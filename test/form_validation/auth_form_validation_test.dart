import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pregnova/l10n/app_localizations.dart';
import 'package:pregnova/login_page.dart';
import 'package:pregnova/register_page.dart';

void main() {
  group('Auth form validation', () {
    testWidgets('login shows validation message when fields are empty', (
      tester,
    ) async {
      await tester.pumpWidget(const _LocalizedTestApp(child: LoginPage()));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Please fill in all fields'), findsOneWidget);
    });

    testWidgets('register shows validation message when fields are empty', (
      tester,
    ) async {
      await tester.pumpWidget(const _LocalizedTestApp(child: RegisterPage()));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
      await tester.pumpAndSettle();

      expect(find.text('Please fill in all fields'), findsOneWidget);
    });

    testWidgets('register rejects passwords shorter than six characters', (
      tester,
    ) async {
      await tester.pumpWidget(const _LocalizedTestApp(child: RegisterPage()));

      await tester.enterText(find.widgetWithText(TextField, 'Full Name'), 'Ada');
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'ada@example.com',
      );
      await tester.enterText(find.widgetWithText(TextField, 'Password'), '123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
    });
  });
}

class _LocalizedTestApp extends StatelessWidget {
  const _LocalizedTestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }
}
