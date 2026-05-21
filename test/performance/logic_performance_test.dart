import 'package:flutter_test/flutter_test.dart';
import 'package:pregnova/admin/admin_panel_logic.dart';
import 'package:pregnova/dietitian/dietitian_panel_logic.dart';
import 'package:pregnova/gynecologist/gynecologist_panel_logic.dart';
import 'package:pregnova/shared/bmi_calculator.dart';
import 'package:pregnova/shared/daily_nutrition_summary.dart';
import 'package:pregnova/shared/firestore_data_validator.dart';
import 'package:pregnova/shared/pregnancy_week_calculator.dart';
import 'package:pregnova/shared/risk_analysis_service.dart';
import 'package:pregnova/shared/weekly_notification_message.dart';

void main() {
  group('Lightweight logic performance', () {
    test('calculates pregnancy weeks for 10000 records under threshold', () {
      final result = _benchmark(() {
        for (var i = 0; i < 10000; i++) {
          final week = PregnancyWeekCalculator.calculate(
            pregnancyStartDate: DateTime(
              2026,
              1,
              1,
            ).add(Duration(days: i % 280)),
            now: DateTime(2026, 5, 20),
          );

          expect(week, inInclusiveRange(1, 42));
        }
      });

      _printPerformanceBenchmark(
        'Pregnancy week calculation',
        records: 10000,
        result: result,
        thresholdMilliseconds: 500,
      );
      expect(result.averageMilliseconds, lessThan(500));
    });

    test('calculates BMI and categories for 10000 records under threshold', () {
      final result = _benchmark(() {
        for (var i = 0; i < 10000; i++) {
          final bmi = BmiCalculator.calculate(
            weightKg: 50 + (i % 40),
            heightCm: 150 + (i % 35),
          );
          final category = BmiCalculator.category(bmi);

          expect(bmi, isNotNull);
          expect(category, isNot('unknown'));
        }
      });

      _printPerformanceBenchmark(
        'BMI calculation',
        records: 10000,
        result: result,
        thresholdMilliseconds: 100,
      );
      expect(result.averageMilliseconds, lessThan(100));
    });

    test('summarizes 5000 nutrition analyses under threshold', () {
      final analyses = List.generate(5000, (index) {
        return {
          'kalori': 100 + (index % 300),
          'totalNutrients': {
            'protein': 5 + (index % 20),
            'carbs': 10 + (index % 30),
            'fat': 2 + (index % 10),
          },
        };
      });

      late DailyNutritionSummary summary;
      final result = _benchmark(() {
        summary = DailyNutritionSummaryService.summarize(analyses);
      });

      expect(summary.calories, greaterThan(0));
      expect(summary.nutrients['protein'], greaterThan(0));
      _printPerformanceBenchmark(
        'Daily nutrition summary',
        records: 5000,
        result: result,
        thresholdMilliseconds: 100,
      );
      expect(result.averageMilliseconds, lessThan(100));
    });

    test('calculates 10000 risk scores under threshold', () {
      final result = _benchmark(() {
        for (var i = 0; i < 10000; i++) {
          final preeclampsia = RiskAnalysisService.calculatePreeklampsi(
            systolic: 110 + (i % 70),
            diastolic: 70 + (i % 50),
            headache: i.isEven,
            swelling: i % 3 == 0,
          );
          final diabetes = RiskAnalysisService.calculateDiabetes(
            fastingGlucose: 80 + (i % 80),
            postMealGlucose: 110 + (i % 120),
            excessiveThirst: i % 4 == 0,
          );
          final preterm = RiskAnalysisService.calculatePreterm(
            contraction: i % 5 == 0,
            discharge: i % 6 == 0,
            stressLevel: (i % 5) + 1,
          );
          final overall = RiskAnalysisService.calculateOverallRisk([
            preeclampsia,
            diabetes,
            preterm,
          ]);

          expect(overall, isIn(['LOW', 'MEDIUM', 'HIGH']));
        }
      });

      _printPerformanceBenchmark(
        'Risk score calculation',
        records: 10000,
        result: result,
        thresholdMilliseconds: 150,
      );
      expect(result.averageMilliseconds, lessThan(150));
    });

    test('filters gynecologist dashboard data for 5000 measurements', () {
      final approvedPatientIds = List.generate(
        1000,
        (index) => 'patient-$index',
      ).toSet();
      final measurements = List.generate(5000, (index) {
        return {
          'uid': 'patient-${index % 1300}',
          'tarih': DateTime(2026, 5, 20).subtract(Duration(days: index % 14)),
          'preeklampsiRisk': index % 11 == 0 ? 'HIGH' : 'LOW',
          'diyabetRisk': index % 17 == 0 ? 'HIGH' : 'LOW',
          'pretermRisk': index % 23 == 0 ? 'HIGH' : 'LOW',
        };
      });

      late int highRiskCount;
      late int activeCount;
      late List<Map<String, dynamic>> recent;
      final result = _benchmark(() {
        highRiskCount = GynecologistPanelLogic.highRiskPatientCount(
          approvedPatientIds: approvedPatientIds,
          measurements: measurements,
        );
        activeCount = GynecologistPanelLogic.activePatientCountLast7Days(
          approvedPatientIds: approvedPatientIds,
          measurements: measurements,
          now: DateTime(2026, 5, 20),
        );
        recent = GynecologistPanelLogic.recentMeasurementsForDoctor(
          approvedPatientIds: approvedPatientIds,
          measurements: measurements,
          limit: 10,
        );
      });

      expect(highRiskCount, greaterThan(0));
      expect(activeCount, greaterThan(0));
      expect(recent.length, 10);
      _printPerformanceBenchmark(
        'Gynecologist dashboard filtering',
        records: 5000,
        result: result,
        thresholdMilliseconds: 250,
      );
      expect(result.averageMilliseconds, lessThan(250));
    });

    test('filters dietitian dashboard analyses for 5000 records', () {
      final analyses = List.generate(5000, (index) {
        return {
          'id': 'analysis-$index',
          'uid': 'client-${index % 800}',
          'dietitianId': index % 3 == 0 ? 'dietitian-1' : 'dietitian-2',
          'createdAt': DateTime(
            2026,
            5,
            20,
          ).subtract(Duration(hours: index % 240)),
          'kalori': 100 + (index % 400),
        };
      });

      late int activeAnalysisCount;
      late List<Map<String, dynamic>> recent;
      late List<DietitianDailyAnalysisGroup> groups;
      final result = _benchmark(() {
        activeAnalysisCount = DietitianPanelLogic.activeAnalysisCountLast7Days(
          analyses: analyses,
          dietitianId: 'dietitian-1',
          now: DateTime(2026, 5, 20),
        );
        recent = DietitianPanelLogic.recentAnalysesForDietitian(
          analyses: analyses,
          dietitianId: 'dietitian-1',
          limit: 10,
        );
        groups = DietitianPanelLogic.groupAnalysesByDay(
          analyses.where((analysis) => analysis['dietitianId'] == 'dietitian-1'),
        );
      });

      expect(activeAnalysisCount, greaterThan(0));
      expect(recent.length, 10);
      expect(groups, isNotEmpty);
      _printPerformanceBenchmark(
        'Dietitian dashboard filtering',
        records: 5000,
        result: result,
        thresholdMilliseconds: 250,
      );
      expect(result.averageMilliseconds, lessThan(250));
    });

    test('builds admin system report for large datasets under threshold', () {
      final users = List.generate(5000, (index) {
        final role = switch (index % 4) {
          0 => 'pregnant',
          1 => 'gynecologist',
          2 => 'dietitian',
          _ => 'admin',
        };

        return {
          'role': role,
          'isApproved': role == 'gynecologist' || role == 'dietitian',
        };
      });
      final risks = List.generate(5000, (index) {
        return {
          'riskLevel': switch (index % 3) {
            0 => 'high',
            1 => 'medium',
            _ => 'normal',
          },
        };
      });
      final analyses = List.generate(5000, (index) => {'uid': 'user-$index'});
      final applications = List.generate(1000, (index) {
        return {
          'status': switch (index % 3) {
            0 => 'approved',
            1 => 'rejected',
            _ => 'pending',
          },
        };
      });

      late AdminSystemReport report;
      final result = _benchmark(() {
        report = AdminPanelLogic.systemReport(
          users: users,
          risks: risks,
          nutritionAnalyses: analyses,
          applications: applications,
        );
      });

      expect(report.totalUsers, 5000);
      expect(report.riskMeasurements, 5000);
      expect(report.nutritionAnalyses, 5000);
      _printPerformanceBenchmark(
        'Admin system report generation',
        records: 16000,
        result: result,
        thresholdMilliseconds: 250,
      );
      expect(result.averageMilliseconds, lessThan(250));
    });

    test('validates 10000 Firestore-like documents under threshold', () {
      final documents = List.generate(10000, (index) {
        return switch (index % 4) {
          0 => {
            'uid': 'patient-$index',
            'title': 'Risk Warning',
            'message': 'Check measurements',
            'type': 'risk_alert',
            'isRead': false,
            'createdAt': DateTime(2026, 5, 20),
          },
          1 => {
            'clientId': 'patient-$index',
            'expertId': 'expert-$index',
            'status': 'pending',
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
          _ => {
            'users': ['patient-$index', 'expert-$index'],
            'lastMessage': 'Hello',
            'lastMessageTime': DateTime(2026, 5, 20),
          },
        };
      });

      late int validCount;
      final result = _benchmark(() {
        validCount = 0;
        for (var i = 0; i < documents.length; i++) {
          final document = documents[i];
          final valid = switch (i % 4) {
            0 => FirestoreDataValidator.isValidNotification(document),
            1 => FirestoreDataValidator.isValidExpertRequest(document),
            2 => FirestoreDataValidator.isValidDietPlan(document),
            _ => FirestoreDataValidator.isValidChat(document),
          };
          if (valid) validCount++;
        }
      });

      expect(validCount, documents.length);
      _printPerformanceBenchmark(
        'Firestore schema validation',
        records: 10000,
        result: result,
        thresholdMilliseconds: 250,
      );
      expect(result.averageMilliseconds, lessThan(250));
    });

    test('generates weekly notification messages under threshold', () {
      late int generatedMessages;
      final result = _benchmark(() {
        generatedMessages = 0;
        for (var i = 0; i < 10000; i++) {
          final message = WeeklyNotificationMessage.messageFor(
            week: (i % 42) + 1,
            languageCode: i.isEven ? 'tr' : 'en',
          );

          if (message.isNotEmpty) generatedMessages++;
        }
      });

      expect(generatedMessages, 10000);
      _printPerformanceBenchmark(
        'Weekly notification message generation',
        records: 10000,
        result: result,
        thresholdMilliseconds: 100,
      );
      expect(result.averageMilliseconds, lessThan(100));
    });
  });
}

PerformanceBenchmarkResult _benchmark(
  void Function() operation, {
  int runs = 5,
}) {
  final elapsedValues = <int>[];

  for (var i = 0; i < runs; i++) {
    final stopwatch = Stopwatch()..start();
    operation();
    stopwatch.stop();
    elapsedValues.add(stopwatch.elapsedMilliseconds);
  }

  elapsedValues.sort();
  final total = elapsedValues.reduce((sum, value) => sum + value);

  return PerformanceBenchmarkResult(
    runs: runs,
    minMilliseconds: elapsedValues.first,
    maxMilliseconds: elapsedValues.last,
    averageMilliseconds: total / runs,
  );
}

void _printPerformanceBenchmark(
  String name, {
  required int records,
  required PerformanceBenchmarkResult result,
  required int thresholdMilliseconds,
}) {
  // Machine-readable output for reporting and thesis tables.
  // ignore: avoid_print
  print(
    'PERF_RESULT|$name|$records|${result.averageMilliseconds.toStringAsFixed(2)}|'
    '${result.minMilliseconds}|${result.maxMilliseconds}|$thresholdMilliseconds|${result.runs}',
  );
}

class PerformanceBenchmarkResult {
  final int runs;
  final int minMilliseconds;
  final int maxMilliseconds;
  final double averageMilliseconds;

  const PerformanceBenchmarkResult({
    required this.runs,
    required this.minMilliseconds,
    required this.maxMilliseconds,
    required this.averageMilliseconds,
  });
}
