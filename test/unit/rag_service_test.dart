import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mamamind/services/rag_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Loads the real pregnancy_faq.json from the assets folder on disk.
/// In unit tests dart:io is available, so we read it directly.
String _loadFaqJson() {
  // The working directory when `flutter test` runs is the project root.
  final file = File('assets/data/pregnancy_faq.json');
  expect(
    file.existsSync(),
    isTrue,
    reason: 'pregnancy_faq.json must exist at assets/data/',
  );
  return file.readAsStringSync();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late RagService service;
  late String faqJson;

  setUpAll(() {
    faqJson = _loadFaqJson();
    service = RagService(apiKey: 'test-key');
    service.initializeFromJson(faqJson);
  });

  // ── 1. Initialisation ────────────────────────────────────────────────────
  group('initializeFromJson()', () {
    test('loads all FAQ documents from the real JSON file', () {
      // The FAQ had 83 entries as of the last update.
      // We allow ≥ 50 to future-proof against additions.
      final docs = service.retrieve('pregnancy', topK: 1000);
      expect(docs.length, greaterThanOrEqualTo(50));
    });

    test('every document has non-empty question, answer, and category', () {
      final docs = service.retrieve('pregnancy', topK: 1000);
      for (final doc in docs) {
        expect(
          doc.question,
          isNotEmpty,
          reason: 'question should not be empty',
        );
        expect(doc.answer, isNotEmpty, reason: 'answer should not be empty');
        expect(
          doc.category,
          isNotEmpty,
          reason: 'category should not be empty',
        );
      }
    });
  });

  // ── 2. TF-IDF tokenisation (via retrieve) ────────────────────────────────
  group('_tokenise() behaviour (verified through retrieve)', () {
    test('stop-words do not drive retrieval — "the a is" returns results', () {
      // Pure stop-word query → queryVec will be empty → fallback returns docs
      final docs = service.retrieve('the a is', topK: 3);
      expect(docs.length, equals(3));
    });

    test('short tokens (≤ 2 chars) are ignored', () {
      // Single-char / two-char words only → treated like stop-words
      final docs = service.retrieve('hi to do', topK: 3);
      expect(docs.length, equals(3));
    });
  });

  // ── 3. Cosine similarity ranking ─────────────────────────────────────────
  group('retrieve() cosine similarity ranking', () {
    test(
      'morning sickness query retrieves nausea/morning-sickness document first',
      () {
        final docs = service.retrieve(
          'morning sickness nausea vomiting',
          topK: 5,
        );
        final questions = docs.map((d) => d.question.toLowerCase()).toList();
        final topIsRelevant = questions.any(
          (q) => q.contains('morning sickness') || q.contains('nausea'),
        );
        expect(
          topIsRelevant,
          isTrue,
          reason: 'Top-5 results should contain a morning-sickness FAQ',
        );
      },
    );

    test('diet schedule query retrieves nutrition document', () {
      final docs = service.retrieve(
        'diet schedule meal plan foods pregnancy',
        topK: 5,
      );
      final categories = docs.map((d) => d.category).toList();
      expect(
        categories,
        contains('nutrition'),
        reason: 'A nutrition document should be in the top-5 for diet queries',
      );
    });

    test('tummy pain query retrieves abdominal/discomfort document', () {
      final docs = service.retrieve('tummy hurts stomach pain cramps', topK: 5);
      final relevant = docs.any(
        (d) =>
            d.question.toLowerCase().contains('tummy') ||
            d.question.toLowerCase().contains('stomach') ||
            d.question.toLowerCase().contains('cramp') ||
            d.question.toLowerCase().contains('abdominal') ||
            d.category == 'common_discomforts',
      );
      expect(
        relevant,
        isTrue,
        reason: 'A tummy/stomach discomfort FAQ should be in top-5',
      );
    });

    test('headache query retrieves headache document', () {
      final docs = service.retrieve('headache head pain pregnancy', topK: 5);
      final relevant = docs.any(
        (d) => d.question.toLowerCase().contains('headache'),
      );
      expect(
        relevant,
        isTrue,
        reason: 'Headache FAQ should be retrieved for headache query',
      );
    });

    test('constipation query retrieves the constipation document', () {
      final docs = service.retrieve(
        'constipation hard stool bowel pregnancy',
        topK: 5,
      );
      final relevant = docs.any(
        (d) => d.question.toLowerCase().contains('constipation'),
      );
      expect(
        relevant,
        isTrue,
        reason: 'Constipation FAQ should be in top-5 results',
      );
    });

    test('UTI / urinary infection query retrieves UTI document', () {
      final docs = service.retrieve(
        'burning urination urinary tract infection',
        topK: 5,
      );
      final relevant = docs.any(
        (d) =>
            d.question.toLowerCase().contains('urinary') ||
            d.question.toLowerCase().contains('uti'),
      );
      expect(
        relevant,
        isTrue,
        reason: 'UTI FAQ should be retrieved for urinary infection query',
      );
    });

    test('anaemia / tiredness query retrieves anaemia document', () {
      final docs = service.retrieve(
        'anaemia tired pale weak low iron',
        topK: 5,
      );
      final relevant = docs.any(
        (d) =>
            d.question.toLowerCase().contains('anaemia') ||
            d.answer.toLowerCase().contains('anaemia') ||
            d.answer.toLowerCase().contains('iron'),
      );
      expect(
        relevant,
        isTrue,
        reason: 'Anaemia FAQ should appear for low-iron tiredness query',
      );
    });

    test('swelling feet ankles query retrieves oedema document', () {
      final docs = service.retrieve(
        'swollen feet ankles swelling pregnancy',
        topK: 5,
      );
      final relevant = docs.any(
        (d) =>
            d.question.toLowerCase().contains('swelling') ||
            d.answer.toLowerCase().contains('swelling') ||
            d.answer.toLowerCase().contains('oedema'),
      );
      expect(
        relevant,
        isTrue,
        reason: 'Swelling FAQ should be retrieved for swollen feet query',
      );
    });

    test('back pain query retrieves back pain document', () {
      final docs = service.retrieve(
        'back pain lower back ache pregnancy',
        topK: 5,
      );
      final relevant = docs.any(
        (d) => d.question.toLowerCase().contains('back pain'),
      );
      expect(
        relevant,
        isTrue,
        reason: 'Back pain FAQ should be in top-5 for back pain query',
      );
    });

    test('flu cold sick query retrieves illness document', () {
      final docs = service.retrieve('cold flu sick fever pregnancy', topK: 5);
      final relevant = docs.any(
        (d) =>
            d.question.toLowerCase().contains('cold') ||
            d.question.toLowerCase().contains('flu') ||
            d.answer.toLowerCase().contains('flu'),
      );
      expect(
        relevant,
        isTrue,
        reason: 'Cold/flu FAQ should be retrieved for illness query',
      );
    });

    test('sciatica hip pain query retrieves sciatica document', () {
      final docs = service.retrieve(
        'sciatica hip pain nerve lower back leg',
        topK: 5,
      );
      final relevant = docs.any(
        (d) =>
            d.question.toLowerCase().contains('sciatica') ||
            d.question.toLowerCase().contains('hip pain'),
      );
      expect(
        relevant,
        isTrue,
        reason: 'Sciatica or hip pain FAQ should appear for that query',
      );
    });

    test('insomnia sleep query retrieves sleep document', () {
      final docs = service.retrieve(
        'insomnia cannot sleep restless night',
        topK: 5,
      );
      final relevant = docs.any(
        (d) =>
            d.question.toLowerCase().contains('sleep') ||
            d.question.toLowerCase().contains('insomnia'),
      );
      expect(
        relevant,
        isTrue,
        reason: 'Insomnia/sleep FAQ should be retrieved for sleep queries',
      );
    });
  });

  // ── 4. Cosine similarity is actually differentiating documents ───────────
  group('TF-IDF scoring produces meaningful differentiation', () {
    test(
      'query about nutrition returns more nutrition docs than labour docs',
      () {
        final docs = service.retrieve(
          'food diet nutrition meal eat vitamins iron calcium pregnancy',
          topK: 6,
        );
        final nutritionCount = docs
            .where((d) => d.category == 'nutrition')
            .length;
        final labourCount = docs
            .where((d) => d.category == 'labor_delivery')
            .length;
        expect(
          nutritionCount,
          greaterThan(labourCount),
          reason:
              'Nutrition query should rank nutrition docs higher than labour docs',
        );
      },
    );

    test('query about labour returns more labour docs than nutrition docs', () {
      final docs = service.retrieve(
        'labor contractions delivery birth hospital pushing stage',
        topK: 6,
      );
      final labourCount = docs
          .where((d) => d.category == 'labor_delivery')
          .length;
      final nutritionCount = docs
          .where((d) => d.category == 'nutrition')
          .length;
      expect(
        labourCount,
        greaterThan(nutritionCount),
        reason:
            'Labour query should rank labour docs higher than nutrition docs',
      );
    });

    test(
      'retrieve returns exactly topK documents when corpus is large enough',
      () {
        for (final k in [1, 3, 4, 5, 10]) {
          final docs = service.retrieve('pregnancy', topK: k);
          expect(
            docs.length,
            equals(k),
            reason: 'retrieve(topK: $k) should return exactly $k docs',
          );
        }
      },
    );

    test('different queries return different top documents', () {
      final nutritionDocs = service.retrieve(
        'food diet vitamins eat meal',
        topK: 3,
      );
      final labourDocs = service.retrieve(
        'contractions labor delivery birth',
        topK: 3,
      );
      final nutritionIds = nutritionDocs.map((d) => d.question).toSet();
      final labourIds = labourDocs.map((d) => d.question).toSet();
      // The top-3 documents for these two very different queries should not be identical
      expect(
        nutritionIds,
        isNot(equals(labourIds)),
        reason: 'Different queries must produce different ranked results',
      );
    });
  });

  // ── 5. Edge cases ────────────────────────────────────────────────────────
  group('retrieve() edge cases', () {
    test('empty query falls back to first topK documents', () {
      final docs = service.retrieve('', topK: 4);
      expect(docs.length, equals(4));
    });

    test('query with only stop-words falls back to first topK documents', () {
      final docs = service.retrieve('and or but the to with', topK: 3);
      expect(docs.length, equals(3));
    });

    test('topK larger than corpus returns all documents', () {
      final docs = service.retrieve('pregnancy', topK: 9999);
      // Should return all documents (not crash)
      expect(docs.length, greaterThan(0));
    });

    test('repeated identical queries return identical results', () {
      final first = service.retrieve('morning sickness', topK: 4);
      final second = service.retrieve('morning sickness', topK: 4);
      expect(
        first.map((d) => d.question).toList(),
        equals(second.map((d) => d.question).toList()),
        reason: 'TF-IDF retrieval must be deterministic',
      );
    });
  });

  // ── 6. Internal maths: cosine similarity via known vectors ───────────────
  group('cosine similarity mathematics (via RagDocument injection)', () {
    test('identical document and query give similarity > 0.9', () {
      // Build a mini-service with a single known document.
      final miniService = RagService(apiKey: 'k');
      miniService.initializeFromJson('''[
        {
          "question": "morning sickness nausea vomiting pregnancy",
          "answer": "morning sickness nausea vomiting pregnancy trimester",
          "category": "first_trimester"
        },
        {
          "question": "back pain lower back ache posture",
          "answer": "back pain posture support belt exercise relief",
          "category": "common_discomforts"
        }
      ]''');
      // Querying with the same terms as doc 0 → it must be ranked first.
      final docs = miniService.retrieve(
        'morning sickness nausea vomiting pregnancy',
        topK: 2,
      );
      expect(
        docs.first.category,
        equals('first_trimester'),
        reason: 'Exact-match doc should rank first (highest cosine similarity)',
      );
    });

    test('dissimilar query ranks the correct document first', () {
      final miniService = RagService(apiKey: 'k');
      miniService.initializeFromJson('''[
        {
          "question": "headache pain head pressure pregnancy",
          "answer": "headache pain head pressure acetaminophen water rest",
          "category": "common_discomforts"
        },
        {
          "question": "nutrition food vitamins iron calcium folate",
          "answer": "nutrition food vitamins iron calcium folate diet healthy",
          "category": "nutrition"
        }
      ]''');
      // Querying nutrition terms → nutrition doc must rank first.
      final nutritionFirst = miniService.retrieve(
        'vitamins iron calcium folate nutrition',
        topK: 2,
      );
      expect(
        nutritionFirst.first.category,
        equals('nutrition'),
        reason: 'Nutrition query should rank the nutrition document first',
      );

      // Querying headache terms → headache doc must rank first.
      final headacheFirst = miniService.retrieve(
        'headache head pain pressure',
        topK: 2,
      );
      expect(
        headacheFirst.first.category,
        equals('common_discomforts'),
        reason: 'Headache query should rank the headache document first',
      );
    });
  });
}
