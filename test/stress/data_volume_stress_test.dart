import 'package:flutter_test/flutter_test.dart';
import 'package:pregnova/admin/admin_panel_logic.dart';
import 'package:pregnova/dietitian/dietitian_panel_logic.dart';
import 'package:pregnova/gynecologist/gynecologist_panel_logic.dart';
import 'package:pregnova/shared/daily_nutrition_summary.dart';
import 'package:pregnova/shared/firestore_data_validator.dart';
import 'package:pregnova/shared/risk_analysis_service.dart';

void main() {
  group('Stress / data volume tests', () {
    test('summarizes a high-volume daily nutrition dataset', () {
      final analyses = List.generate(25000, (index) {
        return {
          'kalori': 120 + (index % 380),
          'totalNutrients': {
            'protein': 4 + (index % 30),
            'carbs': 12 + (index % 45),
            'fat': 2 + (index % 18),
            'iron': index % 4 == 0 ? 1.2 : 0.4,
          },
        };
      });

      late DailyNutritionSummary summary;
      final elapsed = _measure(() {
        summary = DailyNutritionSummaryService.summarize(analyses);
      });

      expect(summary.calories, greaterThan(0));
      expect(summary.nutrients['protein'], greaterThan(0));
      expect(summary.nutrients['iron'], greaterThan(0));
      _printStressResult(
        'High-volume nutrition summary',
        records: analyses.length,
        elapsedMilliseconds: elapsed,
        thresholdMilliseconds: 750,
      );
      expect(elapsed, lessThan(750));
    });

    test('calculates risk levels for a high-volume measurement dataset', () {
      var highRiskCount = 0;
      final elapsed = _measure(() {
        for (var i = 0; i < 30000; i++) {
          final preeclampsia = RiskAnalysisService.calculatePreeklampsi(
            systolic: 105 + (i % 75),
            diastolic: 65 + (i % 55),
            headache: i % 7 == 0,
            swelling: i % 9 == 0,
            chronicHypertension: i % 29 == 0,
          );
          final diabetes = RiskAnalysisService.calculateDiabetes(
            fastingGlucose: 78 + (i % 90),
            postMealGlucose: 105 + (i % 125),
            excessiveThirst: i % 11 == 0,
            frequentUrination: i % 13 == 0,
          );
          final preterm = RiskAnalysisService.calculatePreterm(
            contraction: i % 17 == 0,
            discharge: i % 19 == 0,
            backPain: i % 23 == 0,
            stressLevel: (i % 5) + 1,
          );
          final overall = RiskAnalysisService.calculateOverallRisk([
            preeclampsia,
            diabetes,
            preterm,
          ]);

          if (overall == SharedRiskLevel.high) highRiskCount++;
        }
      });

      expect(highRiskCount, greaterThan(0));
      _printStressResult(
        'High-volume risk calculation',
        records: 30000,
        elapsedMilliseconds: elapsed,
        thresholdMilliseconds: 750,
      );
      expect(elapsed, lessThan(750));
    });

    test('filters gynecologist and dietitian panel data at higher volume', () {
      final approvedPatientIds = List.generate(
        5000,
        (index) => 'patient-$index',
      ).toSet();
      final measurements = List.generate(20000, (index) {
        return {
          'uid': 'patient-${index % 7000}',
          'tarih': DateTime(2026, 5, 20).subtract(Duration(days: index % 30)),
          'preeklampsiRisk': index % 13 == 0 ? 'HIGH' : 'LOW',
          'diyabetRisk': index % 17 == 0 ? 'HIGH' : 'LOW',
          'pretermRisk': index % 23 == 0 ? 'HIGH' : 'LOW',
        };
      });
      final analyses = List.generate(20000, (index) {
        return {
          'uid': 'client-${index % 6500}',
          'dietitianId': index % 4 == 0 ? 'dietitian-1' : 'dietitian-2',
          'createdAt': DateTime(
            2026,
            5,
            20,
          ).subtract(Duration(hours: index % 720)),
          'kalori': 180 + (index % 420),
        };
      });

      late int highRiskPatients;
      late int activePatients;
      late int activeAnalyses;
      late List<DietitianDailyAnalysisGroup> groupedAnalyses;
      final elapsed = _measure(() {
        highRiskPatients = GynecologistPanelLogic.highRiskPatientCount(
          measurements: measurements,
          approvedPatientIds: approvedPatientIds,
        );
        activePatients = GynecologistPanelLogic.activePatientCountLast7Days(
          measurements: measurements,
          approvedPatientIds: approvedPatientIds,
          now: DateTime(2026, 5, 20),
        );
        activeAnalyses = DietitianPanelLogic.activeAnalysisCountLast7Days(
          analyses: analyses,
          dietitianId: 'dietitian-1',
          now: DateTime(2026, 5, 20),
        );
        groupedAnalyses = DietitianPanelLogic.groupAnalysesByDay(
          analyses.where((analysis) => analysis['dietitianId'] == 'dietitian-1'),
        );
      });

      expect(highRiskPatients, greaterThan(0));
      expect(activePatients, greaterThan(0));
      expect(activeAnalyses, greaterThan(0));
      expect(groupedAnalyses, isNotEmpty);
      _printStressResult(
        'High-volume panel filtering',
        records: measurements.length + analyses.length,
        elapsedMilliseconds: elapsed,
        thresholdMilliseconds: 1000,
      );
      expect(elapsed, lessThan(1000));
    });

    test('validates large Firestore-like mixed dataset schemas', () {
      final documents = List.generate(30000, (index) {
        return switch (index % 5) {
          0 => {
            'uid': 'patient-$index',
            'title': 'Risk',
            'message': 'Control required',
            'type': 'risk_alert',
            'isRead': false,
            'createdAt': DateTime(2026, 5, 20),
          },
          1 => {
            'clientId': 'patient-$index',
            'expertId': 'expert-$index',
            'status': 'approved',
            'createdAt': DateTime(2026, 5, 20),
          },
          2 => {
            'clientId': 'patient-$index',
            'dietitianId': 'dietitian-$index',
            'kahvalti': 'sut',
            'ogle': 'sebze',
            'aksam': 'pilav',
            'createdAt': DateTime(2026, 5, 20),
          },
          3 => {
            'users': ['patient-$index', 'expert-$index'],
            'lastMessage': 'Merhaba',
            'lastMessageTime': DateTime(2026, 5, 20),
          },
          _ => {
            'uid': 'patient-$index',
            'createdAt': DateTime(2026, 5, 20),
            'besinler': ['sut', 'yumurta'],
            'toplam': {'kalori': 320, 'protein': 18},
          },
        };
      });

      late int validCount;
      final elapsed = _measure(() {
        validCount = 0;
        for (var i = 0; i < documents.length; i++) {
          final document = documents[i];
          final isValid = switch (i % 5) {
            0 => FirestoreDataValidator.isValidNotification(document),
            1 => FirestoreDataValidator.isValidExpertRequest(document),
            2 => FirestoreDataValidator.isValidDietPlan(document),
            3 => FirestoreDataValidator.isValidChat(document),
            _ => FirestoreDataValidator.isValidNutritionAnalysis(document),
          };
          if (isValid) validCount++;
        }
      });

      expect(validCount, documents.length);
      _printStressResult(
        'High-volume schema validation',
        records: documents.length,
        elapsedMilliseconds: elapsed,
        thresholdMilliseconds: 1000,
      );
      expect(elapsed, lessThan(1000));
    });

    test('builds admin report from high-volume mixed data', () {
      final users = List.generate(20000, (index) {
        final role = switch (index % 4) {
          0 => 'pregnant',
          1 => 'gynecologist',
          2 => 'dietitian',
          _ => 'admin',
        };
        return {'role': role, 'isApproved': index % 3 != 0};
      });
      final risks = List.generate(20000, (index) {
        return {
          'riskLevel': switch (index % 3) {
            0 => 'high',
            1 => 'medium',
            _ => 'normal',
          },
        };
      });
      final nutritionAnalyses = List.generate(
        20000,
        (index) => {'uid': 'patient-$index'},
      );
      final applications = List.generate(5000, (index) {
        return {
          'status': switch (index % 3) {
            0 => 'approved',
            1 => 'rejected',
            _ => 'pending',
          },
        };
      });

      late AdminSystemReport report;
      final elapsed = _measure(() {
        report = AdminPanelLogic.systemReport(
          users: users,
          risks: risks,
          nutritionAnalyses: nutritionAnalyses,
          applications: applications,
        );
      });

      expect(report.totalUsers, users.length);
      expect(report.riskMeasurements, risks.length);
      expect(report.nutritionAnalyses, nutritionAnalyses.length);
      _printStressResult(
        'High-volume admin report',
        records:
            users.length +
            risks.length +
            nutritionAnalyses.length +
            applications.length,
        elapsedMilliseconds: elapsed,
        thresholdMilliseconds: 1000,
      );
      expect(elapsed, lessThan(1000));
    });
  });
}

int _measure(void Function() operation) {
  final stopwatch = Stopwatch()..start();
  operation();
  stopwatch.stop();
  return stopwatch.elapsedMilliseconds;
}

void _printStressResult(
  String name, {
  required int records,
  required int elapsedMilliseconds,
  required int thresholdMilliseconds,
}) {
  // Machine-readable output for report tables.
  // ignore: avoid_print
  print(
    'STRESS_RESULT|$name|$records|$elapsedMilliseconds|'
    '$thresholdMilliseconds',
  );
}
