import assert from 'node:assert/strict';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import test from 'node:test';

const rootDir = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
const dashboardDir = join(rootDir, 'web_dashboard');

function moduleUrl(fileName) {
  return `${pathToFileURL(join(dashboardDir, fileName)).href}?case=${Date.now()}-${Math.random()}`;
}

function installBrowserGlobals({ language = 'en-US', pathname = '/pregnant.html' } = {}) {
  const storage = new Map();
  const events = [];
  let reloadCount = 0;

  Object.defineProperty(globalThis, 'localStorage', {
    configurable: true,
    value: {
    getItem: key => storage.has(key) ? storage.get(key) : null,
    setItem: (key, value) => storage.set(key, String(value)),
    removeItem: key => storage.delete(key),
    clear: () => storage.clear(),
    },
  });
  Object.defineProperty(globalThis, 'navigator', {
    configurable: true,
    value: { language },
  });
  Object.defineProperty(globalThis, 'CustomEvent', {
    configurable: true,
    value: class CustomEvent {
    constructor(type) {
      this.type = type;
    }
    },
  });
  Object.defineProperty(globalThis, 'window', {
    configurable: true,
    value: {
    location: {
      pathname,
      reload: () => {
        reloadCount++;
      },
    },
    dispatchEvent: event => events.push(event.type),
    },
  });
  Object.defineProperty(globalThis, 'document', {
    configurable: true,
    value: {
    documentElement: { lang: '' },
    querySelector: () => null,
    querySelectorAll: () => [],
    },
  });

  return {
    storage,
    events,
    get reloadCount() {
      return reloadCount;
    },
  };
}

test('i18n chooses Turkish from browser language when no saved language exists', async () => {
  installBrowserGlobals({ language: 'tr-TR' });

  const { getLanguage, t } = await import(moduleUrl('i18n.js'));

  assert.equal(getLanguage(), 'tr');
  assert.equal(t('home'), 'Ana Sayfa');
});

test('i18n setLanguage stores language and dispatches languageChanged event', async () => {
  const browser = installBrowserGlobals({ language: 'tr-TR' });
  const { getLanguage, setLanguage, t } = await import(moduleUrl('i18n.js'));

  setLanguage('en');

  assert.equal(browser.storage.get('pregnova:lang'), 'en');
  assert.deepEqual(browser.events, ['pregnova:languageChanged']);
  assert.equal(getLanguage(), 'en');
  assert.equal(t('weekValue', { week: 27 }), 'Week 27');
});

test('i18n ignores unsupported language values', async () => {
  const browser = installBrowserGlobals({ language: 'en-US' });
  const { getLanguage, setLanguage } = await import(moduleUrl('i18n.js'));

  setLanguage('de');

  assert.equal(browser.storage.has('pregnova:lang'), false);
  assert.equal(getLanguage(), 'en');
});

test('applyTranslations updates text, placeholder, title, and html lang', async () => {
  installBrowserGlobals({ language: 'en-US' });
  const textElement = { dataset: { i18n: 'home' }, textContent: '' };
  const inputElement = {
    dataset: { i18nPlaceholder: 'searchNamePlaceholder' },
    placeholder: '',
  };
  const titledElement = {
    dataset: { i18nTitle: 'language' },
    title: '',
  };
  const fakeRoot = {
    querySelectorAll(selector) {
      if (selector === '[data-i18n]') return [textElement];
      if (selector === '[data-i18n-placeholder]') return [inputElement];
      if (selector === '[data-i18n-title]') return [titledElement];
      return [];
    },
  };

  const { applyTranslations } = await import(moduleUrl('i18n.js'));
  applyTranslations(fakeRoot);

  assert.equal(globalThis.document.documentElement.lang, 'en');
  assert.equal(textElement.textContent, 'Home');
  assert.equal(inputElement.placeholder, 'Search name...');
  assert.equal(titledElement.title, 'Language');
});

test('renderSidebar creates a closed pregnant sidebar with language buttons', async () => {
  installBrowserGlobals({ language: 'en-US', pathname: '/pregnant.html' });
  const sidebar = createFakeSidebar();
  globalThis.document.querySelector = selector =>
    selector === '.sidebar' ? sidebar : null;

  const { renderSidebar } = await import(moduleUrl('sidebar.js'));
  renderSidebar('pregnant');

  assert.match(sidebar.innerHTML, /PregNova/);
  assert.match(sidebar.innerHTML, /Home/);
  assert.match(sidebar.innerHTML, /Risk Measurement/);
  assert.match(sidebar.innerHTML, /data-sidebar-lang="tr"/);
  assert.match(sidebar.innerHTML, /data-sidebar-lang="en"/);
  assert.doesNotMatch(sidebar.innerHTML, /sidebar-group open/);
});

test('renderSidebar opens submenu from caret click and stores state', async () => {
  const browser = installBrowserGlobals({
    language: 'en-US',
    pathname: '/dietitian.html',
  });
  const sidebar = createFakeSidebar();
  const group = createFakeGroup('dietitian:dietitian.html');
  const caret = {
    addEventListener(type, handler) {
      this.handler = handler;
    },
    closest(selector) {
      return selector === '.sidebar-group' ? group : null;
    },
  };
  sidebar.nodes['.sidebar-caret'] = [caret];
  globalThis.document.querySelector = selector =>
    selector === '.sidebar' ? sidebar : null;

  const { renderSidebar } = await import(moduleUrl('sidebar.js'));
  renderSidebar('dietitian');

  caret.handler({ stopPropagation() {} });

  assert.equal(group.classList.has('open'), true);
  assert.equal(browser.storage.get('sidebar:dietitian:dietitian.html'), 'open');
});

test('renderSidebar language button changes language and reloads page', async () => {
  const browser = installBrowserGlobals({
    language: 'tr-TR',
    pathname: '/gynecologist.html',
  });
  const sidebar = createFakeSidebar();
  const englishButton = {
    dataset: { sidebarLang: 'en' },
    addEventListener(type, handler) {
      this.handler = handler;
    },
  };
  sidebar.nodes['[data-sidebar-lang]'] = [englishButton];
  globalThis.document.querySelector = selector =>
    selector === '.sidebar' ? sidebar : null;

  const { renderSidebar } = await import(moduleUrl('sidebar.js'));
  renderSidebar('gynecologist');

  englishButton.handler({ stopPropagation() {} });

  assert.equal(browser.storage.get('pregnova:lang'), 'en');
  assert.equal(browser.reloadCount, 1);
});

function createFakeSidebar() {
  return {
    innerHTML: '',
    nodes: {},
    querySelectorAll(selector) {
      return this.nodes[selector] ?? [];
    },
  };
}

function createFakeGroup(key) {
  const classes = new Set();

  return {
    dataset: { group: key },
    classList: {
      toggle(className) {
        if (classes.has(className)) {
          classes.delete(className);
          return false;
        }

        classes.add(className);
        return true;
      },
      has(className) {
        return classes.has(className);
      },
    },
  };
}
