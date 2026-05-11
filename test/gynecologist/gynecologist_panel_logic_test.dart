import 'package:flutter_test/flutter_test.dart';
import 'package:pregnova/gynecologist/gynecologist_panel_logic.dart';

void main() {
  group('GynecologistPanelLogic request counts', () {
    final requests = [
      {'expertId': 'doctor-1', 'clientId': 'patient-1', 'status': 'approved'},
      {'expertId': 'doctor-1', 'clientId': 'patient-2', 'status': 'pending'},
      {'expertId': 'doctor-2', 'clientId': 'patient-3', 'status': 'approved'},
      null,
    ];

    test('counts requests by doctor and status', () {
      expect(
        GynecologistPanelLogic.countRequestsForStatus(
          requests,
          doctorId: 'doctor-1',
          status: 'approved',
        ),
        1,
      );
      expect(
        GynecologistPanelLogic.countRequestsForStatus(
          requests,
          doctorId: 'doctor-1',
          status: 'pending',
        ),
        1,
      );
    });

    test('extracts only approved patient ids for doctor', () {
      expect(
        GynecologistPanelLogic.approvedPatientIdsForDoctor(
          requests,
          doctorId: 'doctor-1',
        ),
        {'patient-1'},
      );
    });
  });

  group('GynecologistPanelLogic risk counters', () {
    final approvedPatientIds = {'patient-1', 'patient-2'};

    test('counts high-risk patients only from approved patient scope', () {
      final count = GynecologistPanelLogic.highRiskPatientCount(
        approvedPatientIds: approvedPatientIds,
        measurements: [
          {'uid': 'patient-1', 'preeklampsiRisk': 'HIGH'},
          {'uid': 'patient-1', 'diyabetRisk': 'HIGH'},
          {'uid': 'patient-2', 'pretermRisk': 'LOW'},
          {'uid': 'patient-3', 'pretermRisk': 'HIGH'},
          {'uid': null, 'preeklampsiRisk': 'HIGH'},
        ],
      );

      expect(count, 1);
    });

    test('normalizes lowercase high-risk labels', () {
      final count = GynecologistPanelLogic.highRiskPatientCount(
        approvedPatientIds: approvedPatientIds,
        measurements: [
          {'uid': 'patient-2', 'diyabetRisk': 'high'},
        ],
      );

      expect(count, 1);
    });

    test('counts active patients in the last 7 days only once', () {
      final count = GynecologistPanelLogic.activePatientCountLast7Days(
        approvedPatientIds: approvedPatientIds,
        now: DateTime(2026, 5, 11),
        measurements: [
          {'uid': 'patient-1', 'tarih': DateTime(2026, 5, 11)},
          {'uid': 'patient-1', 'tarih': DateTime(2026, 5, 10)},
          {'uid': 'patient-2', 'tarih': DateTime(2026, 5, 4)},
          {'uid': 'patient-2', 'tarih': DateTime(2026, 5, 3)},
          {'uid': 'patient-3', 'tarih': DateTime(2026, 5, 11)},
          {'uid': 'patient-2', 'tarih': null},
        ],
      );

      expect(count, 2);
    });
  });

  group('GynecologistPanelLogic risk distribution', () {
    test('groups only patients assigned to the doctor', () {
      final distribution = GynecologistPanelLogic.riskDistributionForDoctor(
        [
          {'assignedDoctor': 'doctor-1', 'riskLevel': 'normal'},
          {'assignedDoctor': 'doctor-1', 'riskLevel': 'medium'},
          {'assignedDoctor': 'doctor-1', 'riskLevel': 'HIGH'},
          {'assignedDoctor': 'doctor-2', 'riskLevel': 'high'},
          {'assignedDoctor': 'doctor-1', 'riskLevel': 'unknown'},
        ],
        doctorId: 'doctor-1',
      );

      expect(distribution, {'normal': 1, 'medium': 1, 'high': 1});
    });
  });

  group('GynecologistPanelLogic recent measurements', () {
    test('filters to approved patients, sorts newest first, and applies limit', () {
      final recent = GynecologistPanelLogic.recentMeasurementsForDoctor(
        approvedPatientIds: {'patient-1', 'patient-2'},
        limit: 2,
        measurements: [
          {'uid': 'patient-1', 'tarih': DateTime(2026, 5, 9), 'id': 'old'},
          {'uid': 'patient-2', 'tarih': DateTime(2026, 5, 11), 'id': 'new'},
          {'uid': 'patient-3', 'tarih': DateTime(2026, 5, 12), 'id': 'other'},
          {'uid': 'patient-1', 'tarih': DateTime(2026, 5, 10), 'id': 'mid'},
        ],
      );

      expect(recent.map((item) => item['id']), ['new', 'mid']);
    });
  });
}
