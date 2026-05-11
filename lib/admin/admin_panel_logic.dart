class AdminPanelLogic {
  const AdminPanelLogic._();

  static AdminDashboardStats dashboardStats({
    required Iterable<Map<String, dynamic>?> users,
    required Iterable<Map<String, dynamic>?> applications,
  }) {
    final userList = users.whereType<Map<String, dynamic>>().toList();
    final appList = applications.whereType<Map<String, dynamic>>().toList();

    final activeExperts = userList.where((user) {
      final role = user['role'];
      return (role == 'dietitian' || role == 'gynecologist') &&
          user['isApproved'] == true;
    }).length;

    final pendingApplications = appList.where((app) {
      return (app['status'] ?? 'pending') == 'pending';
    }).length;

    return AdminDashboardStats(
      totalUsers: userList.length,
      activeExperts: activeExperts,
      pendingApplications: pendingApplications,
    );
  }

  static List<Map<String, dynamic>> filterApplications({
    required Iterable<Map<String, dynamic>?> applications,
    required String statusFilter,
    required String roleFilter,
  }) {
    return applications.whereType<Map<String, dynamic>>().where((app) {
      final status = (app['status'] ?? 'pending').toString();
      if (status != statusFilter) return false;
      if (roleFilter != 'all' && app['role'] != roleFilter) return false;
      return true;
    }).toList();
  }

  static Map<String, dynamic> buildApprovedUserUpdate(
    Map<String, dynamic> application,
  ) {
    return {
      'role': application['role'],
      'diplomaUrl': application['documentUrl'] ?? application['diplomaUrl'],
      'isApproved': true,
    };
  }

  static Map<String, dynamic> buildApplicationStatusUpdate(String status) {
    return {'status': status};
  }

  static Map<String, dynamic> buildApprovalNotificationPayload({
    required String uid,
    required String title,
    required String message,
  }) {
    return {
      'uid': uid,
      'title': title,
      'message': message,
      'isRead': false,
    };
  }

  static List<Map<String, dynamic>> filterUsers({
    required Iterable<Map<String, dynamic>?> users,
    required String roleFilter,
    required String searchText,
  }) {
    final query = searchText.trim().toLowerCase();

    return users.whereType<Map<String, dynamic>>().where((user) {
      if (roleFilter != 'all' && user['role'] != roleFilter) return false;
      if (query.isEmpty) return true;

      final name = (user['name'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();

      return name.contains(query) || email.contains(query);
    }).toList();
  }

  static AdminSystemReport systemReport({
    required Iterable<Map<String, dynamic>?> users,
    required Iterable<Map<String, dynamic>?> risks,
    required Iterable<Map<String, dynamic>?> nutritionAnalyses,
    required Iterable<Map<String, dynamic>?> applications,
  }) {
    var pregnant = 0;
    var doctors = 0;
    var dietitians = 0;
    var pendingApplications = 0;
    var approvedApplications = 0;
    var rejectedApplications = 0;
    var high = 0;
    var medium = 0;
    var low = 0;

    final userList = users.whereType<Map<String, dynamic>>().toList();
    final riskList = risks.whereType<Map<String, dynamic>>().toList();
    final nutritionList = nutritionAnalyses
        .whereType<Map<String, dynamic>>()
        .toList();

    for (final user in userList) {
      switch (user['role']) {
        case 'pregnant':
          pregnant++;
          break;
        case 'gynecologist':
          doctors++;
          break;
        case 'dietitian':
          dietitians++;
          break;
      }
    }

    for (final app in applications.whereType<Map<String, dynamic>>()) {
      switch ((app['status'] ?? 'pending').toString()) {
        case 'approved':
          approvedApplications++;
          break;
        case 'rejected':
          rejectedApplications++;
          break;
        default:
          pendingApplications++;
      }
    }

    for (final risk in riskList) {
      final level = (risk['riskLevel'] ?? risk['overallRisk'] ?? '')
          .toString()
          .toLowerCase();
      switch (level) {
        case 'high':
          high++;
          break;
        case 'medium':
          medium++;
          break;
        case 'low':
        case 'normal':
          low++;
          break;
      }
    }

    final totalRiskLevels = high + medium + low;
    final highPercent = totalRiskLevels == 0
        ? 0
        : ((high / totalRiskLevels) * 100).round();

    return AdminSystemReport(
      totalUsers: userList.length,
      pregnant: pregnant,
      doctors: doctors,
      dietitians: dietitians,
      riskMeasurements: riskList.length,
      nutritionAnalyses: nutritionList.length,
      pendingApplications: pendingApplications,
      approvedApplications: approvedApplications,
      rejectedApplications: rejectedApplications,
      high: high,
      medium: medium,
      low: low,
      highPercent: highPercent,
    );
  }
}

class AdminDashboardStats {
  final int totalUsers;
  final int activeExperts;
  final int pendingApplications;

  const AdminDashboardStats({
    required this.totalUsers,
    required this.activeExperts,
    required this.pendingApplications,
  });
}

class AdminSystemReport {
  final int totalUsers;
  final int pregnant;
  final int doctors;
  final int dietitians;
  final int riskMeasurements;
  final int nutritionAnalyses;
  final int pendingApplications;
  final int approvedApplications;
  final int rejectedApplications;
  final int high;
  final int medium;
  final int low;
  final int highPercent;

  const AdminSystemReport({
    required this.totalUsers,
    required this.pregnant,
    required this.doctors,
    required this.dietitians,
    required this.riskMeasurements,
    required this.nutritionAnalyses,
    required this.pendingApplications,
    required this.approvedApplications,
    required this.rejectedApplications,
    required this.high,
    required this.medium,
    required this.low,
    required this.highPercent,
  });
}
