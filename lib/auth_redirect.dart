import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'hamile_page.dart';
import 'admin_home_page.dart';
import 'diyetisyen_page.dart';
import 'jinekolog_page.dart';
import 'login_page.dart';

class AuthRedirect extends StatelessWidget {
  const AuthRedirect({super.key});

  @override
  Widget build(BuildContext context) {
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

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, snapshot) {

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Scaffold(
                body: Center(child: Text("Kullanıcı verisi bulunamadı")),
              );
            }

            final data =
            snapshot.data!.data() as Map<String, dynamic>;
            final role = data['role'];

            switch (role) {

              case 'admin':
                return const AdminHomePage();

              case 'dietitian':
                return const DietitianHomePage();

              case 'gynecologist':
                return const GynecologistHomePage();

              case 'pregnant':
              default:
                return const HamileAnaSayfa();
            }
          },
        );
      },
    );
  }
}
