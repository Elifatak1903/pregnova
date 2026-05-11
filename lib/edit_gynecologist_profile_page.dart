import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

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

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    licenseController.dispose();
    experienceController.dispose();
    hospitalController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final data = doc.data();
    if (data == null || !mounted) return;

    setState(() {
      nameController.text = data["name"] ?? "";
      emailController.text = data["email"] ?? "";
      licenseController.text = data["licenseNumber"] ?? "";
      experienceController.text = data["experience"] ?? "";
      hospitalController.text = data["hospital"] ?? "";
      diplomaUrl = data["diplomaUrl"] ?? data["diploma"];
    });
  }

  Future<void> saveData() async {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
      "name": nameController.text,
      "licenseNumber": licenseController.text,
      "experience": experienceController.text,
      "hospital": hospitalController.text,
      "diplomaUrl": diplomaUrl,
      "diploma": diplomaUrl,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.infoUpdated),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );

    Navigator.pop(context);
  }

  Future<void> pickDiploma() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.pickFiles(withData: true);

    if (result == null) return;

    final fileBytes = result.files.first.bytes;
    final fileName = result.files.first.name;

    if (fileBytes == null) return;

    setState(() => uploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final ref = FirebaseStorage.instance
          .ref()
          .child("diplomas")
          .child("gynecologist_${user.uid}-$fileName");

      await ref.putData(fileBytes);
      final url = await ref.getDownloadURL();

      if (!mounted) return;

      setState(() {
        diplomaUrl = url;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.diplomaUploaded)));
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.uploadError)));
    } finally {
      if (mounted) {
        setState(() => uploading = false);
      }
    }
  }

  Widget buildField(
    String title,
    TextEditingController controller, {
    bool readOnly = false,
  }) {
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
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: readOnly ? Colors.grey.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            decoration: InputDecoration(
              hintText: l10n.enterFieldHint(title),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.editInfo),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            buildField(l10n.fullName, nameController),
            buildField(l10n.emailField, emailController, readOnly: true),
            buildField(l10n.licenseNumber, licenseController),
            buildField(l10n.experience, experienceController),
            buildField(l10n.institution, hospitalController),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: uploading ? null : pickDiploma,
              icon: const Icon(Icons.upload_file),
              label: Text(uploading ? l10n.loading : l10n.uploadDiploma),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 10),
            if (diplomaUrl != null)
              Text(
                l10n.diplomaUploaded,
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
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
