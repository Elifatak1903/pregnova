import 'package:flutter_test/flutter_test.dart';
import 'package:pregnova/dietitian/dietitian_panel_logic.dart';

void main() {
  group('DietitianPanelLogic request counts', () {
    final requests = [
      {'expertId': 'dietitian-1', 'clientId': 'client-1', 'status': 'approved'},
      {'expertId': 'dietitian-1', 'clientId': 'client-2', 'status': 'pending'},
      {'expertId': 'dietitian-2', 'clientId': 'client-3', 'status': 'approved'},
      null,
    ];

    test('counts requests by dietitian and status', () {
      expect(
        DietitianPanelLogic.countRequestsForStatus(
          requests,
          dietitianId: 'dietitian-1',
          status: 'approved',
        ),
        1,
      );
      expect(
        DietitianPanelLogic.countRequestsForStatus(
          requests,
          dietitianId: 'dietitian-1',
          status: 'pending',
        ),
        1,
      );
    });

    test('extracts approved client ids for dietitian', () {
      expect(
        DietitianPanelLogic.approvedClientIdsForDietitian(
          requests,
          dietitianId: 'dietitian-1',
        ),
        {'client-1'},
      );
    });
  });

  group('DietitianPanelLogic activity and recent analyses', () {
    final analyses = [
      {
        'id': 'a1',
        'uid': 'client-1',
        'dietitianId': 'dietitian-1',
        'createdAt': DateTime(2026, 5, 11, 10),
      },
      {
        'id': 'a2',
        'uid': 'client-2',
        'dietitianId': 'dietitian-1',
        'createdAt': DateTime(2026, 5, 5, 9),
      },
      {
        'id': 'a3',
        'uid': 'client-3',
        'dietitianId': 'dietitian-2',
        'createdAt': DateTime(2026, 5, 11, 12),
      },
      {
        'id': 'a4',
        'uid': 'client-1',
        'dietitianId': 'dietitian-1',
        'createdAt': DateTime(2026, 5, 3, 9),
      },
      null,
    ];

    test('counts last 7 day analyses only for selected dietitian', () {
      final count = DietitianPanelLogic.activeAnalysisCountLast7Days(
        analyses: analyses,
        dietitianId: 'dietitian-1',
        now: DateTime(2026, 5, 11, 23, 59),
      );

      expect(count, 2);
    });

    test('sorts recent analyses newest first and applies limit', () {
      final recent = DietitianPanelLogic.recentAnalysesForDietitian(
        analyses: analyses,
        dietitianId: 'dietitian-1',
        limit: 2,
      );

      expect(recent.map((item) => item['id']), ['a1', 'a2']);
    });
  });

  group('DietitianPanelLogic daily analysis grouping', () {
    test('groups same-day analyses and calculates daily total calories', () {
      final groups = DietitianPanelLogic.groupAnalysesByDay([
        {
          'id': 'first',
          'createdAt': DateTime(2026, 5, 11, 8),
          'kalori': 250,
        },
        {
          'id': 'second',
          'createdAt': DateTime(2026, 5, 11, 18),
          'kalori': '350',
        },
        {
          'id': 'old',
          'createdAt': DateTime(2026, 5, 10, 12),
          'kalori': -100,
        },
        {
          'id': 'invalid',
          'createdAt': null,
          'kalori': 999,
        },
      ]);

      expect(groups.length, 2);
      expect(groups.first.day, DateTime(2026, 5, 11));
      expect(groups.first.analyses.map((item) => item['id']), [
        'first',
        'second',
      ]);
      expect(groups.first.totalCalories, 600);
      expect(groups.last.totalCalories, 0);
    });
  });

  group('DietitianPanelLogic diet plan payload', () {
    test('trims diet plan fields before saving payload', () {
      final payload = DietitianPanelLogic.buildDietPlanPayload(
        clientId: ' client-1 ',
        dietitianId: ' dietitian-1 ',
        breakfast: ' yumurta ',
        snack1: ' meyve ',
        lunch: ' tavuk ',
        snack2: ' yogurt ',
        dinner: ' balik ',
        night: ' sut ',
        notes: ' bol su ',
      );

      expect(payload['clientId'], 'client-1');
      expect(payload['dietitianId'], 'dietitian-1');
      expect(payload['kahvalti'], 'yumurta');
      expect(payload['notlar'], 'bol su');
    });
  });
}
