class GynecologistPanelLogic {
  const GynecologistPanelLogic._();

  static int countRequestsForStatus(
    Iterable<Map<String, dynamic>?> requests, {
    required String doctorId,
    required String status,
  }) {
    return requests.where((request) {
      if (request == null) return false;
      return request['expertId'] == doctorId && request['status'] == status;
    }).length;
  }

  static Set<String> approvedPatientIdsForDoctor(
    Iterable<Map<String, dynamic>?> requests, {
    required String doctorId,
  }) {
    final patientIds = <String>{};

    for (final request in requests) {
      if (request == null) continue;
      if (request['expertId'] != doctorId) continue;
      if (request['status'] != 'approved') continue;

      final patientId = _stringValue(request['clientId'] ?? request['userId']);
      if (patientId != null) patientIds.add(patientId);
    }

    return patientIds;
  }

  static int highRiskPatientCount({
    required Iterable<Map<String, dynamic>?> measurements,
    required Set<String> approvedPatientIds,
  }) {
    final highRiskPatients = <String>{};

    for (final measurement in measurements) {
      if (measurement == null) continue;

      final patientId = _stringValue(measurement['uid']);
      if (patientId == null || !approvedPatientIds.contains(patientId)) {
        continue;
      }

      if (_hasAnyHighRisk(measurement)) {
        highRiskPatients.add(patientId);
      }
    }

    return highRiskPatients.length;
  }

  static int activePatientCountLast7Days({
    required Iterable<Map<String, dynamic>?> measurements,
    required Set<String> approvedPatientIds,
    required DateTime now,
  }) {
    final start = now.subtract(const Duration(days: 7));
    final activePatients = <String>{};

    for (final measurement in measurements) {
      if (measurement == null) continue;

      final patientId = _stringValue(measurement['uid']);
      if (patientId == null || !approvedPatientIds.contains(patientId)) {
        continue;
      }

      final date = _dateFromFirestoreLikeValue(measurement['tarih']);
      if (date == null) continue;

      if (!date.isBefore(start) && !date.isAfter(now)) {
        activePatients.add(patientId);
      }
    }

    return activePatients.length;
  }

  static Map<String, int> riskDistributionForDoctor(
    Iterable<Map<String, dynamic>?> users, {
    required String doctorId,
  }) {
    final result = {'normal': 0, 'medium': 0, 'high': 0};

    for (final user in users) {
      if (user == null) continue;
      if (user['assignedDoctor'] != doctorId) continue;

      final riskLevel = _stringValue(user['riskLevel'])?.toLowerCase();
      if (riskLevel != null && result.containsKey(riskLevel)) {
        result[riskLevel] = result[riskLevel]! + 1;
      }
    }

    return result;
  }

  static List<Map<String, dynamic>> recentMeasurementsForDoctor({
    required Iterable<Map<String, dynamic>?> measurements,
    required Set<String> approvedPatientIds,
    int limit = 5,
  }) {
    final filtered = measurements.whereType<Map<String, dynamic>>().where((
      measurement,
    ) {
      final patientId = _stringValue(measurement['uid']);
      return patientId != null && approvedPatientIds.contains(patientId);
    }).toList();

    filtered.sort((a, b) {
      final aDate = _dateFromFirestoreLikeValue(a['tarih']);
      final bDate = _dateFromFirestoreLikeValue(b['tarih']);
      return (bDate ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
        aDate ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
    });

    return List.unmodifiable(filtered.take(limit));
  }

  static bool _hasAnyHighRisk(Map<String, dynamic> measurement) {
    return _isHighRisk(measurement['preeklampsiRisk']) ||
        _isHighRisk(measurement['diyabetRisk']) ||
        _isHighRisk(measurement['pretermRisk']);
  }

  static bool _isHighRisk(dynamic value) {
    return _stringValue(value)?.toUpperCase() == 'HIGH';
  }

  static String? _stringValue(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
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
