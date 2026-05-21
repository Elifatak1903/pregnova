import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cross-platform consistency', () {
    test('mobile and web risk engines keep the same clinical thresholds', () {
      final mobile = _read('lib/risk_engine.dart');
      final web = _read('web_dashboard/riskEngine.js');

      for (final token in [
        '>= 160',
        '>= 110',
        '>= 140',
        '>= 90',
        '>= 126',
        '>= 200',
        '>= 95',
        '>= 4',
      ]) {
        expect(mobile, contains(token), reason: 'Mobile missing $token');
        expect(web, contains(token), reason: 'Web missing $token');
      }

      for (final risk in ['LOW', 'MEDIUM', 'HIGH']) {
        expect(mobile, contains(risk));
        expect(web, contains(risk));
      }
    });

    test('mobile and web nutrition engines keep core nutrient targets', () {
      final mobile = _read('lib/nutrition_engine.dart');
      final web = _read('web_dashboard/nutritionEngine.js');

      for (final nutrient in [
        'Protein',
        'Demir',
        'Kalsiyum',
        'Omega-3',
        'Folik asit',
        'C vitamini',
        'B12 vitamini',
        'D vitamini',
        'Magnezyum',
        'Çinko',
      ]) {
        expect(mobile, contains(nutrient), reason: 'Mobile missing $nutrient');
        expect(web, contains(nutrient), reason: 'Web missing $nutrient');
      }

      for (final value in [
        '75',
        '27',
        '1000',
        '1.4',
        '600',
        '85',
        '2.6',
        '15',
        '350',
        '11',
      ]) {
        expect(mobile, contains(value), reason: 'Mobile missing target $value');
        expect(web, contains(value), reason: 'Web missing target $value');
      }
    });

    test('mobile and web nutrition engines keep upper-limit coverage aligned', () {
      final mobile = _read('lib/nutrition_engine.dart');
      final web = _read('web_dashboard/nutritionEngine.js');

      final maxLimits = {
        'Demir': '45',
        'Folik asit': '1000',
        'Kalsiyum': '2500',
        'C vitamini': '2000',
        'D vitamini': '100',
        'Magnezyum': '350',
        'Çinko': '40',
      };

      for (final entry in maxLimits.entries) {
        expect(mobile, contains(entry.key), reason: 'Mobile missing max key');
        expect(web, contains(entry.key), reason: 'Web missing max key');
        expect(mobile, contains(entry.value), reason: 'Mobile missing max');
        expect(web, contains(entry.value), reason: 'Web missing max');
      }

      for (final nutrient in ['Protein', 'Omega-3', 'B12 vitamini']) {
        expect(mobile, contains('noEstablishedUpperLimit'));
        expect(web, contains('noEstablishedUpperLimit'));
        expect(mobile, contains(nutrient));
        expect(web, contains(nutrient));
      }
    });

    test('mobile and web food unit conversion values stay aligned', () {
      final mobile = _read('lib/food_units.dart');
      final web = _read('web_dashboard/foodUnits.js');

      final expectedUnits = {
        'tane': 50,
        'piece': 50,
        'tabak': 250,
        'plate': 250,
        'bardak': 200,
        'glass': 200,
        'fincan': 100,
        'cup': 100,
        'gram': 1,
        'g': 1,
        'ml': 1,
        'scoop': 30,
      };

      for (final entry in expectedUnits.entries) {
        expect(
          _containsKeyValue(mobile, entry.key, entry.value),
          isTrue,
          reason: 'Mobile unit mismatch for ${entry.key}',
        );
        expect(
          _containsKeyValue(web, entry.key, entry.value),
          isTrue,
          reason: 'Web unit mismatch for ${entry.key}',
        );
      }
    });

    test('mobile and web weekly notification logic use trimester boundaries', () {
      final mobile = _read('lib/shared/weekly_notification_message.dart');
      final web = _read('web_dashboard/pregnant.js');

      for (final boundary in ['13', '27', '28', '42']) {
        expect(mobile, contains(boundary), reason: 'Mobile missing $boundary');
        expect(web, contains(boundary), reason: 'Web missing $boundary');
      }

      for (final keyword in ['trimester', 'week']) {
        expect(mobile.toLowerCase(), contains(keyword));
        expect(web.toLowerCase(), contains(keyword));
      }
    });

    test('mobile and web role routing keep the same role names and dashboards', () {
      final mobile = _read('lib/shared/role_access.dart');
      final web = _read('web_dashboard/redirect.html');

      final roleToPage = {
        'pregnant': 'pregnant.html',
        'gynecologist': 'gynecologist.html',
        'dietitian': 'dietitian.html',
        'admin': 'admin.html',
      };

      for (final entry in roleToPage.entries) {
        expect(mobile, contains(entry.key), reason: 'Mobile missing role');
        expect(mobile, contains(entry.value), reason: 'Mobile missing page');
        expect(web, contains(entry.key), reason: 'Web missing role');
        expect(web, contains(entry.value), reason: 'Web missing page');
      }
    });

    test('mobile and web use the same main Firestore collection names', () {
      final mobileSources = [
        _read('lib/risk_engine.dart'),
        _read('integration_test/firebase_smoke_test.dart'),
        _read('lib/gynecologist_patient_detail_page.dart'),
      ].join('\n');
      final webSources = [
        _read('web_dashboard/app.js'),
        _read('web_dashboard/risk.js'),
        _read('web_dashboard/nutrition.js'),
        _read('web_dashboard/create_diet.js'),
        _read('web_dashboard/patient_detail.js'),
        _read('web_dashboard/messages_gynecologist.js'),
      ].join('\n');

      for (final collection in [
        'users',
        'risk_olcumleri',
        'besin_analizleri',
        'notification',
        'expert_requests',
        'diet_plans',
        'chats',
        'messages',
      ]) {
        expect(
          mobileSources,
          contains(collection),
          reason: 'Mobile missing collection $collection',
        );
        expect(
          webSources,
          contains(collection),
          reason: 'Web missing collection $collection',
        );
      }
    });
  });
}

String _read(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path should exist');
  return file.readAsStringSync();
}

bool _containsKeyValue(String source, String key, num value) {
  final escapedKey = RegExp.escape(key);
  final escapedValue = RegExp.escape(value.toString());
  final pattern = RegExp('["\']?$escapedKey["\']?\\s*:\\s*$escapedValue\\b');
  return pattern.hasMatch(source);
}
