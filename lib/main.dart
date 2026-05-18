import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_theme.dart';
import 'auth_redirect.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'locale_controller.dart';
import 'welcome_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('tr_TR', null);
  await initializeDateFormatting('en_US', null);
  await localeController.load();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const RoleLoaderPage());
}

class MyApp extends StatelessWidget {
  final String role;
  final bool isAuthenticated;

  const MyApp({super.key, required this.role, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localeController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: localeController.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          localeResolutionCallback: _resolveLocale,
          theme: AppTheme.getTheme(role),
          home: isAuthenticated ? const AuthRedirect() : const WelcomePage(),
        );
      },
    );
  }
}

class RoleLoaderPage extends StatefulWidget {
  const RoleLoaderPage({super.key});

  @override
  State<RoleLoaderPage> createState() => _RoleLoaderPageState();
}

class _RoleLoaderPageState extends State<RoleLoaderPage> {
  String? role;
  bool isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    loadRole();
  }

  Future<void> loadRole() async {
    await Future.delayed(const Duration(milliseconds: 200));

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        role = "pregnant";
        isAuthenticated = false;
      });
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final data = doc.data();

    setState(() {
      role = data?["role"] ?? "pregnant";
      isAuthenticated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (role == null) {
      return AnimatedBuilder(
        animation: localeController,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: localeController.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            localeResolutionCallback: _resolveLocale,
            theme: AppTheme.getTheme("pregnant"),
            home: const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Colors.deepPurple),
              ),
            ),
          );
        },
      );
    }

    return MyApp(role: role!, isAuthenticated: isAuthenticated);
  }
}

Locale _resolveLocale(Locale? locale, Iterable<Locale> supportedLocales) {
  if (locale == null) return const Locale('tr');

  for (final supportedLocale in supportedLocales) {
    if (supportedLocale.languageCode == locale.languageCode) {
      return supportedLocale;
    }
  }

  return const Locale('tr');
}
