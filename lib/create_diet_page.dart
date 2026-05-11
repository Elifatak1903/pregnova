import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

class CreateDietPage extends StatefulWidget {
  final String clientId;

  const CreateDietPage({super.key, required this.clientId});

  @override
  State<CreateDietPage> createState() => _CreateDietPageState();
}

class _CreateDietPageState extends State<CreateDietPage> {
  final kahvalti = TextEditingController();
  final ara1 = TextEditingController();
  final ogle = TextEditingController();
  final ara2 = TextEditingController();
  final aksam = TextEditingController();
  final gece = TextEditingController();
  final notlar = TextEditingController();

  @override
  void dispose() {
    kahvalti.dispose();
    ara1.dispose();
    ogle.dispose();
    ara2.dispose();
    aksam.dispose();
    gece.dispose();
    notlar.dispose();
    super.dispose();
  }

  Future<void> saveDiet() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection("diet_plans").add({
      "clientId": widget.clientId,
      "dietitianId": uid,
      "kahvalti": kahvalti.text,
      "ara1": ara1.text,
      "ogle": ogle.text,
      "ara2": ara2.text,
      "aksam": aksam.text,
      "gece": gece.text,
      "notlar": notlar.text,
      "createdAt": FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.dietPlanSaved),
        backgroundColor: primaryColor,
      ),
    );

    navigator.pop();
  }

  Widget buildField(String title, TextEditingController controller) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            hintText: l10n.writeFieldHint(title),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                l10n.createDietPlan,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              buildField(l10n.breakfast, kahvalti),
              buildField(l10n.snack1, ara1),
              buildField(l10n.lunch, ogle),
              buildField(l10n.snack2, ara2),
              buildField(l10n.dinner, aksam),
              buildField(l10n.nightSnack, gece),
              buildField(l10n.notes, notlar),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveDiet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
