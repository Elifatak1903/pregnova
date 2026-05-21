enum PregNovaRole {
  pregnant,
  gynecologist,
  dietitian,
  admin,
}

class RoleAccess {
  const RoleAccess._();

  static PregNovaRole normalizeRole(dynamic role) {
    final value = role?.toString().trim().toLowerCase();

    switch (value) {
      case 'admin':
        return PregNovaRole.admin;
      case 'gynecologist':
        return PregNovaRole.gynecologist;
      case 'dietitian':
        return PregNovaRole.dietitian;
      case 'pregnant':
      default:
        return PregNovaRole.pregnant;
    }
  }

  static String webHomePageForRole(dynamic role) {
    switch (normalizeRole(role)) {
      case PregNovaRole.admin:
        return 'admin.html';
      case PregNovaRole.gynecologist:
        return 'gynecologist.html';
      case PregNovaRole.dietitian:
        return 'dietitian.html';
      case PregNovaRole.pregnant:
        return 'pregnant.html';
    }
  }

  static bool canViewDoctorPatient({
    required String doctorId,
    required Map<String, dynamic>? patient,
  }) {
    if (patient == null) return false;
    return patient['assignedDoctor'] == doctorId;
  }

  static bool canViewDietitianClient({
    required String dietitianId,
    required Map<String, dynamic>? client,
  }) {
    if (client == null) return false;
    return client['assignedDietitian'] == dietitianId;
  }

  static bool canManageUsers(dynamic role) {
    return normalizeRole(role) == PregNovaRole.admin;
  }
}
