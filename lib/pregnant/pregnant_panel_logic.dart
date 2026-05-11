import '../shared/pregnancy_week_calculator.dart';

class PregnantPanelLogic {
  const PregnantPanelLogic._();

  static bool shouldShowProfilePopup(Map<String, dynamic>? userData) {
    if (userData == null) return false;
    if (userData['profilTamamlandi'] == true) return false;
    if (userData['infoLater'] == true) return false;
    return true;
  }

  static bool isValidPregnancyWeekInput(String? input) {
    final week = int.tryParse(input?.trim() ?? '');
    return week != null && week >= 1 && week <= 42;
  }

  static DateTime? pregnancyStartDateFromWeek(String? input, {DateTime? now}) {
    final week = int.tryParse(input?.trim() ?? '');
    if (week == null || week < 1 || week > 42) return null;

    final currentDate = now ?? DateTime.now();
    return currentDate.subtract(Duration(days: week * 7));
  }

  static int calculateCurrentWeekFromUserData(
    Map<String, dynamic> userData, {
    DateTime? now,
  }) {
    final start = userData['gebelikBaslangicTarihi'];
    final startDate = _dateFromFirestoreLikeValue(start);

    return PregnancyWeekCalculator.calculate(
      pregnancyStartDate: startDate,
      now: now,
      fallbackWeek: _intFromDynamic(userData['hafta']),
    );
  }

  static bool canSaveNutritionAnalysis(Map<String, dynamic>? userData) {
    if (userData == null) return false;

    final dietitianId = userData['assignedDietitian'];
    if (dietitianId is! String) return false;

    return dietitianId.trim().isNotEmpty;
  }

  static int? _intFromDynamic(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static DateTime? _dateFromFirestoreLikeValue(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    try {
      final dynamic firestoreLikeValue = value;
      final date = firestoreLikeValue.toDate();
      if (date is DateTime) return date;
    } catch (_) {
      return null;
    }

    return null;
  }
}
