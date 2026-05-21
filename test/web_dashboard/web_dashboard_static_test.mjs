import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const rootDir = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
const dashboardDir = join(rootDir, 'web_dashboard');

const panelPages = [
  'pregnant.html',
  'gynecologist.html',
  'dietitian.html',
  'admin.html',
];

const criticalScripts = [
  'app.js',
  'i18n.js',
  'sidebar.js',
  'pregnant.js',
  'gynecologist.js',
  'dietitian.js',
  'admin.js',
  'nutritionEngine.js',
  'riskEngine.js',
];

function readDashboardFile(fileName) {
  return readFileSync(join(dashboardDir, fileName), 'utf8');
}

test('critical panel pages exist and include shared layout assets', () => {
  for (const page of panelPages) {
    const pagePath = join(dashboardDir, page);
    assert.equal(existsSync(pagePath), true, `${page} should exist`);

    const html = readDashboardFile(page);
    assert.match(html, /<meta charset="UTF-8">/i, `${page} should be UTF-8`);
    assert.match(html, /css\/theme\.css/, `${page} should load theme.css`);
    assert.match(html, /css\/sidebar\.css/, `${page} should load sidebar.css`);
  }

  const loginHtml = readDashboardFile('login.html');
  assert.match(loginHtml, /<meta charset="UTF-8">/i);
  assert.match(loginHtml, /css\/auth\.css/, 'login.html should load auth.css');
});

test('authenticated panel pages keep sidebar and localization markers', () => {
  for (const page of panelPages) {
    const html = readDashboardFile(page);
    assert.match(html, /class="sidebar"/, `${page} should render sidebar host`);
    assert.match(
      html,
      /data-i18n=/,
      `${page} should contain localization markers`,
    );
  }
});

test('patient, gynecologist, and dietitian pages include notification dropdowns', () => {
  for (const page of [
    'pregnant.html',
    'gynecologist.html',
    'dietitian.html',
    'dietitian_clients.html',
    'dietitian_requests.html',
    'son_analizler.html',
    'messages_dietitian.html',
    'select_client_for_diet.html',
    'create_diet.html',
    'client_detail.html',
    'account_dietitian.html',
  ]) {
    const html = readDashboardFile(page);
    assert.match(
      html,
      /id="notifDropdown"/,
      `${page} should include notification dropdown`,
    );
    assert.match(html, /id="notifList"/, `${page} should include notifList`);
    assert.match(html, /class="badge"/, `${page} should include badge`);
  }
});

test('role dashboards load their matching page scripts as modules', () => {
  const expectedScripts = {
    'pregnant.html': 'pregnant.js',
    'gynecologist.html': 'gynecologist.js',
    'dietitian.html': 'dietitian.js',
    'admin.html': 'admin.js',
  };

  for (const [page, script] of Object.entries(expectedScripts)) {
    const html = readDashboardFile(page);
    assert.match(
      html,
      new RegExp(`<script[^>]+type=["']module["'][^>]+src=["']${script}["']`),
      `${page} should load ${script} as module`,
    );
  }
});

test('web localization dictionary includes main sidebar and account labels', () => {
  const i18n = readDashboardFile('i18n.js');

  for (const key of [
    'home',
    'clients',
    'requests',
    'messages',
    'account',
    'logout',
    'editProfile',
    'changePassword',
    'giveFeedback',
  ]) {
    assert.match(i18n, new RegExp(`${key}:`), `i18n.js should include ${key}`);
  }
});

test('notification action routing keeps role-specific destinations', () => {
  const appScript = readDashboardFile('app.js');

  const expectedRoutes = [
    'patient_detail.html?uid=',
    'client_detail.html?id=',
    'son_olcumler.html',
    'son_analizler.html',
    'admin_requests.html',
    'expert_application.html',
    'requests_gynecologist.html',
    'dietitian_requests.html',
    'expert_search.html',
    'messages_gynecologist.html',
    'messages_dietitian.html',
    'messages_pregnant.html',
  ];

  assert.match(
    appScript,
    /export function getNotificationActionPage/,
    'app.js should expose notification action routing',
  );

  for (const route of expectedRoutes) {
    assert.match(
      appScript,
      new RegExp(route.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')),
      `notification routing should include ${route}`,
    );
  }
});

test('redirect page keeps role-specific dashboard destinations', () => {
  const redirectPage = readDashboardFile('redirect.html');
  const expectedRoleRoutes = {
    pregnant: 'pregnant.html',
    gynecologist: 'gynecologist.html',
    dietitian: 'dietitian.html',
    admin: 'admin.html',
  };

  for (const [role, route] of Object.entries(expectedRoleRoutes)) {
    assert.match(
      redirectPage,
      new RegExp(`role === ["']${role}["']`),
      `redirect.html should check ${role} role`,
    );
    assert.match(
      redirectPage,
      new RegExp(`window\\.location\\.href = ["']${route}["']`),
      `redirect.html should send ${role} to ${route}`,
    );
  }
});

test('critical dashboard JavaScript files pass syntax check', () => {
  for (const script of criticalScripts) {
    execFileSync(process.execPath, ['--check', join(dashboardDir, script)], {
      stdio: 'pipe',
    });
  }
});
