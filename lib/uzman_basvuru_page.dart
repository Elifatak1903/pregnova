import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

class UzmanBasvuruPage extends StatefulWidget {
  const UzmanBasvuruPage({super.key});

  @override
  State<UzmanBasvuruPage> createState() => _UzmanBasvuruPageState();
}

class _UzmanBasvuruPageState extends State<UzmanBasvuruPage> {
  PlatformFile? selectedFile;
  final _formKey = GlobalKey<FormState>();

  String role = 'dietitian';
  String licenseNo = '';
  String experience = '';
  String phone = '';
  String hospital = '';
  String city = '';

  bool isLoading = false;
  String applicationStatus = 'none';

  @override
  void initState() {
    super.initState();
    checkApplicationStatus();
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
    );

    if (result != null) {
      setState(() {
        selectedFile = result.files.first;
      });
    }
  }

  Future<String?> uploadFile() async {
    if (selectedFile == null) return null;

    final file = selectedFile!;

    if (file.bytes == null) {
      throw Exception("Dosya verisi okunamadı. pickFiles içinde withData: true olmalı.");
    }

    final safeFileName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

    final path =
        'expert_documents/${FirebaseAuth.instance.currentUser!.uid}/${DateTime.now().millisecondsSinceEpoch}_$safeFileName';

    final ref = FirebaseStorage.instance.ref(path);

    final uploadTask = await ref.putData(
      file.bytes!,
      SettableMetadata(
        contentType: file.extension == 'pdf'
            ? 'application/pdf'
            : 'image/jpeg',
      ),
    );

    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> checkApplicationStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('expert_applications')
        .doc(uid)
        .get();

    if (!mounted) return;

    if (doc.exists && doc.data() != null) {
      setState(() {
        applicationStatus = doc['status'] ?? 'none';
      });
    }
  }

  Future<void> submitApplication() async {
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) return;

    if (selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.uploadDocumentPrompt),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kullanıcı oturumu bulunamadı."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final docRef = FirebaseFirestore.instance
          .collection('expert_applications')
          .doc(user.uid);

      final existingDoc = await docRef.get();

      final existingData = existingDoc.data();

      if (existingDoc.exists &&
          existingData != null &&
          existingData['status'] == 'pending') {
        if (!mounted) return;

        setState(() => isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.applicationAlreadyPending)),
        );
        return;
      }

      if (existingDoc.exists &&
          existingData != null &&
          existingData['status'] == 'approved') {
        if (!mounted) return;

        setState(() => isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.alreadyExpert)),
        );
        return;
      }

      final uploadedUrl = await uploadFile();

      if (uploadedUrl == null) {
        throw Exception("Dosya yüklenemedi. Lütfen tekrar deneyin.");
      }

      final data = <String, dynamic>{
        'uid': user.uid,
        'email': user.email ?? '',
        'fullName': user.displayName ?? '',
        'role': role,
        'licenseNumber': licenseNo.trim(),
        'experience': experience.trim(),
        'phone': phone.trim(),
        'hospital': hospital.trim(),
        'city': city.trim(),
        'documentUrl': uploadedUrl,
        'status': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!existingDoc.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await docRef.set(data, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('notification').add({
        'uid': user.uid,
        'title': l10n.expertApplicationReceivedTitle,
        'message': l10n.expertApplicationReceivedMessage,
        'type': 'expert_application',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        isLoading = false;
        applicationStatus = 'pending';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.applicationReceived),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint("UZMAN BAŞVURU HATASI: $e");

      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Başvuru gönderilirken hata oluştu: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildStatusView() {
    final l10n = AppLocalizations.of(context)!;

    if (applicationStatus == 'pending') {
      return Center(
        child: Text(
          l10n.applicationPendingStatus,
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (applicationStatus == 'approved') {
      return Center(
        child: Text(
          l10n.applicationApprovedStatus,
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (applicationStatus == 'rejected') {
      return Center(
        child: Text(
          l10n.applicationRejectedStatus,
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.expertApplication),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: applicationStatus != 'none'
              ? buildStatusView()
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: role,
                          items: [
                            DropdownMenuItem(
                              value: 'dietitian',
                              child: Text(l10n.dietitian),
                            ),
                            DropdownMenuItem(
                              value: 'gynecologist',
                              child: Text(l10n.gynecologist),
                            ),
                          ],
                          onChanged: (val) {
                            if (val == null) return;
                            setState(() => role = val);
                          },
                          decoration: buildInput(context, l10n.expertiseArea),
                        ),
                        TextFormField(
                          decoration: buildInput(
                            context,
                            l10n.licenseRegistryNumber,
                          ),
                          onChanged: (v) => licenseNo = v,
                          validator: (v) => v == null || v.isEmpty
                              ? l10n.requiredField
                              : null,
                        ),
                        TextFormField(
                          decoration: buildInput(context, l10n.experience),
                          onChanged: (v) => experience = v,
                        ),
                        TextFormField(
                          decoration: buildInput(context, l10n.phone),
                          keyboardType: TextInputType.phone,
                          onChanged: (v) => phone = v,
                        ),
                        TextFormField(
                          decoration: buildInput(context, l10n.institution),
                          onChanged: (v) => hospital = v,
                        ),
                        TextFormField(
                          decoration: buildInput(context, l10n.city),
                          onChanged: (v) => city = v,
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          onPressed: pickFile,
                          icon: const Icon(Icons.upload_file),
                          label: Text(l10n.uploadDocument),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (selectedFile != null)
                          Text(
                            l10n.selectedFileName(selectedFile!.name),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              submitApplication();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 40,
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  l10n.submitApplication,
                                  style: const TextStyle(color: Colors.white),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

InputDecoration buildInput(BuildContext context, String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Theme.of(context).colorScheme.surface,
    labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.primary,
        width: 2,
      ),
    ),
  );
}
