class FormValidationRules {
  const FormValidationRules._();

  static bool hasText(String? value) {
    return value?.trim().isNotEmpty ?? false;
  }

  static bool isValidEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return false;

    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  static bool isValidPassword(String? value, {int minLength = 6}) {
    return (value ?? '').length >= minLength;
  }

  static bool isPositiveNumberText(String? value) {
    final parsed = num.tryParse(value?.trim().replaceAll(',', '.') ?? '');
    return parsed != null && parsed > 0;
  }

  static bool isPregnancyWeek(String? value) {
    final week = int.tryParse(value?.trim() ?? '');
    return week != null && week >= 1 && week <= 42;
  }

  static bool canSubmitRiskMeasurement({
    required String? systolic,
    required String? diastolic,
    required String? fastingGlucose,
    required String? postMealGlucose,
  }) {
    return isPositiveNumberText(systolic) &&
        isPositiveNumberText(diastolic) &&
        isPositiveNumberText(fastingGlucose) &&
        isPositiveNumberText(postMealGlucose);
  }

  static bool canAddNutritionItem({
    required String? name,
    required String? amount,
  }) {
    return hasText(name) && isPositiveNumberText(amount);
  }

  static bool canSubmitNutritionAnalysis({
    required int foodCount,
    required int supplementCount,
    required String? assignedDietitianId,
  }) {
    return foodCount + supplementCount > 0 && hasText(assignedDietitianId);
  }

  static bool canSubmitDietPlan({
    required String? clientId,
    required String? dietitianId,
    required String? breakfast,
    required String? lunch,
    required String? dinner,
  }) {
    return hasText(clientId) &&
        hasText(dietitianId) &&
        hasText(breakfast) &&
        hasText(lunch) &&
        hasText(dinner);
  }

  static bool canSubmitExpertApplication({
    required String? role,
    required String? fullName,
    required String? clinicName,
    required String? diplomaUrl,
  }) {
    final normalizedRole = role?.trim().toLowerCase();
    final validRole =
        normalizedRole == 'gynecologist' || normalizedRole == 'dietitian';

    return validRole &&
        hasText(fullName) &&
        hasText(clinicName) &&
        hasText(diplomaUrl);
  }
}
