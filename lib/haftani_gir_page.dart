import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HaftaniGirPage extends StatefulWidget {
  const HaftaniGirPage({super.key});

  @override
  State<HaftaniGirPage> createState() => _HaftaniGirPageState();
}

class _HaftaniGirPageState extends State<HaftaniGirPage> {
  final controller = TextEditingController();

  Future<void> saveWeek() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    int week = int.parse(controller.text);

    await FirebaseFirestore.instance.collection("users").doc(uid).update({
      "pregWeek": week,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hafta Bilgisi Gir"),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Kaçıncı haftadasın?",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveWeek,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                "Kaydet",
                style: TextStyle(fontSize: 16),
              ),
            )
          ],
        ),
      ),
    );
  }
}
