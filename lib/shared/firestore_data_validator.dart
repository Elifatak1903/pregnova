class FirestoreDataValidator {
  const FirestoreDataValidator._();

  static bool isValidUser(Map<String, dynamic>? data) {
    if (data == null) return false;

    final role = _trimmed(data['role']);
    if (role == null || !_validRoles.contains(role)) return false;

    if (data.containsKey('email') && _trimmed(data['email']) == null) {
      return false;
    }

    if (data.containsKey('riskLevel')) {
      final riskLevel = _trimmed(data['riskLevel'])?.toLowerCase();
      if (riskLevel == null || !_validUserRiskLevels.contains(riskLevel)) {
        return false;
      }
    }

    if (data.containsKey('assignedDoctor') &&
        !_isOptionalNonEmptyString(data['assignedDoctor'])) {
      return false;
    }

    if (data.containsKey('assignedDietitian') &&
        !_isOptionalNonEmptyString(data['assignedDietitian'])) {
      return false;
    }

    return true;
  }

  static bool isValidRiskMeasurement(Map<String, dynamic>? data) {
    if (data == null) return false;

    return _trimmed(data['uid']) != null &&
        _hasDateLikeValue(data['tarih']) &&
        _isPositiveNumber(data['sistolik']) &&
        _isPositiveNumber(data['diastolik']) &&
        _isRiskLabel(data['preeklampsiRisk']) &&
        _isRiskLabel(data['diyabetRisk']) &&
        _isRiskLabel(data['pretermRisk']);
  }

  static bool isValidNutritionAnalysis(Map<String, dynamic>? data) {
    if (data == null) return false;

    final foods = data['besinler'];
    final total = data['toplam'];

    return _trimmed(data['uid']) != null &&
        _hasDateLikeValue(data['createdAt'] ?? data['tarih']) &&
        foods is List &&
        foods.isNotEmpty &&
        total is Map &&
        _isNonNegativeNumber(total['kalori']);
  }

  static bool isValidNotification(Map<String, dynamic>? data) {
    if (data == null) return false;

    return _trimmed(data['uid']) != null &&
        _trimmed(data['title']) != null &&
        _trimmed(data['message']) != null &&
        _trimmed(data['type']) != null &&
        data['isRead'] is bool &&
        _hasDateLikeValue(data['createdAt']);
  }

  static bool isValidExpertRequest(Map<String, dynamic>? data) {
    if (data == null) return false;

    final status = _trimmed(data['status']);

    return _trimmed(data['clientId']) != null &&
        _trimmed(data['expertId']) != null &&
        status != null &&
        _validRequestStatuses.contains(status) &&
        (!data.containsKey('createdAt') || _hasDateLikeValue(data['createdAt']));
  }

  static bool isValidDietPlan(Map<String, dynamic>? data) {
    if (data == null) return false;

    return _trimmed(data['clientId']) != null &&
        _trimmed(data['dietitianId']) != null &&
        _trimmed(data['kahvalti']) != null &&
        _trimmed(data['ogle']) != null &&
        _trimmed(data['aksam']) != null &&
        (!data.containsKey('createdAt') || _hasDateLikeValue(data['createdAt']));
  }

  static bool isValidChat(Map<String, dynamic>? data) {
    if (data == null) return false;

    final users = data['users'];

    return users is List &&
        users.length >= 2 &&
        users.every((userId) => _trimmed(userId) != null) &&
        data['lastMessage'] is String &&
        (!data.containsKey('lastMessageTime') ||
            _hasDateLikeValue(data['lastMessageTime']));
  }

  static const _validRoles = {
    'pregnant',
    'gynecologist',
    'dietitian',
    'admin',
  };

  static const _validUserRiskLevels = {
    'normal',
    'low',
    'medium',
    'high',
  };

  static const _validRequestStatuses = {
    'pending',
    'approved',
    'rejected',
    'removed',
  };

  static bool _isRiskLabel(dynamic value) {
    final text = _trimmed(value)?.toUpperCase();
    return text == 'LOW' || text == 'MEDIUM' || text == 'HIGH';
  }

  static bool _isPositiveNumber(dynamic value) {
    final number = _number(value);
    return number != null && number > 0;
  }

  static bool _isNonNegativeNumber(dynamic value) {
    final number = _number(value);
    return number != null && number >= 0;
  }

  static num? _number(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '');
  }

  static bool _isOptionalNonEmptyString(dynamic value) {
    return value == null || _trimmed(value) != null;
  }

  static String? _trimmed(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static bool _hasDateLikeValue(dynamic value) {
    if (value == null) return false;
    if (value is DateTime) return true;

    try {
      final dynamic firestoreLikeValue = value;
      final date = firestoreLikeValue.toDate();
      if (date is DateTime) return true;
    } catch (_) {
      return false;
    }

    return false;
  }
}
