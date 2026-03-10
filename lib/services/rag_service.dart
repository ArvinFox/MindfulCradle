import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class RagService {
  RagService({
    this.apiKey = '',
    this.backendUrl = '',
    this.assetsPath = 'assets/data/pregnancy_faq.json',
  });

  /// Direct Gemini API key — used only when [backendUrl] is empty.
  final String apiKey;

  /// Base URL of the Node.js backend (e.g. "https://api.yourdomain.com").
  /// When non-empty the service proxies all AI calls through the backend
  /// so the Gemini API key is never bundled in the app.
  final String backendUrl;

  final String assetsPath;

  bool get _useBackend => backendUrl.isNotEmpty;

  bool _initialized = false;
  List<RagDocument> _faqs = <RagDocument>[];

  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Returns the current user's Firebase ID token for authenticating
  /// backend requests.
  Future<String?> _getIdToken() async {
    return FirebaseAuth.instance.currentUser?.getIdToken();
  }

  Future<void> initialize() async {
    if (_initialized) return;

    // In backend mode the FAQ is loaded server-side; skip local loading.
    if (!_useBackend) {
      final String jsonText = await rootBundle.loadString(assetsPath);
      _faqs = _parseFaq(jsonText);
    }

    _initialized = true;
  }

  Future<String> answer(
    String query, {
    String? languageHint,
    String? sessionId,
  }) async {
    if (!_initialized) await initialize();

    // ── Backend proxy mode ──────────────────────────────────────────────────
    if (_useBackend) {
      final String? idToken = await _getIdToken();
      if (idToken == null) return 'Authentication error. Please log in again.';

      try {
        final response = await http.post(
          Uri.parse('$backendUrl/api/chat'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'message': query,
            if (languageHint != null) 'language': languageHint,
            if (sessionId != null) 'sessionId': sessionId,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['answer'] ?? 'Sorry, I could not generate a response.';
        } else {
          final error = jsonDecode(response.body);
          return 'Error: ${error['error'] ?? response.statusCode}';
        }
      } catch (e) {
        return 'Connection error. Please check your internet and try again.';
      }
    }

    // ── Direct Gemini mode (no backend) ────────────────────────────────────
    if (_faqs.isEmpty) {
      return 'Sorry, I do not have enough information to answer that.';
    }

    final String context = _faqs
        .map(
          (doc) =>
              'Q: ${doc.question}\nA: ${doc.answer}\nCategory: ${doc.category}',
        )
        .join('\n\n');

    final String prompt = _buildPrompt(
      query: query,
      context: context,
      languageHint: languageHint,
    );

    try {
      final response = await http.post(
        Uri.parse(
          '$_geminiBaseUrl/gemini-3-flash-preview:generateContent?key=$apiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        return text ?? 'Sorry, I could not generate a response.';
      } else {
        final error = jsonDecode(response.body);
        final errorMessage = error['error']?['message'] ?? 'Unknown error';
        return 'API Error: $errorMessage';
      }
    } catch (e) {
      return 'Connection error. Please check your internet and try again.';
    }
  }

  /// Streams the answer in real-time chunks for a more responsive UI
  /// with conversation context.
  Stream<String> answerStream(
    String query, {
    String? languageHint,
    List<Map<String, String>>? conversationHistory,
    String? sessionId,
  }) async* {
    if (!_initialized) await initialize();

    // ── Backend proxy mode ──────────────────────────────────────────────────
    if (_useBackend) {
      final String? idToken = await _getIdToken();
      if (idToken == null) {
        yield 'Authentication error. Please log in again.';
        return;
      }

      try {
        final uri = Uri.parse('$backendUrl/api/chat/stream').replace(
          queryParameters: {
            'message': query,
            if (languageHint != null) 'language': languageHint,
            if (sessionId != null) 'sessionId': sessionId,
          },
        );

        final request = http.Request('GET', uri);
        request.headers['Authorization'] = 'Bearer $idToken';

        final streamedResponse = await request.send();

        if (streamedResponse.statusCode == 200) {
          await for (final chunk
              in streamedResponse.stream.transform(utf8.decoder)) {
            final lines = chunk.split('\n');
            for (final line in lines) {
              if (line.startsWith('data: ')) {
                final jsonData = line.substring(6);
                try {
                  final data = jsonDecode(jsonData);
                  // Backend forwards Gemini SSE unchanged
                  final text = data['candidates']?[0]?['content']?['parts']
                      ?[0]?['text'];
                  if (text != null && (text as String).isNotEmpty) {
                    yield text;
                  }
                } catch (_) {
                  continue;
                }
              }
            }
          }
        } else {
          yield 'Error: ${streamedResponse.statusCode}';
        }
      } catch (e) {
        yield 'Connection error. Please check your internet and try again.';
      }
      return;
    }

    // ── Direct Gemini mode (no backend) ────────────────────────────────────
    if (_faqs.isEmpty) {
      yield 'Sorry, I do not have enough information to answer that.';
      return;
    }

    final String context = _faqs
        .map(
          (doc) =>
              'Q: ${doc.question}\nA: ${doc.answer}\nCategory: ${doc.category}',
        )
        .join('\n\n');

    final String prompt = _buildPrompt(
      query: query,
      context: context,
      languageHint: languageHint,
      conversationHistory: conversationHistory,
    );

    try {
      final request = http.Request(
        'POST',
        Uri.parse(
          '$_geminiBaseUrl/gemini-3-flash-preview:streamGenerateContent?alt=sse&key=$apiKey',
        ),
      );
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
      });

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        await for (final chunk
            in streamedResponse.stream.transform(utf8.decoder)) {
          final lines = chunk.split('\n');
          for (final line in lines) {
            if (line.startsWith('data: ')) {
              final jsonData = line.substring(6);
              try {
                final data = jsonDecode(jsonData);
                final text =
                    data['candidates']?[0]?['content']?['parts']?[0]?['text'];
                if (text != null && (text as String).isNotEmpty) {
                  yield text;
                }
              } catch (_) {
                continue;
              }
            }
          }
        }
      } else {
        final errorBody = await streamedResponse.stream.bytesToString();
        try {
          final error = jsonDecode(errorBody);
          final errorMessage = error['error']?['message'] ?? 'Unknown error';
          yield 'API Error: $errorMessage';
        } catch (_) {
          yield 'API Error: ${streamedResponse.statusCode}';
        }
      }
    } catch (e) {
      yield 'Connection error. Please check your internet and try again.';
    }
  }

  List<RagDocument> _parseFaq(String jsonText) {
    final List<dynamic> data = jsonDecode(jsonText) as List<dynamic>;
    return data
        .map(
          (dynamic item) => RagDocument.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  String _buildPrompt({
    required String query,
    required String context,
    String? languageHint,
    List<Map<String, String>>? conversationHistory,
  }) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln(
      'You are a compassionate and knowledgeable pregnancy support assistant for the Mindful Cradle app. '
      'Your role is to provide helpful, evidence-based information about pregnancy, childbirth, and newborn care. '
      'Answer using the context provided below. If the context doesn\'t contain enough information, '
      'provide a general supportive response and suggest consulting with a healthcare provider. '
      'Be warm, reassuring, and supportive in your responses.',
    );
    if (languageHint != null && languageHint.isNotEmpty) {
      buffer.writeln('Please reply in: $languageHint.');
    }
    buffer.writeln('\nKnowledge Base:');
    buffer.writeln(context);

    // Add conversation history for context
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      buffer.writeln('\n--- Previous Conversation ---');
      // Include last 5 messages for context (optimized to save tokens)
      final recentMessages = conversationHistory.length > 5
          ? conversationHistory.sublist(conversationHistory.length - 5)
          : conversationHistory;

      for (final msg in recentMessages) {
        final role = msg['role'] == 'user' ? 'User' : 'Assistant';
        final text = msg['text'] ?? '';
        // Truncate very long messages to save tokens
        final truncated = text.length > 200
            ? '${text.substring(0, 200)}...'
            : text;
        buffer.writeln('$role: $truncated');
      }
      buffer.writeln('--- End of Previous Conversation ---\n');
    }

    buffer.writeln('\nUser Question: $query');
    buffer.writeln('\nYour Response:');
    return buffer.toString();
  }
}

class RagDocument {
  const RagDocument({
    required this.question,
    required this.answer,
    required this.category,
  });

  final String question;
  final String answer;
  final String category;

  factory RagDocument.fromJson(Map<String, dynamic> json) {
    return RagDocument(
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      category: json['category'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'question': question,
      'answer': answer,
      'category': category,
    };
  }
}
