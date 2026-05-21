class SharedRiskLevel {
  static const low = 'LOW';
  static const medium = 'MEDIUM';
  static const high = 'HIGH';
}

class RiskAnalysisService {
  const RiskAnalysisService._();

  static String calculatePreeklampsi({
    required int? systolic,
    required int? diastolic,
    bool visionProblem = false,
    bool headache = false,
    bool swelling = false,
    bool chronicHypertension = false,
  }) {
    final safeSystolic = _positiveInt(systolic);
    final safeDiastolic = _positiveInt(diastolic);

    if (safeSystolic >= 160 || safeDiastolic >= 110) {
      return SharedRiskLevel.high;
    }

    var score = 0;
    if (safeSystolic >= 140) score += 2;
    if (safeDiastolic >= 90) score += 2;
    if (headache) score += 1;
    if (visionProblem) score += 1;
    if (swelling) score += 1;
    if (chronicHypertension) score += 2;

    final risk = _scoreToRisk(score);
    if ((safeSystolic >= 140 || safeDiastolic >= 90) &&
        risk == SharedRiskLevel.low) {
      return SharedRiskLevel.medium;
    }

    return risk;
  }

  static String calculateDiabetes({
    required double? fastingGlucose,
    required double? postMealGlucose,
    bool excessiveThirst = false,
    bool frequentUrination = false,
    bool diabetesHistory = false,
  }) {
    final safeFasting = _positiveDouble(fastingGlucose);
    final safePostMeal = _positiveDouble(postMealGlucose);

    if (safeFasting >= 126 || safePostMeal >= 200) {
      return SharedRiskLevel.high;
    }

    var score = 0;
    if (safeFasting >= 95) score += 2;
    if (safePostMeal >= 140) score += 2;
    if (excessiveThirst) score += 1;
    if (frequentUrination) score += 1;
    if (diabetesHistory) score += 2;

    final risk = _scoreToRisk(score);
    if ((safeFasting >= 95 || safePostMeal >= 140) &&
        risk == SharedRiskLevel.low) {
      return SharedRiskLevel.medium;
    }

    return risk;
  }

  static String calculatePreterm({
    bool contraction = false,
    bool discharge = false,
    bool backPain = false,
    double? stressLevel,
    bool previousPreterm = false,
    bool multiplePregnancy = false,
  }) {
    final safeStress = _positiveDouble(stressLevel);

    var score = 0;
    if (contraction) score += 2;
    if (discharge) score += 1;
    if (backPain) score += 1;
    if (safeStress == 5) {
      score += 3;
    } else if (safeStress >= 4) {
      score += 2;
    }
    if (previousPreterm) score += 2;
    if (multiplePregnancy) score += 2;

    return _scoreToRisk(score);
  }

  static String calculateOverallRisk(Iterable<String?> risks) {
    final normalized = risks.map((risk) => risk?.toUpperCase()).toList();
    if (normalized.contains(SharedRiskLevel.high)) return SharedRiskLevel.high;
    if (normalized.contains(SharedRiskLevel.medium)) {
      return SharedRiskLevel.medium;
    }
    return SharedRiskLevel.low;
  }

  static String _scoreToRisk(int score) {
    if (score <= 2) return SharedRiskLevel.low;
    if (score <= 5) return SharedRiskLevel.medium;
    return SharedRiskLevel.high;
  }

  static int _positiveInt(int? value) {
    if (value == null || value <= 0) return 0;
    return value;
  }

  static double _positiveDouble(double? value) {
    if (value == null || value <= 0) return 0;
    return value;
  }
}
