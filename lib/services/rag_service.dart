import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class RagService {
  RagService({
    required this.apiKey,
    this.assetsPath = 'assets/data/pregnancy_faq.json',
  });

  final String apiKey;
  final String assetsPath;

  bool _initialized = false;
  List<RagDocument> _faqs = <RagDocument>[];

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final String jsonText = await rootBundle.loadString(assetsPath);
    _faqs = _parseFaq(jsonText);
    _initialized = true;
  }

  Future<String> answer(String query, {String? languageHint}) async {
    if (!_initialized) {
      await initialize();
    }

    if (_faqs.isEmpty) {
      return 'Sorry, I do not have enough information to answer that.';
    }

    // Build context from all FAQs (simple approach, no embeddings needed)
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
          '$_baseUrl/gemini-3-flash-preview:generateContent?key=$apiKey',
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
      print('RAG Error Details: $e');
      return 'Connection error. Please check your internet and try again.';
    }
  }

  /// Streams the answer in real-time chunks for a more responsive UI
  Stream<String> answerStream(String query, {String? languageHint}) async* {
    if (!_initialized) {
      await initialize();
    }

    if (_faqs.isEmpty) {
      yield 'Sorry, I do not have enough information to answer that.';
      return;
    }

    // Build context from all FAQs
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
      final request = http.Request(
        'POST',
        Uri.parse(
          '$_baseUrl/gemini-3-flash-preview:streamGenerateContent?alt=sse&key=$apiKey',
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
        await for (final chunk in streamedResponse.stream.transform(
          utf8.decoder,
        )) {
          // Parse Server-Sent Events (SSE) format
          final lines = chunk.split('\n');
          for (final line in lines) {
            if (line.startsWith('data: ')) {
              final jsonData = line.substring(6); // Remove 'data: ' prefix
              try {
                final data = jsonDecode(jsonData);
                final text =
                    data['candidates']?[0]?['content']?['parts']?[0]?['text'];
                if (text != null && text.isNotEmpty) {
                  yield text;
                }
              } catch (e) {
                // Skip malformed JSON chunks
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
      print('RAG Streaming Error: $e');
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
