import 'package:flutter_test/flutter_test.dart';
import 'package:pregnova/shared/pregnancy_week_calculator.dart';

void main() {
  group('PregnancyWeekCalculator', () {
    test('calculates pregnancy week from start date', () {
      final week = PregnancyWeekCalculator.calculate(
        pregnancyStartDate: DateTime(2026, 1, 1),
        now: DateTime(2026, 2, 12),
      );

      expect(week, 6);
    });

    test('uses integer week boundaries for exact day differences', () {
      expect(
        PregnancyWeekCalculator.calculate(
          pregnancyStartDate: DateTime(2026, 1, 1),
          now: DateTime(2026, 1, 7),
        ),
        1,
      );
      expect(
        PregnancyWeekCalculator.calculate(
          pregnancyStartDate: DateTime(2026, 1, 1),
          now: DateTime(2026, 1, 8),
        ),
        1,
      );
      expect(
        PregnancyWeekCalculator.calculate(
          pregnancyStartDate: DateTime(2026, 1, 1),
          now: DateTime(2026, 1, 15),
        ),
        2,
      );
    });

    test('uses elapsed full days so time-of-day changes do not overcount weeks', () {
      expect(
        PregnancyWeekCalculator.calculate(
          pregnancyStartDate: DateTime(2026, 1, 1, 23),
          now: DateTime(2026, 1, 8, 1),
        ),
        1,
      );
      expect(
        PregnancyWeekCalculator.calculate(
          pregnancyStartDate: DateTime(2026, 1, 1, 1),
          now: DateTime(2026, 1, 8, 23),
        ),
        1,
      );
    });

    test('clamps week to minimum 1 when start date is today or future', () {
      expect(
        PregnancyWeekCalculator.calculate(
          pregnancyStartDate: DateTime(2026, 5, 9),
          now: DateTime(2026, 5, 9),
        ),
        1,
      );
      expect(
        PregnancyWeekCalculator.calculate(
          pregnancyStartDate: DateTime(2026, 6, 1),
          now: DateTime(2026, 5, 9),
        ),
        1,
      );
    });

    test('clamps week to maximum 42 for old start dates', () {
      final week = PregnancyWeekCalculator.calculate(
        pregnancyStartDate: DateTime(2025, 1, 1),
        now: DateTime(2026, 5, 9),
      );

      expect(week, 42);
    });

    test('uses normalized fallback week when start date is null', () {
      expect(
        PregnancyWeekCalculator.calculate(
          pregnancyStartDate: null,
          fallbackWeek: 12,
        ),
        12,
      );
      expect(
        PregnancyWeekCalculator.calculate(
          pregnancyStartDate: null,
          fallbackWeek: 0,
        ),
        1,
      );
      expect(
        PregnancyWeekCalculator.calculate(
          pregnancyStartDate: null,
          fallbackWeek: 99,
        ),
        42,
      );
    });

    test('defaults to week 1 when both start date and fallback are missing', () {
      expect(
        PregnancyWeekCalculator.calculate(pregnancyStartDate: null),
        1,
      );
    });
  });
}
