// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist, undefined_identifier

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pregnova/firebase_options.dart';

Future<void> _ensureFirebaseInitialized() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const runFirebaseIntegration = bool.fromEnvironment(
    'RUN_FIREBASE_INTEGRATION',
  );

  group('Firebase smoke integration', () {
    testWidgets(
      'initializes Firebase and performs Firestore write/read/delete',
      (tester) async {
        await _ensureFirebaseInitialized();

        final firestore = FirebaseFirestore.instance;
        final testDoc = firestore.collection('integration_test_runs').doc();

        final payload = {
          'source': 'flutter_integration_test',
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'started',
        };

        await testDoc.set(payload);

        final snapshot = await testDoc.get();
        expect(snapshot.exists, isTrue);
        expect(snapshot.data()?['source'], 'flutter_integration_test');
        expect(snapshot.data()?['status'], 'started');

        await testDoc.delete();

        final deletedSnapshot = await testDoc.get();
        expect(deletedSnapshot.exists, isFalse);
      },
      // Run with:
      // flutter test integration_test/firebase_smoke_test.dart -d <deviceId>
      // --dart-define=RUN_FIREBASE_INTEGRATION=true
      skip: !runFirebaseIntegration,
    );

    testWidgets(
      'writes and reads a risk measurement flow with test data',
      (tester) async {
        await _ensureFirebaseInitialized();

        final firestore = FirebaseFirestore.instance;
        final testUid =
            'integration_test_patient_${DateTime.now().millisecondsSinceEpoch}';
        final userDoc = firestore.collection('users').doc(testUid);
        final riskDoc = firestore.collection('risk_olcumleri').doc();

        try {
          await userDoc.set({
            'name': 'Integration',
            'surname': 'Patient',
            'role': 'pregnant',
            'riskLevel': 'medium',
            'createdAt': FieldValue.serverTimestamp(),
          });

          await riskDoc.set({
            'uid': testUid,
            'tarih': Timestamp.now(),
            'sistolik': 140,
            'diastolik': 90,
            'aclikSeker': 95,
            'toklukSeker': 130,
            'preeklampsiRisk': 'MEDIUM',
            'diyabetRisk': 'MEDIUM',
            'pretermRisk': 'LOW',
          });

          final snapshot = await riskDoc.get();
          expect(snapshot.exists, isTrue);
          expect(snapshot.data()?['uid'], testUid);
          expect(snapshot.data()?['preeklampsiRisk'], 'MEDIUM');
          expect(snapshot.data()?['diyabetRisk'], 'MEDIUM');
        } finally {
          await riskDoc.delete();
          await userDoc.delete();
        }
      },
      skip: !runFirebaseIntegration,
    );

    testWidgets(
      'writes and reads a nutrition analysis flow with daily totals',
      (tester) async {
        await _ensureFirebaseInitialized();

        final firestore = FirebaseFirestore.instance;
        final testUid =
            'integration_test_patient_${DateTime.now().millisecondsSinceEpoch}';
        final nutritionDoc = firestore.collection('besin_analizleri').doc();

        try {
          await nutritionDoc.set({
            'uid': testUid,
            'createdAt': FieldValue.serverTimestamp(),
            'tarih': Timestamp.now(),
            'besinler': [
              {'ad': 'yogurt', 'miktar': 1, 'birim': 'kase'},
              {'ad': 'spinach', 'miktar': 2, 'birim': 'tabak'},
            ],
            'toplam': {
              'kalori': 260,
              'protein': 18,
              'karbonhidrat': 22,
              'yag': 10,
            },
            'feedback': 'Integration test nutrition feedback',
          });

          final snapshot = await nutritionDoc.get();
          final data = snapshot.data();

          expect(snapshot.exists, isTrue);
          expect(data?['uid'], testUid);
          expect(data?['besinler'], isA<List<dynamic>>());
          expect(data?['toplam'], isA<Map<String, dynamic>>());
          expect(data?['toplam']['kalori'], 260);
        } finally {
          await nutritionDoc.delete();
        }
      },
      skip: !runFirebaseIntegration,
    );

    testWidgets(
      'writes and reads an actionable notification with receiver id',
      (tester) async {
        await _ensureFirebaseInitialized();

        final firestore = FirebaseFirestore.instance;
        final testUid =
            'integration_test_patient_${DateTime.now().millisecondsSinceEpoch}';
        final notificationDoc = firestore.collection('notification').doc();

        try {
          await notificationDoc.set({
            'uid': testUid,
            'title': 'Integration Test Notification',
            'message': 'Risk measurement needs review',
            'type': 'risk_alert',
            'targetPage': 'risk_detail',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });

          final snapshot = await notificationDoc.get();
          final data = snapshot.data();

          expect(snapshot.exists, isTrue);
          expect(data?['uid'], testUid);
          expect(data?['type'], 'risk_alert');
          expect(data?['targetPage'], 'risk_detail');
          expect(data?['isRead'], isFalse);

          await notificationDoc.update({'isRead': true});

          final readSnapshot = await notificationDoc.get();
          expect(readSnapshot.data()?['isRead'], isTrue);
        } finally {
          await notificationDoc.delete();
        }
      },
      skip: !runFirebaseIntegration,
    );

    testWidgets(
      'writes and reads a chat document between patient and expert',
      (tester) async {
        await _ensureFirebaseInitialized();

        final firestore = FirebaseFirestore.instance;
        final patientId =
            'integration_test_patient_${DateTime.now().millisecondsSinceEpoch}';
        final expertId =
            'integration_test_expert_${DateTime.now().millisecondsSinceEpoch}';
        final chatDoc = firestore.collection('chats').doc();

        try {
          await chatDoc.set({
            'users': [patientId, expertId],
            'lastMessage': 'Integration test feedback',
            'lastMessageTime': FieldValue.serverTimestamp(),
          });

          final snapshot = await chatDoc.get();
          final data = snapshot.data();

          expect(snapshot.exists, isTrue);
          expect(data?['users'], contains(patientId));
          expect(data?['users'], contains(expertId));
          expect(data?['lastMessage'], 'Integration test feedback');
        } finally {
          await chatDoc.delete();
        }
      },
      skip: !runFirebaseIntegration,
    );

    testWidgets(
      'writes, updates, and reads an expert request flow',
      (tester) async {
        await _ensureFirebaseInitialized();

        final firestore = FirebaseFirestore.instance;
        final suffix = DateTime.now().millisecondsSinceEpoch;
        final patientId = 'integration_test_patient_$suffix';
        final expertId = 'integration_test_expert_$suffix';
        final requestDoc = firestore.collection('expert_requests').doc();

        try {
          await requestDoc.set({
            'clientId': patientId,
            'expertId': expertId,
            'expertRole': 'dietitian',
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });

          final pendingSnapshot = await requestDoc.get();
          expect(pendingSnapshot.exists, isTrue);
          expect(pendingSnapshot.data()?['clientId'], patientId);
          expect(pendingSnapshot.data()?['expertId'], expertId);
          expect(pendingSnapshot.data()?['status'], 'pending');

          await requestDoc.update({
            'status': 'approved',
            'approvedAt': FieldValue.serverTimestamp(),
          });

          final approvedSnapshot = await requestDoc.get();
          expect(approvedSnapshot.data()?['status'], 'approved');
        } finally {
          await requestDoc.delete();
        }
      },
      skip: !runFirebaseIntegration,
    );

    testWidgets(
      'writes and reads a diet plan flow for a selected client',
      (tester) async {
        await _ensureFirebaseInitialized();

        final firestore = FirebaseFirestore.instance;
        final suffix = DateTime.now().millisecondsSinceEpoch;
        final clientId = 'integration_test_patient_$suffix';
        final dietitianId = 'integration_test_dietitian_$suffix';
        final planDoc = firestore.collection('diet_plans').doc();

        try {
          await planDoc.set({
            'clientId': clientId,
            'dietitianId': dietitianId,
            'kahvalti': 'sut',
            'ara1': 'ceviz',
            'ogle': 'sebze',
            'ara2': 'yumurta',
            'aksam': 'pilav',
            'gece': '-',
            'notlar': 'Integration test diet plan',
            'createdAt': FieldValue.serverTimestamp(),
          });

          final snapshot = await planDoc.get();
          final data = snapshot.data();

          expect(snapshot.exists, isTrue);
          expect(data?['clientId'], clientId);
          expect(data?['dietitianId'], dietitianId);
          expect(data?['kahvalti'], 'sut');
          expect(data?['notlar'], 'Integration test diet plan');
        } finally {
          await planDoc.delete();
        }
      },
      skip: !runFirebaseIntegration,
    );

    testWidgets(
      'writes and reads a message linked to a chat flow',
      (tester) async {
        await _ensureFirebaseInitialized();

        final firestore = FirebaseFirestore.instance;
        final suffix = DateTime.now().millisecondsSinceEpoch;
        final patientId = 'integration_test_patient_$suffix';
        final expertId = 'integration_test_expert_$suffix';
        final chatDoc = firestore.collection('chats').doc();
        final messageDoc = firestore.collection('messages').doc();

        try {
          await chatDoc.set({
            'users': [patientId, expertId],
            'lastMessage': '',
            'lastMessageTime': FieldValue.serverTimestamp(),
          });

          await messageDoc.set({
            'chatId': chatDoc.id,
            'senderId': expertId,
            'receiverId': patientId,
            'text': 'Integration test message',
            'createdAt': FieldValue.serverTimestamp(),
          });

          await chatDoc.update({
            'lastMessage': 'Integration test message',
            'lastMessageTime': FieldValue.serverTimestamp(),
          });

          final messageSnapshot = await messageDoc.get();
          final chatSnapshot = await chatDoc.get();

          expect(messageSnapshot.exists, isTrue);
          expect(messageSnapshot.data()?['chatId'], chatDoc.id);
          expect(messageSnapshot.data()?['senderId'], expertId);
          expect(messageSnapshot.data()?['text'], 'Integration test message');
          expect(chatSnapshot.data()?['lastMessage'], 'Integration test message');
        } finally {
          await messageDoc.delete();
          await chatDoc.delete();
        }
      },
      skip: !runFirebaseIntegration,
    );
  });
}
