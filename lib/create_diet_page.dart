import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> saveDiet() async {
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Diyet planı kaydedildi ✅")),
    );

    Navigator.pop(context);
  }

  Widget buildField(String title, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            hintText: "$title yaz...",
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              const Text(
                "Diyet Planı Oluştur 🥗",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              buildField("Kahvaltı", kahvalti),
              buildField("Ara Öğün 1", ara1),
              buildField("Öğle", ogle),
              buildField("Ara Öğün 2", ara2),
              buildField("Akşam", aksam),
              buildField("Gece", gece),
              buildField("Notlar", notlar),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: saveDiet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Kaydet"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}