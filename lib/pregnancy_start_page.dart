import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

class PregnancyStartPage extends StatefulWidget {
  const PregnancyStartPage({super.key});

  @override
  State<PregnancyStartPage> createState() => _PregnancyStartPageState();
}

class _PregnancyStartPageState extends State<PregnancyStartPage> {
  final haftaController = TextEditingController();

  @override
  void dispose() {
    haftaController.dispose();
    super.dispose();
  }

  Future<void> kaydet() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final hafta = int.tryParse(haftaController.text);

    if (uid == null || hafta == null || hafta < 1 || hafta > 42) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.pregnancyWeekRangeValidation)),
      );
      return;
    }

    final baslangicTarihi = DateTime.now().subtract(Duration(days: hafta * 7));

    await FirebaseFirestore.instance.collection("users").doc(uid).set({
      "gebelikBaslangicTarihi": Timestamp.fromDate(baslangicTarihi),
    }, SetOptions(merge: true));

    if (!mounted) return;

    messenger.showSnackBar(SnackBar(content: Text(l10n.saved)));
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pregnancyStart)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: haftaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.whichPregnancyWeek),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: kaydet, child: Text(l10n.save)),
          ],
        ),
      ),
    );
  }
}
