import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Routes all AI chat calls through the Node.js backend.
/// The Gemini API key lives only on the server — never in the app bundle.
class RagService {
  RagService({required this.backendUrl});

  final String backendUrl;

  bool _initialized = false;

  Future<String?> _getIdToken() async {
    return FirebaseAuth.instance.currentUser?.getIdToken();
  }

  Future<void> initialize() async {
    _initialized = true; // FAQ is loaded server-side; nothing to do locally.
  }

  Future<String> answer(
    String query, {
    String? languageHint,
    String? sessionId,
  }) async {
    if (!_initialized) await initialize();

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

  /// Streams the answer in real-time chunks via SSE from the backend.
  Stream<String> answerStream(
    String query, {
    String? languageHint,
    List<Map<String, String>>? conversationHistory,
    String? sessionId,
  }) async* {
    if (!_initialized) await initialize();

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
  }
}
