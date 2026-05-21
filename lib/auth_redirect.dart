import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_home_page.dart';
import 'diyetisyen_page.dart';
import 'hamile_page.dart';
import 'jinekolog_page.dart';
import 'l10n/app_localizations.dart';
import 'login_page.dart';
import 'shared/role_access.dart';

class AuthRedirect extends StatelessWidget {
  const AuthRedirect({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;

        if (user == null) {
          return const LoginPage();
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Scaffold(body: Center(child: Text(l10n.dataNotFound)));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final rawRole = data['role']?.toString();
            final applicationStatus =
                data['expertApplicationStatus']?.toString();

            if (rawRole == 'expert_pending' ||
                applicationStatus == 'pending') {
              return PendingExpertApplicationPage(
                requestedRole: data['requestedRole']?.toString(),
              );
            }

            final role = RoleAccess.normalizeRole(data['role']);

            switch (role) {
              case PregNovaRole.admin:
                return const AdminHomePage();
              case PregNovaRole.dietitian:
                return const DietitianHomePage();
              case PregNovaRole.gynecologist:
                return const GynecologistHomePage();
              case PregNovaRole.pregnant:
                return const HamileAnaSayfa();
            }
          },
        );
      },
    );
  }
}

class PendingExpertApplicationPage extends StatelessWidget {
  final String? requestedRole;

  const PendingExpertApplicationPage({super.key, this.requestedRole});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final roleText = requestedRole == 'gynecologist'
        ? 'Jinekolog'
        : requestedRole == 'dietitian'
            ? 'Diyetisyen'
            : 'Uzman';

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: IgnorePointer(
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 56),
                    Text(
                      '$roleText Paneli',
                      style: TextStyle(
                        color: primary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: List.generate(
                          4,
                          (index) => Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.12)),
          Center(
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hourglass_top, size: 44, color: primary),
                  const SizedBox(height: 14),
                  const Text(
                    'İsteğiniz beklemede',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$roleText başvurunuz admin tarafından onaylanınca paneliniz otomatik açılacak.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      height: 1.35,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      child: const Text('Çıkış Yap'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
