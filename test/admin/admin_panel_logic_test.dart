import 'package:flutter_test/flutter_test.dart';
import 'package:pregnova/admin/admin_panel_logic.dart';

void main() {
  group('AdminPanelLogic dashboard stats', () {
    test('counts total users, active approved experts, and pending apps', () {
      final stats = AdminPanelLogic.dashboardStats(
        users: [
          {'role': 'pregnant'},
          {'role': 'dietitian', 'isApproved': true},
          {'role': 'gynecologist', 'isApproved': true},
          {'role': 'gynecologist', 'isApproved': false},
          {'role': 'admin', 'isApproved': true},
        ],
        applications: [
          {'status': 'pending'},
          {'status': 'approved'},
          {'status': null},
        ],
      );

      expect(stats.totalUsers, 5);
      expect(stats.activeExperts, 2);
      expect(stats.pendingApplications, 2);
    });
  });

  group('AdminPanelLogic expert applications', () {
    final applications = [
      {'uid': 'u1', 'role': 'dietitian', 'status': 'pending'},
      {'uid': 'u2', 'role': 'gynecologist', 'status': 'pending'},
      {'uid': 'u3', 'role': 'dietitian', 'status': 'approved'},
      {'uid': 'u4', 'role': 'gynecologist', 'status': 'rejected'},
      null,
    ];

    test('filters applications by status and role', () {
      final pendingDietitians = AdminPanelLogic.filterApplications(
        applications: applications,
        statusFilter: 'pending',
        roleFilter: 'dietitian',
      );

      expect(pendingDietitians.map((app) => app['uid']), ['u1']);
    });

    test('supports all role filter', () {
      final pending = AdminPanelLogic.filterApplications(
        applications: applications,
        statusFilter: 'pending',
        roleFilter: 'all',
      );

      expect(pending.length, 2);
    });

    test('builds approved user update with diploma fallback', () {
      final update = AdminPanelLogic.buildApprovedUserUpdate({
        'role': 'gynecologist',
        'documentUrl': null,
        'diplomaUrl': 'storage://diploma.pdf',
      });

      expect(update['role'], 'gynecologist');
      expect(update['diplomaUrl'], 'storage://diploma.pdf');
      expect(update['isApproved'], isTrue);
    });

    test('builds application status and notification payloads', () {
      expect(
        AdminPanelLogic.buildApplicationStatusUpdate('approved'),
        {'status': 'approved'},
      );

      final notification = AdminPanelLogic.buildApprovalNotificationPayload(
        uid: 'expert-1',
        title: 'Approved',
        message: 'Application approved',
      );

      expect(notification['uid'], 'expert-1');
      expect(notification['isRead'], isFalse);
      expect(notification['title'], 'Approved');
    });
  });

  group('AdminPanelLogic user management', () {
    final users = [
      {'name': 'Merve Seccan', 'email': 'merve@example.com', 'role': 'pregnant'},
      {'name': 'Elif Atak', 'email': 'elif@example.com', 'role': 'dietitian'},
      {'name': 'Ayse Doktor', 'email': 'ayse@example.com', 'role': 'gynecologist'},
    ];

    test('filters users by role', () {
      final filtered = AdminPanelLogic.filterUsers(
        users: users,
        roleFilter: 'dietitian',
        searchText: '',
      );

      expect(filtered.map((user) => user['name']), ['Elif Atak']);
    });

    test('filters users by name or email search text', () {
      final byName = AdminPanelLogic.filterUsers(
        users: users,
        roleFilter: 'all',
        searchText: 'merve',
      );
      final byEmail = AdminPanelLogic.filterUsers(
        users: users,
        roleFilter: 'all',
        searchText: 'ayse@example',
      );

      expect(byName.single['role'], 'pregnant');
      expect(byEmail.single['role'], 'gynecologist');
    });
  });

  group('AdminPanelLogic system report', () {
    test('builds role, application, risk, and analysis counts', () {
      final report = AdminPanelLogic.systemReport(
        users: [
          {'role': 'pregnant'},
          {'role': 'pregnant'},
          {'role': 'gynecologist'},
          {'role': 'dietitian'},
          {'role': 'admin'},
        ],
        risks: [
          {'riskLevel': 'high'},
          {'riskLevel': 'medium'},
          {'riskLevel': 'normal'},
          {'overallRisk': 'HIGH'},
          {'riskLevel': 'unknown'},
        ],
        nutritionAnalyses: [
          {'uid': 'u1'},
          {'uid': 'u2'},
        ],
        applications: [
          {'status': 'approved'},
          {'status': 'rejected'},
          {'status': 'pending'},
          {'status': null},
        ],
      );

      expect(report.totalUsers, 5);
      expect(report.pregnant, 2);
      expect(report.doctors, 1);
      expect(report.dietitians, 1);
      expect(report.riskMeasurements, 5);
      expect(report.nutritionAnalyses, 2);
      expect(report.approvedApplications, 1);
      expect(report.rejectedApplications, 1);
      expect(report.pendingApplications, 2);
      expect(report.high, 2);
      expect(report.medium, 1);
      expect(report.low, 1);
      expect(report.highPercent, 50);
    });

    test('returns zero high-risk percent when there are no risk levels', () {
      final report = AdminPanelLogic.systemReport(
        users: [],
        risks: [],
        nutritionAnalyses: [],
        applications: [],
      );

      expect(report.highPercent, 0);
    });
  });
}
