import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pregnova/app_theme.dart';
import 'package:pregnova/l10n/app_localizations.dart';
import 'package:pregnova/welcome_page.dart';

void main() {
  group('Core widget rendering', () {
    testWidgets('welcome page renders English title, subtitle, icon, and CTA', (
      tester,
    ) async {
      await tester.pumpWidget(
        const _LocalizedWidgetApp(
          locale: Locale('en'),
          child: WelcomePage(),
        ),
      );

      expect(find.text('Welcome to PregNova'), findsOneWidget);
      expect(find.textContaining('Track your pregnancy journey'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.byIcon(Icons.pregnant_woman), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('welcome page renders Turkish localized title and CTA', (
      tester,
    ) async {
      await tester.pumpWidget(
        const _LocalizedWidgetApp(
          locale: Locale('tr'),
          child: WelcomePage(),
        ),
      );

      expect(find.text("PregNova'ya Hoş Geldin"), findsOneWidget);
      expect(find.textContaining('Hamilelik sürecini'), findsOneWidget);
      expect(find.text('Kullanmaya Başla'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('pregnant theme applies purple primary color to AppBar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _ThemeProbeApp(role: 'pregnant', child: const _ThemeProbeScaffold()),
      );

      final context = tester.element(find.byType(_ThemeProbeScaffold));
      final theme = Theme.of(context);

      expect(theme.colorScheme.primary, const Color(0xFF673AB7));
      expect(theme.appBarTheme.backgroundColor, const Color(0xFF673AB7));
    });

    testWidgets('dietitian theme applies green primary color to buttons', (
      tester,
    ) async {
      await tester.pumpWidget(
        _ThemeProbeApp(role: 'dietitian', child: const _ThemeProbeScaffold()),
      );

      final context = tester.element(find.byType(_ThemeProbeScaffold));
      final background = Theme.of(
        context,
      ).elevatedButtonTheme.style?.backgroundColor?.resolve({});

      expect(background, const Color(0xFF2E7D32));
    });

    testWidgets('admin theme keeps readable foreground color on primary areas', (
      tester,
    ) async {
      await tester.pumpWidget(
        _ThemeProbeApp(role: 'admin', child: const _ThemeProbeScaffold()),
      );

      final context = tester.element(find.byType(_ThemeProbeScaffold));
      final colors = Theme.of(context).colorScheme;

      expect(colors.primary, const Color(0xFF1565C0));
      expect(colors.onPrimary, Colors.white);
    });
  });
}

class _LocalizedWidgetApp extends StatelessWidget {
  const _LocalizedWidgetApp({
    required this.locale,
    required this.child,
  });

  final Locale locale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      theme: AppTheme.getTheme('pregnant'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }
}

class _ThemeProbeApp extends StatelessWidget {
  const _ThemeProbeApp({
    required this.role,
    required this.child,
  });

  final String role;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.getTheme(role),
      home: child,
    );
  }
}

class _ThemeProbeScaffold extends StatelessWidget {
  const _ThemeProbeScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Probe')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {},
          child: const Text('Action'),
        ),
      ),
    );
  }
}
