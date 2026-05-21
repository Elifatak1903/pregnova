import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pregnova/l10n/app_localizations.dart';
import 'package:pregnova/language_selector.dart';
import 'package:pregnova/locale_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await localeController.useSystemLocale();
  });

  group('LanguageActionButton widget', () {
    testWidgets('renders Turkish localized text and language tooltip', (
      tester,
    ) async {
      await localeController.setLocale(const Locale('tr'));
      await tester.pumpWidget(const _LocalizedTestApp());

      expect(find.text('Ana Sayfa'), findsOneWidget);
      expect(find.byTooltip('Dil'), findsOneWidget);
    });

    testWidgets('renders English localized text and language tooltip', (
      tester,
    ) async {
      await localeController.setLocale(const Locale('en'));
      await tester.pumpWidget(const _LocalizedTestApp());

      expect(find.text('Home'), findsOneWidget);
      expect(find.byTooltip('Language'), findsOneWidget);
    });

    testWidgets('opens language dialog with all language options', (
      tester,
    ) async {
      await localeController.setLocale(const Locale('tr'));
      await tester.pumpWidget(const _LocalizedTestApp());

      await tester.tap(find.byTooltip('Dil'));
      await tester.pumpAndSettle();

      expect(find.text('Dil Seç'), findsOneWidget);
      expect(find.text('Sistem dili'), findsOneWidget);
      expect(find.text('Türkçe'), findsOneWidget);
      expect(find.text('İngilizce'), findsOneWidget);
    });

    testWidgets('updates app text after selecting English', (tester) async {
      await localeController.setLocale(const Locale('tr'));
      await tester.pumpWidget(const _LocalizedTestApp());

      await tester.tap(find.byTooltip('Dil'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('İngilizce'));
      await tester.pumpAndSettle();

      expect(localeController.locale, const Locale('en'));
      expect(find.text('Home'), findsOneWidget);
      expect(find.byTooltip('Language'), findsOneWidget);
    });

    testWidgets('can switch from English back to Turkish', (tester) async {
      await localeController.setLocale(const Locale('en'));
      await tester.pumpWidget(const _LocalizedTestApp());

      await tester.tap(find.byTooltip('Language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Turkish'));
      await tester.pumpAndSettle();

      expect(localeController.locale, const Locale('tr'));
      expect(find.text('Ana Sayfa'), findsOneWidget);
      expect(find.byTooltip('Dil'), findsOneWidget);
    });
  });
}

class _LocalizedTestApp extends StatelessWidget {
  const _LocalizedTestApp();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localeController,
      builder: (context, _) {
        return MaterialApp(
          locale: localeController.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const _LocalizedHome(),
        );
      },
    );
  }
}

class _LocalizedHome extends StatelessWidget {
  const _LocalizedHome();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(actions: const [LanguageActionButton()]),
      body: Center(child: Text(l10n.home)),
    );
  }
}
