class DailyNutritionSummary {
  final double calories;
  final Map<String, double> nutrients;

  const DailyNutritionSummary({
    required this.calories,
    required this.nutrients,
  });
}

class DailyNutritionSummaryService {
  const DailyNutritionSummaryService._();

  static DailyNutritionSummary summarize(
    Iterable<Map<String, dynamic>?> analyses,
  ) {
    var calories = 0.0;
    final nutrients = <String, double>{};

    for (final analysis in analyses) {
      if (analysis == null) continue;

      calories += _positiveNumber(analysis['kalori'] ?? analysis['calories']);

      final rawNutrients =
          analysis['totalNutrients'] ?? analysis['nutrients'] ?? {};

      if (rawNutrients is Map) {
        rawNutrients.forEach((key, value) {
          final nutrientName = key?.toString().trim();
          if (nutrientName == null || nutrientName.isEmpty) return;

          final amount = _positiveNumber(value);
          if (amount == 0) return;

          nutrients[nutrientName] = (nutrients[nutrientName] ?? 0) + amount;
        });
      }
    }

    return DailyNutritionSummary(
      calories: calories,
      nutrients: Map.unmodifiable(nutrients),
    );
  }

  static double _positiveNumber(dynamic value) {
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');

    if (parsed == null || parsed <= 0) return 0;
    return parsed;
  }
}
