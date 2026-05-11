import 'package:flutter_test/flutter_test.dart';
import 'package:pregnova/pregnant/pregnant_panel_logic.dart';

void main() {
  group('PregnantPanelLogic profile popup', () {
    test('does not show popup when user data is missing', () {
      expect(PregnantPanelLogic.shouldShowProfilePopup(null), isFalse);
    });

    test('does not show popup when profile is completed', () {
      expect(
        PregnantPanelLogic.shouldShowProfilePopup({
          'profilTamamlandi': true,
        }),
        isFalse,
      );
    });

    test('does not show popup when user postponed profile info', () {
      expect(
        PregnantPanelLogic.shouldShowProfilePopup({
          'profilTamamlandi': false,
          'infoLater': true,
        }),
        isFalse,
      );
    });

    test('shows popup when profile is incomplete and not postponed', () {
      expect(
        PregnantPanelLogic.shouldShowProfilePopup({
          'profilTamamlandi': false,
          'infoLater': false,
        }),
        isTrue,
      );
    });
  });

  group('PregnantPanelLogic pregnancy week input', () {
    test('accepts only weeks between 1 and 42', () {
      expect(PregnantPanelLogic.isValidPregnancyWeekInput('1'), isTrue);
      expect(PregnantPanelLogic.isValidPregnancyWeekInput('42'), isTrue);
      expect(PregnantPanelLogic.isValidPregnancyWeekInput(' 12 '), isTrue);

      expect(PregnantPanelLogic.isValidPregnancyWeekInput(null), isFalse);
      expect(PregnantPanelLogic.isValidPregnancyWeekInput(''), isFalse);
      expect(PregnantPanelLogic.isValidPregnancyWeekInput('0'), isFalse);
      expect(PregnantPanelLogic.isValidPregnancyWeekInput('43'), isFalse);
      expect(PregnantPanelLogic.isValidPregnancyWeekInput('hafta'), isFalse);
    });

    test('calculates pregnancy start date from week input', () {
      final startDate = PregnantPanelLogic.pregnancyStartDateFromWeek(
        '6',
        now: DateTime(2026, 5, 11),
      );

      expect(startDate, DateTime(2026, 3, 30));
    });

    test('returns null start date for invalid week input', () {
      expect(PregnantPanelLogic.pregnancyStartDateFromWeek('0'), isNull);
      expect(PregnantPanelLogic.pregnancyStartDateFromWeek('43'), isNull);
      expect(PregnantPanelLogic.pregnancyStartDateFromWeek('abc'), isNull);
    });
  });

  group('PregnantPanelLogic current week calculation', () {
    test('calculates current week from stored start date', () {
      final week = PregnantPanelLogic.calculateCurrentWeekFromUserData(
        {'gebelikBaslangicTarihi': DateTime(2026, 1, 1)},
        now: DateTime(2026, 2, 12),
      );

      expect(week, 6);
    });

    test('falls back to stored week when start date is missing', () {
      expect(
        PregnantPanelLogic.calculateCurrentWeekFromUserData({'hafta': '27'}),
        27,
      );
      expect(
        PregnantPanelLogic.calculateCurrentWeekFromUserData({'hafta': 0}),
        1,
      );
      expect(
        PregnantPanelLogic.calculateCurrentWeekFromUserData({'hafta': 99}),
        42,
      );
    });
  });

  group('PregnantPanelLogic nutrition analysis availability', () {
    test('requires a non-empty assigned dietitian id', () {
      expect(PregnantPanelLogic.canSaveNutritionAnalysis(null), isFalse);
      expect(PregnantPanelLogic.canSaveNutritionAnalysis({}), isFalse);
      expect(
        PregnantPanelLogic.canSaveNutritionAnalysis({
          'assignedDietitian': null,
        }),
        isFalse,
      );
      expect(
        PregnantPanelLogic.canSaveNutritionAnalysis({
          'assignedDietitian': '   ',
        }),
        isFalse,
      );
      expect(
        PregnantPanelLogic.canSaveNutritionAnalysis({
          'assignedDietitian': 'dietitian-1',
        }),
        isTrue,
      );
    });
  });
}
