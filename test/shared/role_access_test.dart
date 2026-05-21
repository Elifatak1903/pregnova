import 'package:flutter_test/flutter_test.dart';
import 'package:pregnova/shared/role_access.dart';

void main() {
  group('RoleAccess role normalization', () {
    test('maps known roles to typed roles', () {
      expect(RoleAccess.normalizeRole('pregnant'), PregNovaRole.pregnant);
      expect(
        RoleAccess.normalizeRole('gynecologist'),
        PregNovaRole.gynecologist,
      );
      expect(RoleAccess.normalizeRole('dietitian'), PregNovaRole.dietitian);
      expect(RoleAccess.normalizeRole('admin'), PregNovaRole.admin);
    });

    test('falls back to pregnant for unknown or empty roles', () {
      expect(RoleAccess.normalizeRole(null), PregNovaRole.pregnant);
      expect(RoleAccess.normalizeRole(''), PregNovaRole.pregnant);
      expect(RoleAccess.normalizeRole('unknown'), PregNovaRole.pregnant);
    });
  });

  group('RoleAccess web panel routing', () {
    test('returns the expected dashboard page for each role', () {
      expect(RoleAccess.webHomePageForRole('pregnant'), 'pregnant.html');
      expect(RoleAccess.webHomePageForRole('gynecologist'), 'gynecologist.html');
      expect(RoleAccess.webHomePageForRole('dietitian'), 'dietitian.html');
      expect(RoleAccess.webHomePageForRole('admin'), 'admin.html');
    });
  });

  group('RoleAccess patient/client scope', () {
    test('allows a doctor to view only assigned patients', () {
      expect(
        RoleAccess.canViewDoctorPatient(
          doctorId: 'doctor-1',
          patient: {'assignedDoctor': 'doctor-1'},
        ),
        isTrue,
      );
      expect(
        RoleAccess.canViewDoctorPatient(
          doctorId: 'doctor-1',
          patient: {'assignedDoctor': 'doctor-2'},
        ),
        isFalse,
      );
      expect(
        RoleAccess.canViewDoctorPatient(doctorId: 'doctor-1', patient: null),
        isFalse,
      );
    });

    test('allows a dietitian to view only assigned clients', () {
      expect(
        RoleAccess.canViewDietitianClient(
          dietitianId: 'dietitian-1',
          client: {'assignedDietitian': 'dietitian-1'},
        ),
        isTrue,
      );
      expect(
        RoleAccess.canViewDietitianClient(
          dietitianId: 'dietitian-1',
          client: {'assignedDietitian': 'dietitian-2'},
        ),
        isFalse,
      );
      expect(
        RoleAccess.canViewDietitianClient(
          dietitianId: 'dietitian-1',
          client: null,
        ),
        isFalse,
      );
    });
  });

  group('RoleAccess admin permissions', () {
    test('only admin can manage users', () {
      expect(RoleAccess.canManageUsers('admin'), isTrue);
      expect(RoleAccess.canManageUsers('pregnant'), isFalse);
      expect(RoleAccess.canManageUsers('gynecologist'), isFalse);
      expect(RoleAccess.canManageUsers('dietitian'), isFalse);
      expect(RoleAccess.canManageUsers(null), isFalse);
    });
  });
}
