import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  deleteDoc,
  doc,
  getDoc,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'pregnova-security-test',
    firestore: {
      rules: readFileSync('firestore.rules', 'utf8'),
      host: '127.0.0.1',
      port: 8081,
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

after(async () => {
  await testEnv.cleanup();
});

function authedDb(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

async function seed(path, data) {
  await testEnv.withSecurityRulesDisabled(async context => {
    await setDoc(doc(context.firestore(), path), data);
  });
}

describe('Firestore security rules', () => {
  test('user can read own profile but not another user profile', async () => {
    await seed('users/alice', { role: 'pregnant', name: 'Alice' });
    await seed('users/bob', { role: 'pregnant', name: 'Bob' });

    await assertSucceeds(getDoc(doc(authedDb('alice'), 'users/alice')));
    await assertFails(getDoc(doc(authedDb('alice'), 'users/bob')));
  });

  test('admin can read and delete users', async () => {
    await seed('users/admin-1', { role: 'admin' });
    await seed('users/patient-1', { role: 'pregnant' });

    await assertSucceeds(getDoc(doc(authedDb('admin-1'), 'users/patient-1')));
    await assertSucceeds(deleteDoc(doc(authedDb('admin-1'), 'users/patient-1')));
  });

  test('patient can create own risk measurement but not another patient measurement', async () => {
    await seed('users/patient-1', { role: 'pregnant' });
    await seed('users/patient-2', { role: 'pregnant' });

    await assertSucceeds(
      setDoc(doc(authedDb('patient-1'), 'risk_olcumleri/risk-1'), {
        uid: 'patient-1',
        sistolik: 120,
        diastolik: 80,
      }),
    );

    await assertFails(
      setDoc(doc(authedDb('patient-1'), 'risk_olcumleri/risk-2'), {
        uid: 'patient-2',
        sistolik: 120,
        diastolik: 80,
      }),
    );
  });

  test('assigned doctor can read patient profile and risk measurements', async () => {
    await seed('users/doctor-1', { role: 'gynecologist' });
    await seed('users/doctor-2', { role: 'gynecologist' });
    await seed('users/patient-1', {
      role: 'pregnant',
      assignedDoctor: 'doctor-1',
    });
    await seed('risk_olcumleri/risk-1', {
      uid: 'patient-1',
      sistolik: 140,
      diastolik: 90,
    });

    await assertSucceeds(getDoc(doc(authedDb('doctor-1'), 'users/patient-1')));
    await assertSucceeds(
      getDoc(doc(authedDb('doctor-1'), 'risk_olcumleri/risk-1')),
    );
    await assertFails(getDoc(doc(authedDb('doctor-2'), 'users/patient-1')));
    await assertFails(
      getDoc(doc(authedDb('doctor-2'), 'risk_olcumleri/risk-1')),
    );
  });

  test('assigned dietitian can read client profile, analyses, and diet plans', async () => {
    await seed('users/dietitian-1', { role: 'dietitian' });
    await seed('users/dietitian-2', { role: 'dietitian' });
    await seed('users/client-1', {
      role: 'pregnant',
      assignedDietitian: 'dietitian-1',
    });
    await seed('besin_analizleri/analysis-1', {
      uid: 'client-1',
      toplam: { kalori: 260 },
    });
    await seed('diet_plans/plan-1', {
      clientId: 'client-1',
      dietitianId: 'dietitian-1',
      kahvalti: 'sut',
      ogle: 'sebze',
      aksam: 'pilav',
    });

    await assertSucceeds(getDoc(doc(authedDb('dietitian-1'), 'users/client-1')));
    await assertSucceeds(
      getDoc(doc(authedDb('dietitian-1'), 'besin_analizleri/analysis-1')),
    );
    await assertSucceeds(
      getDoc(doc(authedDb('dietitian-1'), 'diet_plans/plan-1')),
    );

    await assertFails(getDoc(doc(authedDb('dietitian-2'), 'users/client-1')));
    await assertFails(
      getDoc(doc(authedDb('dietitian-2'), 'besin_analizleri/analysis-1')),
    );
    await assertFails(
      getDoc(doc(authedDb('dietitian-2'), 'diet_plans/plan-1')),
    );
  });

  test('notification can be read and marked as read only by receiver', async () => {
    await seed('users/patient-1', { role: 'pregnant' });
    await seed('users/patient-2', { role: 'pregnant' });
    await seed('notification/notif-1', {
      uid: 'patient-1',
      title: 'Risk Warning',
      message: 'Check measurements',
      type: 'risk_alert',
      isRead: false,
    });

    await assertSucceeds(getDoc(doc(authedDb('patient-1'), 'notification/notif-1')));
    await assertSucceeds(
      updateDoc(doc(authedDb('patient-1'), 'notification/notif-1'), {
        isRead: true,
      }),
    );
    await assertFails(getDoc(doc(authedDb('patient-2'), 'notification/notif-1')));
  });

  test('chat is visible only to chat participants', async () => {
    await seed('users/patient-1', { role: 'pregnant' });
    await seed('users/doctor-1', { role: 'gynecologist' });
    await seed('users/outsider', { role: 'pregnant' });
    await seed('chats/chat-1', {
      users: ['patient-1', 'doctor-1'],
      lastMessage: 'Hello',
    });

    await assertSucceeds(getDoc(doc(authedDb('patient-1'), 'chats/chat-1')));
    await assertSucceeds(getDoc(doc(authedDb('doctor-1'), 'chats/chat-1')));
    await assertFails(getDoc(doc(authedDb('outsider'), 'chats/chat-1')));
  });
});
