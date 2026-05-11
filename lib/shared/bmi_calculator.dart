class BmiCalculator {
  const BmiCalculator._();

  static double? calculate({
    required double? weightKg,
    required double? heightCm,
  }) {
    if (weightKg == null || heightCm == null) return null;
    if (weightKg <= 0 || heightCm <= 0) return null;

    final heightMeter = heightCm / 100;
    return weightKg / (heightMeter * heightMeter);
  }

  static String category(double? bmi) {
    if (bmi == null || bmi <= 0) return 'unknown';
    if (bmi < 18.5) return 'underweight';
    if (bmi < 25) return 'normal';
    if (bmi < 30) return 'overweight';
    return 'obese';
  }
}
