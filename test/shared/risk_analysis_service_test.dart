import 'package:flutter_test/flutter_test.dart';
import 'package:pregnova/shared/risk_analysis_service.dart';

void main() {
  group('RiskAnalysisService preeklampsi', () {
    test('returns HIGH for emergency blood pressure values', () {
      expect(
        RiskAnalysisService.calculatePreeklampsi(systolic: 160, diastolic: 80),
        SharedRiskLevel.high,
      );
      expect(
        RiskAnalysisService.calculatePreeklampsi(systolic: 120, diastolic: 110),
        SharedRiskLevel.high,
      );
    });

    test('returns LOW for null and zero inputs without symptoms', () {
      expect(
        RiskAnalysisService.calculatePreeklampsi(systolic: null, diastolic: 0),
        SharedRiskLevel.low,
      );
    });

    test('scores symptoms and chronic hypertension as MEDIUM', () {
      expect(
        RiskAnalysisService.calculatePreeklampsi(
          systolic: 130,
          diastolic: 80,
          headache: true,
          visionProblem: true,
          chronicHypertension: true,
        ),
        SharedRiskLevel.medium,
      );
    });

    test('returns MEDIUM at non-emergency blood pressure thresholds', () {
      expect(
        RiskAnalysisService.calculatePreeklampsi(systolic: 140, diastolic: 80),
        SharedRiskLevel.medium,
      );
      expect(
        RiskAnalysisService.calculatePreeklampsi(systolic: 120, diastolic: 90),
        SharedRiskLevel.medium,
      );
      expect(
        RiskAnalysisService.calculatePreeklampsi(
          systolic: 140,
          diastolic: 90,
        ),
        SharedRiskLevel.medium,
      );
    });

    test('ignores negative blood pressure values', () {
      expect(
        RiskAnalysisService.calculatePreeklampsi(
          systolic: -160,
          diastolic: -110,
          headache: true,
        ),
        SharedRiskLevel.low,
      );
    });
  });

  group('RiskAnalysisService diabetes', () {
    test('returns HIGH for diabetic threshold values', () {
      expect(
        RiskAnalysisService.calculateDiabetes(
          fastingGlucose: 126,
          postMealGlucose: null,
        ),
        SharedRiskLevel.high,
      );
      expect(
        RiskAnalysisService.calculateDiabetes(
          fastingGlucose: null,
          postMealGlucose: 200,
        ),
        SharedRiskLevel.high,
      );
    });

    test('returns LOW for null, zero, or negative glucose values', () {
      expect(
        RiskAnalysisService.calculateDiabetes(
          fastingGlucose: null,
          postMealGlucose: 0,
        ),
        SharedRiskLevel.low,
      );
      expect(
        RiskAnalysisService.calculateDiabetes(
          fastingGlucose: -10,
          postMealGlucose: -20,
        ),
        SharedRiskLevel.low,
      );
    });

    test('returns MEDIUM for borderline glucose with symptoms', () {
      expect(
        RiskAnalysisService.calculateDiabetes(
          fastingGlucose: 95,
          postMealGlucose: null,
        ),
        SharedRiskLevel.medium,
      );
      expect(
        RiskAnalysisService.calculateDiabetes(
          fastingGlucose: 94,
          postMealGlucose: 140,
        ),
        SharedRiskLevel.medium,
      );
      expect(
        RiskAnalysisService.calculateDiabetes(
          fastingGlucose: 95,
          postMealGlucose: 120,
          excessiveThirst: true,
          frequentUrination: true,
        ),
        SharedRiskLevel.medium,
      );
    });

    test('escalates borderline glucose to HIGH with diabetic history and symptoms', () {
      expect(
        RiskAnalysisService.calculateDiabetes(
          fastingGlucose: 95,
          postMealGlucose: 120,
          excessiveThirst: true,
          frequentUrination: true,
          diabetesHistory: true,
        ),
        SharedRiskLevel.high,
      );
    });
  });

  group('RiskAnalysisService preterm', () {
    test('returns HIGH when multiple strong risk factors exist', () {
      expect(
        RiskAnalysisService.calculatePreterm(
          contraction: true,
          stressLevel: 5,
          previousPreterm: true,
        ),
        SharedRiskLevel.high,
      );
    });

    test('returns LOW for empty or null risk inputs', () {
      expect(
        RiskAnalysisService.calculatePreterm(stressLevel: null),
        SharedRiskLevel.low,
      );
    });

    test('scores stress level 4 as MEDIUM and stress level 5 stronger', () {
      expect(
        RiskAnalysisService.calculatePreterm(
          stressLevel: 4,
          contraction: true,
        ),
        SharedRiskLevel.medium,
      );
      expect(
        RiskAnalysisService.calculatePreterm(
          stressLevel: 5,
          contraction: true,
          discharge: true,
        ),
        SharedRiskLevel.high,
      );
    });

    test('ignores negative stress levels', () {
      expect(
        RiskAnalysisService.calculatePreterm(stressLevel: -3),
        SharedRiskLevel.low,
      );
    });
  });

  group('RiskAnalysisService overall risk', () {
    test('prioritizes HIGH over MEDIUM and LOW', () {
      expect(
        RiskAnalysisService.calculateOverallRisk([
          SharedRiskLevel.low,
          SharedRiskLevel.high,
          SharedRiskLevel.medium,
        ]),
        SharedRiskLevel.high,
      );
    });

    test('returns LOW for empty or null-only risk list', () {
      expect(RiskAnalysisService.calculateOverallRisk([]), SharedRiskLevel.low);
      expect(
        RiskAnalysisService.calculateOverallRisk([null]),
        SharedRiskLevel.low,
      );
    });

    test('normalizes lowercase and mixed-case risk labels', () {
      expect(
        RiskAnalysisService.calculateOverallRisk(['low', 'medium']),
        SharedRiskLevel.medium,
      );
      expect(
        RiskAnalysisService.calculateOverallRisk(['LoW', 'hIgH']),
        SharedRiskLevel.high,
      );
    });
  });
}
