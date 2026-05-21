import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Localization resources', () {
    test('Turkish and English ARB files expose the same message keys', () {
      final trKeys = _messageKeys('lib/l10n/app_tr.arb');
      final enKeys = _messageKeys('lib/l10n/app_en.arb');

      expect(enKeys.difference(trKeys), isEmpty, reason: 'Keys missing in TR');
      expect(trKeys.difference(enKeys), isEmpty, reason: 'Keys missing in EN');
    });
  });
}

Set<String> _messageKeys(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path should exist');

  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  return json.keys
      .where((key) => !key.startsWith('@') && key != '@@locale')
      .toSet();
}
