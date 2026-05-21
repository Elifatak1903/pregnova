import 'package:flutter_test/flutter_test.dart';
import 'package:pregnova/shared/daily_nutrition_summary.dart';

void main() {
  group('DailyNutritionSummaryService', () {
    test('sums calories and nutrients across multiple analyses in a day', () {
      final summary = DailyNutritionSummaryService.summarize([
        {
          'kalori': 250,
          'totalNutrients': {'Protein': 20, 'Demir': 4},
        },
        {
          'kalori': 150,
          'totalNutrients': {'Protein': 10, 'Kalsiyum': 120},
        },
      ]);

      expect(summary.calories, 400);
      expect(summary.nutrients['Protein'], 30);
      expect(summary.nutrients['Demir'], 4);
      expect(summary.nutrients['Kalsiyum'], 120);
    });

    test('supports calories/nutrients aliases for future shared payloads', () {
      final summary = DailyNutritionSummaryService.summarize([
        {
          'calories': '100.5',
          'nutrients': {'Protein': '5.5'},
        },
      ]);

      expect(summary.calories, 100.5);
      expect(summary.nutrients['Protein'], 5.5);
    });

    test('includes supplement-derived nutrients when they are stored in totals', () {
      final summary = DailyNutritionSummaryService.summarize([
        {
          'kalori': 84,
          'totalNutrients': {'Kalsiyum': 240},
        },
        {
          'kalori': 0,
          'totalNutrients': {'Demir': 27, 'Folik Asit': 400},
        },
      ]);

      expect(summary.calories, 84);
      expect(summary.nutrients['Kalsiyum'], 240);
      expect(summary.nutrients['Demir'], 27);
      expect(summary.nutrients['Folik Asit'], 400);
    });

    test('trims nutrient names and sums numeric strings', () {
      final summary = DailyNutritionSummaryService.summarize([
        {
          'kalori': '120',
          'totalNutrients': {' Protein ': '8.5', 'Demir': 2},
        },
        {
          'kalori': 80,
          'totalNutrients': {'Protein': 1.5, 'Demir': '3'},
        },
      ]);

      expect(summary.calories, 200);
      expect(summary.nutrients['Protein'], 10);
      expect(summary.nutrients['Demir'], 5);
    });

    test('ignores null analyses, null nutrients, and negative values', () {
      final summary = DailyNutritionSummaryService.summarize([
        null,
        {'kalori': null, 'totalNutrients': null},
        {
          'kalori': -200,
          'totalNutrients': {'Protein': -5, '': 10, null: 3},
        },
      ]);

      expect(summary.calories, 0);
      expect(summary.nutrients, isEmpty);
    });

    test('ignores unsupported nutrient payload types', () {
      final summary = DailyNutritionSummaryService.summarize([
        {'kalori': 50, 'totalNutrients': ['Protein', 10]},
        {'calories': 'not-a-number', 'nutrients': 'Protein: 10'},
      ]);

      expect(summary.calories, 50);
      expect(summary.nutrients, isEmpty);
    });

    test('returns zero totals for an empty day', () {
      final summary = DailyNutritionSummaryService.summarize([]);

      expect(summary.calories, 0);
      expect(summary.nutrients, isEmpty);
    });

    test('returns an immutable nutrient map', () {
      final summary = DailyNutritionSummaryService.summarize([
        {
          'kalori': 100,
          'totalNutrients': {'Protein': 5},
        },
      ]);

      expect(
        () => summary.nutrients['Protein'] = 10,
        throwsUnsupportedError,
      );
    });
  });
}
