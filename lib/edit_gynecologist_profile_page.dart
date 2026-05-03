import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditGynecologistProfilePage extends StatefulWidget {
  const EditGynecologistProfilePage({super.key});

  @override
  State<EditGynecologistProfilePage> createState() =>
      _EditGynecologistProfilePageState();
}

class _EditGynecologistProfilePageState
    extends State<EditGynecologistProfilePage> {

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final licenseController = TextEditingController();
  final experienceController = TextEditingController();
  final hospitalController = TextEditingController();

  bool uploading = false;
  String? diplomaUrl;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  /// 🔥 DATA ÇEK
  Future<void> loadData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    final data = doc.data();

    if (data != null) {
      nameController.text = data["name"] ?? "";
      emailController.text = data["email"] ?? "";
      licenseController.text = data["licenseNumber"] ?? "";
      experienceController.text = data["experience"] ?? "";
      hospitalController.text = data["hospital"] ?? "";
      diplomaUrl = data["diplomaUrl"];
    }
  }

  Future<void> saveData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .update({
      "name": nameController.text,
      "licenseNumber": licenseController.text,
      "experience": experienceController.text,
      "hospital": hospitalController.text,
      "diplomaUrl": diplomaUrl,
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

  Future<void> pickDiploma() async {
    final result = await FilePicker.platform.pickFiles(withData: true);

    if (result == null) return;

    final fileBytes = result.files.first.bytes;
    final fileName = result.files.first.name;

    if (fileBytes == null) return;

    setState(() => uploading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final ref = FirebaseStorage.instance
          .ref()
          .child("diplomas")
          .child("gynecologist_$uid-$fileName");

      await ref.putData(fileBytes);

      final url = await ref.getDownloadURL();

      setState(() {
        diplomaUrl = url;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Diploma yüklendi ✅")),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Yükleme hatası ❌")),
      );
    } finally {
      setState(() => uploading = false);
    }
  }

  Widget buildField(String title, TextEditingController controller,
      {bool readOnly = false}) {
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
        const SizedBox(height: 6),

        Container(
          decoration: BoxDecoration(
            color: readOnly ? Colors.grey.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            decoration: InputDecoration(
              hintText: "$title gir...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ),

        const SizedBox(height: 16),
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

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            buildField("İsim Soyisim", nameController),
            buildField("Email", emailController, readOnly: true),

            buildField("Lisans Numarası", licenseController),
            buildField("Deneyim (yıl)", experienceController),
            buildField("Çalıştığı Hastane", hospitalController),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: uploading ? null : pickDiploma,
              icon: const Icon(Icons.upload_file),
              label: Text(uploading ? "Yükleniyor..." : "Diploma Yükle"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 10),

            if (diplomaUrl != null)
              Text(
                "Diploma yüklendi ✅",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),

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