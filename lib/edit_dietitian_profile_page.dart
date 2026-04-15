import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditDietitianProfilePage extends StatefulWidget {
  const EditDietitianProfilePage({super.key});

  @override
  State<EditDietitianProfilePage> createState() =>
      _EditDietitianProfilePageState();
}

class _EditDietitianProfilePageState
    extends State<EditDietitianProfilePage> {

  final nameController = TextEditingController();
  final expertiseController = TextEditingController();
  final experienceController = TextEditingController();
  final institutionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    final data = doc.data();

    if (data != null) {
      nameController.text = data["name"] ?? "";
      expertiseController.text = data["expertise"] ?? "";
      experienceController.text = data["experience"] ?? "";
      institutionController.text = data["institution"] ?? "";
    }
  }

  Future<void> saveData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .update({
      "name": nameController.text,
      "expertise": expertiseController.text,
      "experience": experienceController.text,
      "institution": institutionController.text,
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Bilgiler güncellendi ✅"),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
    );

    Navigator.pop(context);
  }

  Widget buildField(String title, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        )),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            hintText: "$title gir...",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Bilgileri Düzenle"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            buildField("İsim", nameController),
            buildField("Uzmanlık", expertiseController),
            buildField("Deneyim", experienceController),
            buildField("Kurum", institutionController),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: saveData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Kaydet"),
            ),
          ],
        ),
      ),
    );
  }
}