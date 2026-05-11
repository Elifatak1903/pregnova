class DietitianPanelLogic {
  const DietitianPanelLogic._();

  static int countRequestsForStatus(
    Iterable<Map<String, dynamic>?> requests, {
    required String dietitianId,
    required String status,
  }) {
    return requests.where((request) {
      if (request == null) return false;
      return request['expertId'] == dietitianId && request['status'] == status;
    }).length;
  }

  static Set<String> approvedClientIdsForDietitian(
    Iterable<Map<String, dynamic>?> requests, {
    required String dietitianId,
  }) {
    final clientIds = <String>{};

    for (final request in requests) {
      if (request == null) continue;
      if (request['expertId'] != dietitianId) continue;
      if (request['status'] != 'approved') continue;

      final clientId = _stringValue(request['clientId'] ?? request['userId']);
      if (clientId != null) clientIds.add(clientId);
    }

    return clientIds;
  }

  static int activeAnalysisCountLast7Days({
    required Iterable<Map<String, dynamic>?> analyses,
    required String dietitianId,
    required DateTime now,
  }) {
    final start = now.subtract(const Duration(days: 7));

    return analyses.where((analysis) {
      if (analysis == null) return false;
      if (analysis['dietitianId'] != dietitianId) return false;

      final date = _dateFromFirestoreLikeValue(
        analysis['createdAt'] ?? analysis['tarih'],
      );
      if (date == null) return false;

      return !date.isBefore(start) && !date.isAfter(now);
    }).length;
  }

  static List<Map<String, dynamic>> recentAnalysesForDietitian({
    required Iterable<Map<String, dynamic>?> analyses,
    required String dietitianId,
    int limit = 5,
  }) {
    final filtered = analyses.whereType<Map<String, dynamic>>().where((
      analysis,
    ) {
      return analysis['dietitianId'] == dietitianId;
    }).toList();

    filtered.sort((a, b) {
      final aDate = _dateFromFirestoreLikeValue(a['createdAt'] ?? a['tarih']);
      final bDate = _dateFromFirestoreLikeValue(b['createdAt'] ?? b['tarih']);
      return (bDate ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
        aDate ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
    });

    return List.unmodifiable(filtered.take(limit));
  }

  static List<DietitianDailyAnalysisGroup> groupAnalysesByDay(
    Iterable<Map<String, dynamic>?> analyses,
  ) {
    final groups = <DateTime, List<Map<String, dynamic>>>{};

    for (final analysis in analyses) {
      if (analysis == null) continue;

      final date = _dateFromFirestoreLikeValue(
        analysis['createdAt'] ?? analysis['tarih'],
      );
      if (date == null) continue;

      final day = DateTime(date.year, date.month, date.day);
      groups.putIfAbsent(day, () => []).add(analysis);
    }

    final result = groups.entries.map((entry) {
      entry.value.sort((a, b) {
        final aDate = _dateFromFirestoreLikeValue(a['createdAt'] ?? a['tarih']);
        final bDate = _dateFromFirestoreLikeValue(b['createdAt'] ?? b['tarih']);
        return (aDate ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
          bDate ?? DateTime.fromMillisecondsSinceEpoch(0),
        );
      });

      final totalCalories = entry.value.fold<double>(
        0,
        (sum, analysis) => sum + _positiveNumber(analysis['kalori']),
      );

      return DietitianDailyAnalysisGroup(
        day: entry.key,
        analyses: List.unmodifiable(entry.value),
        totalCalories: totalCalories,
      );
    }).toList();

    result.sort((a, b) => b.day.compareTo(a.day));
    return List.unmodifiable(result);
  }

  static Map<String, dynamic> buildDietPlanPayload({
    required String clientId,
    required String dietitianId,
    required String breakfast,
    required String snack1,
    required String lunch,
    required String snack2,
    required String dinner,
    required String night,
    required String notes,
  }) {
    return {
      'clientId': clientId.trim(),
      'dietitianId': dietitianId.trim(),
      'kahvalti': breakfast.trim(),
      'ara1': snack1.trim(),
      'ogle': lunch.trim(),
      'ara2': snack2.trim(),
      'aksam': dinner.trim(),
      'gece': night.trim(),
      'notlar': notes.trim(),
    };
  }

  static String? _stringValue(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static double _positiveNumber(dynamic value) {
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');

    if (parsed == null || parsed <= 0) return 0;
    return parsed;
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

    return DateTime.tryParse(value.toString());
  }
}

class DietitianDailyAnalysisGroup {
  final DateTime day;
  final List<Map<String, dynamic>> analyses;
  final double totalCalories;

  const DietitianDailyAnalysisGroup({
    required this.day,
    required this.analyses,
    required this.totalCalories,
  });
}
