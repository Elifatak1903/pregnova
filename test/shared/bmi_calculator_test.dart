import 'package:flutter_test/flutter_test.dart';
import 'package:pregnova/shared/bmi_calculator.dart';

void main() {
  group('BmiCalculator', () {
    test('calculates BMI from kilogram and centimeter values', () {
      final bmi = BmiCalculator.calculate(weightKg: 70, heightCm: 170);

      expect(bmi, closeTo(24.22, 0.01));
    });

    test('returns null when weight is null or zero', () {
      expect(BmiCalculator.calculate(weightKg: null, heightCm: 170), isNull);
      expect(BmiCalculator.calculate(weightKg: 0, heightCm: 170), isNull);
      expect(BmiCalculator.calculate(weightKg: -55, heightCm: 170), isNull);
    });

    test('returns null when height is null, zero, or negative', () {
      expect(BmiCalculator.calculate(weightKg: 70, heightCm: null), isNull);
      expect(BmiCalculator.calculate(weightKg: 70, heightCm: 0), isNull);
      expect(BmiCalculator.calculate(weightKg: 70, heightCm: -160), isNull);
    });

    test('handles decimal weight and height values', () {
      final bmi = BmiCalculator.calculate(weightKg: 68.5, heightCm: 165.5);

      expect(bmi, closeTo(25.01, 0.01));
    });

    test('handles extreme but positive values without crashing', () {
      expect(
        BmiCalculator.calculate(weightKg: 1, heightCm: 250),
        closeTo(0.16, 0.01),
      );
      expect(
        BmiCalculator.calculate(weightKg: 300, heightCm: 100),
        closeTo(300, 0.01),
      );
    });

    test('returns expected BMI category boundaries', () {
      expect(BmiCalculator.category(null), 'unknown');
      expect(BmiCalculator.category(0), 'unknown');
      expect(BmiCalculator.category(18.4), 'underweight');
      expect(BmiCalculator.category(18.5), 'normal');
      expect(BmiCalculator.category(24.9), 'normal');
      expect(BmiCalculator.category(25), 'overweight');
      expect(BmiCalculator.category(29.9), 'overweight');
      expect(BmiCalculator.category(30), 'obese');
    });
  });
}
