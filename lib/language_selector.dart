import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'locale_controller.dart';

class LanguageActionButton extends StatelessWidget {
  const LanguageActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return IconButton(
      tooltip: l10n.language,
      icon: const Icon(Icons.language),
      onPressed: () => showLanguageDialog(context),
    );
  }
}

Future<void> showLanguageDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AnimatedBuilder(
        animation: localeController,
        builder: (context, _) {
          final l10n = AppLocalizations.of(context)!;
          final selectedCode = localeController.locale?.languageCode;

          return AlertDialog(
            title: Text(l10n.selectLanguage),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String?>(
                  value: null,
                  groupValue: selectedCode,
                  title: Text(l10n.systemLanguage),
                  onChanged: (_) => _changeLanguage(
                    dialogContext,
                    parentContext: context,
                    languageCode: null,
                  ),
                ),
                RadioListTile<String?>(
                  value: 'tr',
                  groupValue: selectedCode,
                  title: Text(l10n.turkish),
                  onChanged: (_) => _changeLanguage(
                    dialogContext,
                    parentContext: context,
                    languageCode: 'tr',
                  ),
                ),
                RadioListTile<String?>(
                  value: 'en',
                  groupValue: selectedCode,
                  title: Text(l10n.english),
                  onChanged: (_) => _changeLanguage(
                    dialogContext,
                    parentContext: context,
                    languageCode: 'en',
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> _changeLanguage(
  BuildContext dialogContext, {
  required BuildContext parentContext,
  required String? languageCode,
}) async {
  await localeController.setLocale(
    languageCode == null ? null : Locale(languageCode),
  );

  if (dialogContext.mounted) {
    Navigator.pop(dialogContext);
  }

  if (!parentContext.mounted) return;

  final l10n = AppLocalizations.of(parentContext)!;
  ScaffoldMessenger.of(
    parentContext,
  ).showSnackBar(SnackBar(content: Text(l10n.languageUpdated)));
}
