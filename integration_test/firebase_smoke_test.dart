// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist, undefined_identifier

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pregnova/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const runFirebaseIntegration = bool.fromEnvironment(
    'RUN_FIREBASE_INTEGRATION',
  );

  group('Firebase smoke integration', () {
    testWidgets(
      'initializes Firebase and performs Firestore write/read/delete',
      (tester) async {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

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
  });
}
