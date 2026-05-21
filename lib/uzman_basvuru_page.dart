import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

class UzmanBasvuruPage extends StatefulWidget {
  final bool fromRegister;

  const UzmanBasvuruPage({super.key, this.fromRegister = false});

  @override
  State<UzmanBasvuruPage> createState() => _UzmanBasvuruPageState();
}

class _UzmanBasvuruPageState extends State<UzmanBasvuruPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final surnameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  PlatformFile? selectedFile;
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
    if (!widget.fromRegister) {
      checkApplicationStatus();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    surnameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);

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
      throw Exception("Dosya verisi okunamadı.");
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

    return uploadTask.ref.getDownloadURL();
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
      _showSnack(l10n.uploadDocumentPrompt, isError: true);
      return;
    }

    if (widget.fromRegister && !_validateRegisterFields(l10n)) {
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null && !widget.fromRegister) {
      _showSnack("Kullanıcı oturumu bulunamadı.", isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      if (widget.fromRegister) {
        user = await _createPendingExpertAccount();
      }

      if (user == null) {
        throw Exception("Kullanıcı oturumu bulunamadı.");
      }

      final docRef = FirebaseFirestore.instance
          .collection('expert_applications')
          .doc(user.uid);
      final existingDoc = await docRef.get();
      final existingData = existingDoc.data();

      if (existingData?['status'] == 'pending') {
        if (!mounted) return;
        setState(() => isLoading = false);
        _showSnack(l10n.applicationAlreadyPending);
        return;
      }

      if (existingData?['status'] == 'approved') {
        if (!mounted) return;
        setState(() => isLoading = false);
        _showSnack(l10n.alreadyExpert);
        return;
      }

      final uploadedUrl = await uploadFile();

      if (uploadedUrl == null) {
        throw Exception("Dosya yüklenemedi. Lütfen tekrar deneyin.");
      }

      final data = <String, dynamic>{
        'uid': user.uid,
        'email': widget.fromRegister
            ? emailController.text.trim()
            : user.email ?? '',
        'fullName': widget.fromRegister
            ? "${nameController.text.trim()} ${surnameController.text.trim()}"
            : user.displayName ?? '',
        if (widget.fromRegister) 'name': nameController.text.trim(),
        if (widget.fromRegister) 'surname': surnameController.text.trim(),
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

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'expertApplicationStatus': 'pending',
        'requestedRole': role,
      }, SetOptions(merge: true));

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

      if (widget.fromRegister) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        await _showRegisterSuccessDialog();
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        _showSnack(l10n.applicationReceived);
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("UZMAN BASVURU HATASI: $e");

      if (!mounted) return;

      setState(() => isLoading = false);
      _showSnack(_submitErrorText(e), isError: true);
    }
  }

  bool _validateRegisterFields(AppLocalizations l10n) {
    final name = nameController.text.trim();
    final surname = surnameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || surname.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnack(l10n.fillAllFields, isError: true);
      return false;
    }

    if (password.length < 6) {
      _showSnack(l10n.passwordMinLength, isError: true);
      return false;
    }

    return true;
  }

  Future<User> _createPendingExpertAccount() async {
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    final user = credential.user!;
    final fullName =
        "${nameController.text.trim()} ${surnameController.text.trim()}";

    await user.updateDisplayName(fullName);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'name': nameController.text.trim(),
      'surname': surnameController.text.trim(),
      'email': emailController.text.trim(),
      'role': 'expert_pending',
      'requestedRole': role,
      'expertApplicationStatus': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return user;
  }

  Future<void> _showRegisterSuccessDialog() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("İsteğiniz oluşturuldu"),
        content: const Text(
          "Uzman başvurunuz admin onayına gönderildi. Giriş yapabilirsiniz; onaylanana kadar başvuru beklemede ekranı gösterilecek.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Tamam"),
          ),
        ],
      ),
    );
  }

  String _submitErrorText(Object error) {
    if (error is FirebaseAuthException) {
      if (error.code == 'email-already-in-use') {
        return "Bu e-posta ile kayıtlı bir hesap var.";
      }
      if (error.code == 'invalid-email') {
        return "Geçerli bir e-posta adresi girin.";
      }
      if (error.code == 'weak-password') {
        return "Şifre daha güçlü olmalı.";
      }
    }

    return "Başvuru gönderilirken hata oluştu: $error";
  }

  void _showSnack(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError
            ? Colors.red
            : Theme.of(context).colorScheme.primary,
      ),
    );
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
                        if (widget.fromRegister) ...[
                          TextFormField(
                            controller: nameController,
                            decoration: buildInput(context, "İsim"),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? l10n.requiredField
                                    : null,
                          ),
                          TextFormField(
                            controller: surnameController,
                            decoration: buildInput(context, "Soy isim"),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? l10n.requiredField
                                    : null,
                          ),
                          TextFormField(
                            controller: emailController,
                            decoration: buildInput(context, l10n.emailField),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? l10n.requiredField
                                    : null,
                          ),
                          TextFormField(
                            controller: passwordController,
                            decoration: buildInput(context, l10n.password),
                            obscureText: true,
                            validator: (value) =>
                                value == null || value.length < 6
                                    ? l10n.passwordMinLength
                                    : null,
                          ),
                        ],
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
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
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
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
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
                                  widget.fromRegister
                                      ? "Kayıt ve Başvuru Oluştur"
                                      : l10n.submitApplication,
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
