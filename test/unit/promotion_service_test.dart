import 'package:flutter_test/flutter_test.dart';
import 'package:mamamind/services/promotion_service.dart';

void main() {
  group('PromotionService', () {
    const allTypes = [
      PromotionService.typeJournal,
      PromotionService.typeMood,
      PromotionService.typeMeditation,
      PromotionService.typeEvaluation,
    ];

    group('pickPromotion()', () {
      test('never returns mood when hasMoodToday=true', () async {
        // Run many times to ensure mood is never picked.
        for (int i = 0; i < 50; i++) {
          final result = await PromotionService.pickPromotion(
            hasMoodToday: true,
            hasJournalEntry: false,
            hasMeditationProgress: false,
          );
          expect(result, isNot(PromotionService.typeMood));
        }
      });

      test('can return mood when hasMoodToday=false', () async {
        bool moodSeen = false;
        for (int i = 0; i < 100; i++) {
          final result = await PromotionService.pickPromotion(
            hasMoodToday: false,
            hasJournalEntry: false,
            hasMeditationProgress: false,
          );
          if (result == PromotionService.typeMood) {
            moodSeen = true;
            break;
          }
        }
        expect(moodSeen, isTrue);
      });

      test('result is always one of the valid type constants', () async {
        for (int i = 0; i < 30; i++) {
          final result = await PromotionService.pickPromotion(
            hasMoodToday: false,
            hasJournalEntry: false,
            hasMeditationProgress: false,
          );
          expect(allTypes, contains(result));
        }
      });

      test('returns non-null result', () async {
        final result = await PromotionService.pickPromotion(
          hasMoodToday: true,
          hasJournalEntry: false,
          hasMeditationProgress: false,
        );
        expect(result, isNotNull);
      });

      test(
        'avoids repeating lastShownType back-to-back when other options exist',
        () async {
          // Run 50 iterations: with 4 options, at least some should differ from lastShownType.
          int repeatCount = 0;
          const last = PromotionService.typeJournal;
          for (int i = 0; i < 50; i++) {
            final result = await PromotionService.pickPromotion(
              hasMoodToday: false,
              hasJournalEntry: false,
              hasMeditationProgress: false,
              lastShownType: last,
            );
            if (result == last) repeatCount++;
          }
          // Not all 50 should be the same type.
          expect(repeatCount, lessThan(50));
        },
      );

      test('type constants have correct string values', () {
        expect(PromotionService.typeJournal, 'journal');
        expect(PromotionService.typeMood, 'mood');
        expect(PromotionService.typeMeditation, 'meditation');
        expect(PromotionService.typeEvaluation, 'evaluation');
      });
    });

    group('markShown()', () {
      test('completes without error for any type', () async {
        for (final type in allTypes) {
          await expectLater(PromotionService.markShown(type), completes);
        }
      });
    });
  });
}
