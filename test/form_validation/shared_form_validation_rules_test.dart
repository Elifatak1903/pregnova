import 'package:flutter_test/flutter_test.dart';
import 'package:pregnova/shared/form_validation_rules.dart';

void main() {
  group('Shared form validation rules', () {
    test('validates required text by trimming whitespace', () {
      expect(FormValidationRules.hasText(' Elif '), isTrue);
      expect(FormValidationRules.hasText('   '), isFalse);
      expect(FormValidationRules.hasText(null), isFalse);
    });

    test('validates email format without accepting empty or malformed input', () {
      expect(FormValidationRules.isValidEmail('user@example.com'), isTrue);
      expect(FormValidationRules.isValidEmail(' user@example.com '), isTrue);
      expect(FormValidationRules.isValidEmail('userexample.com'), isFalse);
      expect(FormValidationRules.isValidEmail('user@'), isFalse);
      expect(FormValidationRules.isValidEmail(null), isFalse);
    });

    test('validates password minimum length', () {
      expect(FormValidationRules.isValidPassword('123456'), isTrue);
      expect(FormValidationRules.isValidPassword('12345'), isFalse);
      expect(FormValidationRules.isValidPassword(null), isFalse);
    });

    test('validates positive numeric text and comma decimals', () {
      expect(FormValidationRules.isPositiveNumberText('12'), isTrue);
      expect(FormValidationRules.isPositiveNumberText('12,5'), isTrue);
      expect(FormValidationRules.isPositiveNumberText('0'), isFalse);
      expect(FormValidationRules.isPositiveNumberText('-1'), isFalse);
      expect(FormValidationRules.isPositiveNumberText('abc'), isFalse);
    });

    test('accepts only pregnancy weeks between 1 and 42', () {
      expect(FormValidationRules.isPregnancyWeek('1'), isTrue);
      expect(FormValidationRules.isPregnancyWeek('42'), isTrue);
      expect(FormValidationRules.isPregnancyWeek('0'), isFalse);
      expect(FormValidationRules.isPregnancyWeek('43'), isFalse);
      expect(FormValidationRules.isPregnancyWeek('hafta'), isFalse);
    });

    test('requires core numeric fields for risk measurement submit', () {
      expect(
        FormValidationRules.canSubmitRiskMeasurement(
          systolic: '120',
          diastolic: '80',
          fastingGlucose: '90',
          postMealGlucose: '130',
        ),
        isTrue,
      );

      expect(
        FormValidationRules.canSubmitRiskMeasurement(
          systolic: '',
          diastolic: '80',
          fastingGlucose: '90',
          postMealGlucose: '130',
        ),
        isFalse,
      );
    });

    test('rejects zero or negative risk measurement values', () {
      expect(
        FormValidationRules.canSubmitRiskMeasurement(
          systolic: '0',
          diastolic: '80',
          fastingGlucose: '90',
          postMealGlucose: '130',
        ),
        isFalse,
      );

      expect(
        FormValidationRules.canSubmitRiskMeasurement(
          systolic: '120',
          diastolic: '-80',
          fastingGlucose: '90',
          postMealGlucose: '130',
        ),
        isFalse,
      );
    });

    test('requires nutrition item name and positive amount', () {
      expect(
        FormValidationRules.canAddNutritionItem(name: 'sut', amount: '2'),
        isTrue,
      );
      expect(
        FormValidationRules.canAddNutritionItem(name: '', amount: '2'),
        isFalse,
      );
      expect(
        FormValidationRules.canAddNutritionItem(name: 'sut', amount: '0'),
        isFalse,
      );
    });

    test('requires at least one nutrition item and assigned dietitian', () {
      expect(
        FormValidationRules.canSubmitNutritionAnalysis(
          foodCount: 1,
          supplementCount: 0,
          assignedDietitianId: 'dietitian-1',
        ),
        isTrue,
      );
      expect(
        FormValidationRules.canSubmitNutritionAnalysis(
          foodCount: 0,
          supplementCount: 0,
          assignedDietitianId: 'dietitian-1',
        ),
        isFalse,
      );
      expect(
        FormValidationRules.canSubmitNutritionAnalysis(
          foodCount: 1,
          supplementCount: 0,
          assignedDietitianId: ' ',
        ),
        isFalse,
      );
    });

    test('requires diet plan owner ids and main meals', () {
      expect(
        FormValidationRules.canSubmitDietPlan(
          clientId: 'client-1',
          dietitianId: 'dietitian-1',
          breakfast: 'sut',
          lunch: 'sebze',
          dinner: 'pilav',
        ),
        isTrue,
      );
      expect(
        FormValidationRules.canSubmitDietPlan(
          clientId: 'client-1',
          dietitianId: 'dietitian-1',
          breakfast: 'sut',
          lunch: '',
          dinner: 'pilav',
        ),
        isFalse,
      );
    });

    test('requires valid expert role and document for application submit', () {
      expect(
        FormValidationRules.canSubmitExpertApplication(
          role: 'gynecologist',
          fullName: 'Dr Ada',
          clinicName: 'PregNova Clinic',
          diplomaUrl: 'https://example.com/diploma.pdf',
        ),
        isTrue,
      );

      expect(
        FormValidationRules.canSubmitExpertApplication(
          role: 'pregnant',
          fullName: 'Ada',
          clinicName: 'PregNova Clinic',
          diplomaUrl: 'https://example.com/diploma.pdf',
        ),
        isFalse,
      );
    });

    test('rejects expert application when required text or diploma is missing', () {
      expect(
        FormValidationRules.canSubmitExpertApplication(
          role: 'dietitian',
          fullName: ' ',
          clinicName: 'PregNova Clinic',
          diplomaUrl: 'https://example.com/diploma.pdf',
        ),
        isFalse,
      );

      expect(
        FormValidationRules.canSubmitExpertApplication(
          role: 'dietitian',
          fullName: 'Dyt Ada',
          clinicName: 'PregNova Clinic',
          diplomaUrl: '',
        ),
        isFalse,
      );
    });
  });
}
