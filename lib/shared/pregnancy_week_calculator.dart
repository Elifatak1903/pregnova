class PregnancyWeekCalculator {
  const PregnancyWeekCalculator._();

  static int calculate({
    required DateTime? pregnancyStartDate,
    DateTime? now,
    int? fallbackWeek,
  }) {
    if (pregnancyStartDate == null) {
      return _normalizeWeek(fallbackWeek);
    }

    final currentDate = now ?? DateTime.now();
    final days = currentDate.difference(pregnancyStartDate).inDays;
    final week = days ~/ 7;

    return week.clamp(1, 42);
  }

  static int _normalizeWeek(int? week) {
    if (week == null || week <= 0) return 1;
    return week.clamp(1, 42);
  }
}
