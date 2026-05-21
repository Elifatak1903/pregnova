import 'package:flutter_test/flutter_test.dart';
import 'package:pregnova/shared/firestore_data_validator.dart';

void main() {
  group('FirestoreDataValidator users', () {
    test('accepts valid role and optional assignments', () {
      expect(
        FirestoreDataValidator.isValidUser({
          'role': 'pregnant',
          'email': 'patient@example.com',
          'assignedDoctor': 'doctor-1',
          'assignedDietitian': 'dietitian-1',
          'riskLevel': 'medium',
        }),
        isTrue,
      );
    });

    test('rejects missing or unknown roles', () {
      expect(FirestoreDataValidator.isValidUser({}), isFalse);
      expect(
        FirestoreDataValidator.isValidUser({'role': 'unknown'}),
        isFalse,
      );
    });
  });

  group('FirestoreDataValidator risk measurements', () {
    test('accepts valid measurement schema', () {
      expect(
        FirestoreDataValidator.isValidRiskMeasurement({
          'uid': 'patient-1',
          'tarih': DateTime(2026, 5, 20),
          'sistolik': 140,
          'diastolik': 90,
          'preeklampsiRisk': 'MEDIUM',
          'diyabetRisk': 'LOW',
          'pretermRisk': 'HIGH',
        }),
        isTrue,
      );
    });

    test('rejects missing uid, invalid date, or invalid risk labels', () {
      expect(
        FirestoreDataValidator.isValidRiskMeasurement({
          'uid': '',
          'tarih': DateTime(2026, 5, 20),
          'sistolik': 140,
          'diastolik': 90,
          'preeklampsiRisk': 'MEDIUM',
          'diyabetRisk': 'LOW',
          'pretermRisk': 'HIGH',
        }),
        isFalse,
      );

      expect(
        FirestoreDataValidator.isValidRiskMeasurement({
          'uid': 'patient-1',
          'tarih': null,
          'sistolik': 140,
          'diastolik': 90,
          'preeklampsiRisk': 'UNKNOWN',
          'diyabetRisk': 'LOW',
          'pretermRisk': 'HIGH',
        }),
        isFalse,
      );
    });
  });

  group('FirestoreDataValidator nutrition analyses', () {
    test('accepts daily total and food list structure', () {
      expect(
        FirestoreDataValidator.isValidNutritionAnalysis({
          'uid': 'patient-1',
          'createdAt': DateTime(2026, 5, 20),
          'besinler': [
            {'ad': 'yogurt', 'miktar': 1},
          ],
          'toplam': {'kalori': 260},
        }),
        isTrue,
      );
    });

    test('rejects empty food list or missing total calories', () {
      expect(
        FirestoreDataValidator.isValidNutritionAnalysis({
          'uid': 'patient-1',
          'createdAt': DateTime(2026, 5, 20),
          'besinler': [],
          'toplam': {'kalori': 260},
        }),
        isFalse,
      );

      expect(
        FirestoreDataValidator.isValidNutritionAnalysis({
          'uid': 'patient-1',
          'createdAt': DateTime(2026, 5, 20),
          'besinler': [
            {'ad': 'yogurt'},
          ],
          'toplam': {},
        }),
        isFalse,
      );
    });
  });

  group('FirestoreDataValidator notifications', () {
    test('accepts valid notification schema', () {
      expect(
        FirestoreDataValidator.isValidNotification({
          'uid': 'patient-1',
          'title': 'Risk Warning',
          'message': 'Risk measurement needs review',
          'type': 'risk_alert',
          'isRead': false,
          'createdAt': DateTime(2026, 5, 20),
        }),
        isTrue,
      );
    });

    test('rejects notification without receiver or boolean read state', () {
      expect(
        FirestoreDataValidator.isValidNotification({
          'uid': '',
          'title': 'Risk Warning',
          'message': 'Risk measurement needs review',
          'type': 'risk_alert',
          'isRead': false,
          'createdAt': DateTime(2026, 5, 20),
        }),
        isFalse,
      );

      expect(
        FirestoreDataValidator.isValidNotification({
          'uid': 'patient-1',
          'title': 'Risk Warning',
          'message': 'Risk measurement needs review',
          'type': 'risk_alert',
          'isRead': 'false',
          'createdAt': DateTime(2026, 5, 20),
        }),
        isFalse,
      );
    });
  });

  group('FirestoreDataValidator expert requests', () {
    test('accepts pending, approved, rejected, and removed statuses', () {
      for (final status in ['pending', 'approved', 'rejected', 'removed']) {
        expect(
          FirestoreDataValidator.isValidExpertRequest({
            'clientId': 'patient-1',
            'expertId': 'expert-1',
            'status': status,
            'createdAt': DateTime(2026, 5, 20),
          }),
          isTrue,
        );
      }
    });

    test('rejects missing expert/client ids or unknown statuses', () {
      expect(
        FirestoreDataValidator.isValidExpertRequest({
          'clientId': 'patient-1',
          'expertId': '',
          'status': 'pending',
        }),
        isFalse,
      );

      expect(
        FirestoreDataValidator.isValidExpertRequest({
          'clientId': 'patient-1',
          'expertId': 'expert-1',
          'status': 'archived',
        }),
        isFalse,
      );
    });
  });

  group('FirestoreDataValidator diet plans', () {
    test('accepts valid diet plan meal fields', () {
      expect(
        FirestoreDataValidator.isValidDietPlan({
          'clientId': 'patient-1',
          'dietitianId': 'dietitian-1',
          'kahvalti': 'sut',
          'ogle': 'sebze',
          'aksam': 'pilav',
          'createdAt': DateTime(2026, 5, 20),
        }),
        isTrue,
      );
    });

    test('rejects diet plan without owner or required meals', () {
      expect(
        FirestoreDataValidator.isValidDietPlan({
          'clientId': 'patient-1',
          'dietitianId': 'dietitian-1',
          'kahvalti': 'sut',
          'ogle': '',
          'aksam': 'pilav',
        }),
        isFalse,
      );
    });
  });

  group('FirestoreDataValidator chats', () {
    test('accepts chat documents with at least two users', () {
      expect(
        FirestoreDataValidator.isValidChat({
          'users': ['patient-1', 'doctor-1'],
          'lastMessage': 'Hello',
          'lastMessageTime': DateTime(2026, 5, 20),
        }),
        isTrue,
      );
    });

    test('rejects chats with missing users or non-string last message', () {
      expect(
        FirestoreDataValidator.isValidChat({
          'users': ['patient-1'],
          'lastMessage': 'Hello',
        }),
        isFalse,
      );

      expect(
        FirestoreDataValidator.isValidChat({
          'users': ['patient-1', 'doctor-1'],
          'lastMessage': null,
        }),
        isFalse,
      );
    });
  });
}
