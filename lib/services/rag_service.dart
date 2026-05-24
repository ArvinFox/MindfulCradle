import 'dart:convert';
import 'dart:math';

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

  /// For unit tests — loads from a JSON string instead of assets.
  // ignore: invalid_use_of_visible_for_testing_member
  void initializeFromJson(String jsonText) {
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

    // Retrieve top-4 FAQs and build the prompt.
    final retrieved = retrieve(query, topK: 4);
    final String context = _buildContext(retrieved);

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
          'generationConfig': {'temperature': 0.7},
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

  /// Streams the response token by token for the live typing effect.
  Stream<String> answerStream(
    String query, {
    String? languageHint,
    List<Map<String, String>>? conversationHistory,
    String? userName,
    String? crisisExtra,
  }) async* {
    if (!_initialized) {
      await initialize();
    }

    if (_faqs.isEmpty) {
      yield 'Sorry, I do not have enough information to answer that.';
      return;
    }

    // Retrieve top-4 FAQs and build the prompt.
    final retrieved = retrieve(query, topK: 4);
    final String context = _buildContext(retrieved);

    final String prompt = _buildPrompt(
      query: query,
      context: context,
      languageHint: languageHint,
      conversationHistory: conversationHistory,
      userName: userName,
      crisisExtra: crisisExtra,
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
        'generationConfig': {'temperature': 0.7},
      });

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        await for (final chunk in streamedResponse.stream.transform(
          utf8.decoder,
        )) {
          // Parse SSE chunks.
          final lines = chunk.split('\n');
          for (final line in lines) {
            if (line.startsWith('data: ')) {
              final jsonData = line.substring(6); // strip 'data: ' prefix
              try {
                final data = jsonDecode(jsonData);
                final text =
                    data['candidates']?[0]?['content']?['parts']?[0]?['text'];
                if (text != null && text.isNotEmpty) {
                  yield text;
                }
              } catch (e) {
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

  // Retrieval

  /// Lowercases text, removes stop-words, and returns meaningful tokens.
  static const _stopWords = {
    'i',
    'me',
    'my',
    'we',
    'our',
    'you',
    'your',
    'he',
    'she',
    'it',
    'they',
    'them',
    'what',
    'which',
    'who',
    'this',
    'that',
    'these',
    'those',
    'am',
    'is',
    'are',
    'was',
    'were',
    'be',
    'been',
    'being',
    'have',
    'has',
    'had',
    'do',
    'does',
    'did',
    'will',
    'would',
    'could',
    'should',
    'may',
    'might',
    'must',
    'can',
    'a',
    'an',
    'the',
    'and',
    'but',
    'or',
    'for',
    'of',
    'in',
    'on',
    'at',
    'to',
    'by',
    'with',
    'from',
    'up',
    'about',
    'into',
    'through',
    'during',
    'how',
    'when',
    'where',
    'why',
    'so',
    'if',
    'then',
    'than',
    'too',
    'very',
    'just',
    'not',
    'no',
    'nor',
    'as',
    'also',
  };

  static List<String> _tokenise(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'[^a-z]+'))
        .where((t) => t.length > 2 && !_stopWords.contains(t))
        .toList();
  }

  // TF-IDF + Cosine Similarity (Retrieval Phase)

  /// Computes smoothed IDF weights: IDF(t) = log((N+1) / (df(t)+1)) + 1
  Map<String, double> _buildIdf() {
    final int N = _faqs.length;
    final df = <String, int>{};
    for (final doc in _faqs) {
      final docText = '${doc.question} ${doc.answer} ${doc.category}';
      for (final term in _tokenise(docText).toSet()) {
        df[term] = (df[term] ?? 0) + 1;
      }
    }
    return df.map(
      (term, freq) => MapEntry(term, log((N + 1) / (freq + 1)) + 1),
    );
  }

  /// Converts text into a TF-IDF vector using pre-computed IDF weights.
  Map<String, double> _tfidfVector(String text, Map<String, double> idf) {
    final tokens = _tokenise(text);
    if (tokens.isEmpty) return {};

    // Term frequency (normalised by document length).
    final tf = <String, double>{};
    for (final t in tokens) {
      tf[t] = (tf[t] ?? 0) + 1;
    }
    for (final t in tf.keys.toList()) {
      tf[t] = tf[t]! / tokens.length;
    }

    // Multiply TF by IDF; skip terms not in the corpus.
    final vector = <String, double>{};
    for (final entry in tf.entries) {
      final idfWeight = idf[entry.key];
      if (idfWeight != null) {
        vector[entry.key] = entry.value * idfWeight;
      }
    }
    return vector;
  }

  /// Returns cosine similarity between two TF-IDF vectors (range 0–1).
  double _cosineSimilarity(Map<String, double> a, Map<String, double> b) {
    if (a.isEmpty || b.isEmpty) return 0;

    // Dot product.
    double dot = 0;
    for (final entry in a.entries) {
      final bVal = b[entry.key];
      if (bVal != null) dot += entry.value * bVal;
    }
    if (dot == 0) return 0;

    // L2 norms.
    final magA = sqrt(a.values.fold(0.0, (sum, v) => sum + v * v));
    final magB = sqrt(b.values.fold(0.0, (sum, v) => sum + v * v));
    if (magA == 0 || magB == 0) return 0;

    return dot / (magA * magB);
  }

  /// Returns the top [topK] matching FAQs. Falls back to first [topK] if no vocab overlap.
  List<RagDocument> retrieve(String query, {int topK = 4}) {
    if (_faqs.isEmpty) return [];

    final idf = _buildIdf();
    final queryVec = _tfidfVector(query, idf);

    // No overlap (e.g. Sinhala query) — use fallback.
    if (queryVec.isEmpty) return _faqs.take(topK).toList();

    final scored = _faqs.map((doc) {
      final docText = '${doc.question} ${doc.answer} ${doc.category}';
      final docVec = _tfidfVector(docText, idf);
      return (doc: doc, score: _cosineSimilarity(queryVec, docVec));
    }).toList()..sort((a, b) => b.score.compareTo(a.score));

    return scored.take(topK).map((e) => e.doc).toList();
  }

  // Context builder

  String _buildContext(List<RagDocument> docs) {
    return docs
        .map(
          (doc) =>
              'Q: ${doc.question}\nA: ${doc.answer}\nCategory: ${doc.category}',
        )
        .join('\n\n');
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
    String? userName,
    String? crisisExtra,
  }) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln(
      'You are a compassionate and knowledgeable pregnancy support assistant for the Mindful Cradle app. '
      'Your role is to provide helpful, evidence-based information about pregnancy, childbirth, and newborn care. '
      'Answer using the context provided below. If the context doesn\'t contain enough information, '
      'provide a general supportive response and suggest consulting with a healthcare provider. '
      'Be warm, reassuring, and supportive in your responses. '
      'Keep responses concise and to the point — aim for 2 to 4 short paragraphs at most. '
      'Avoid repeating information and skip unnecessary filler phrases. '
      'Use Markdown formatting for emphasis: **bold** for important points, *italics* for emphasis, and bullet points or numbered lists for structured information.',
    );
    if (userName != null && userName.trim().isNotEmpty) {
      final firstName = userName.trim().split(RegExp(r'\s+')).first;
      buffer.writeln(
        'The user\'s name is $firstName. Address them warmly by name when it feels natural.',
      );
    }
    if (crisisExtra != null && crisisExtra.isNotEmpty) {
      buffer.writeln(crisisExtra);
    }
    if (languageHint != null && languageHint.isNotEmpty) {
      buffer.writeln('Please reply in: $languageHint.');
    }
    buffer.writeln('\nKnowledge Base:');
    buffer.writeln(context);

    // Append last 5 messages for context.
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      buffer.writeln('\n--- Previous Conversation ---');
      final recentMessages = conversationHistory.length > 5
          ? conversationHistory.sublist(conversationHistory.length - 5)
          : conversationHistory;

      for (final msg in recentMessages) {
        final role = msg['role'] == 'user' ? 'User' : 'Assistant';
        final text = msg['text'] ?? '';
        // Truncate long messages.
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
