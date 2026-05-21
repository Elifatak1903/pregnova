import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const rootDir = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
const i18nPath = resolve(rootDir, 'web_dashboard', 'i18n.js');

test('web dashboard Turkish and English dictionaries expose the same keys', () => {
  const source = readFileSync(i18nPath, 'utf8');

  const trKeys = extractDictionaryKeys(source, 'tr');
  const enKeys = extractDictionaryKeys(source, 'en');

  assert.deepEqual(enKeys, trKeys);
});

function extractDictionaryKeys(source, language) {
  const nextLanguage = language === 'tr' ? 'en' : null;
  const startPattern = new RegExp(`\\n\\s{2}${language}: \\{`);
  const startMatch = source.match(startPattern);

  assert.ok(startMatch, `${language} dictionary should exist`);

  const startIndex = startMatch.index + startMatch[0].length;
  const endIndex = nextLanguage
    ? source.search(new RegExp(`\\n\\s{2}${nextLanguage}: \\{`))
    : source.indexOf('\n  }\n};', startIndex);

  assert.ok(endIndex > startIndex, `${language} dictionary should close`);

  const block = source.slice(startIndex, endIndex);
  const keys = [...block.matchAll(/^\s{4}([A-Za-z0-9_]+):/gm)]
    .map(match => match[1])
    .sort();

  assert.ok(keys.length > 0, `${language} dictionary should include keys`);
  return keys;
}
