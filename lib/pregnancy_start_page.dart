import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PregnancyStartPage extends StatefulWidget {
  const PregnancyStartPage({super.key});

  @override
  State<PregnancyStartPage> createState() =>
      _PregnancyStartPageState();
}

class _PregnancyStartPageState extends State<PregnancyStartPage> {

  final haftaController = TextEditingController();

  Future<void> kaydet() async {

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final hafta = int.tryParse(haftaController.text) ?? 0;

    final baslangicTarihi =
    DateTime.now().subtract(Duration(days: hafta * 7));

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .set({
      "gebelikBaslangicTarihi":
      Timestamp.fromDate(baslangicTarihi),
    }, SetOptions(merge: true));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Kaydedildi ✅")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gebelik Başlangıç")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(
              controller: haftaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Kaçıncı haftadasın?",
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: kaydet,
              child: const Text("Kaydet"),
            )
          ],
        ),
      ),
    );
  }
}