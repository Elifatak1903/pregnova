import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UzmanBasvuruPage extends StatefulWidget {
  const UzmanBasvuruPage({Key? key}) : super(key: key);

  @override
  State<UzmanBasvuruPage> createState() => _UzmanBasvuruPageState();
}

class _UzmanBasvuruPageState extends State<UzmanBasvuruPage> {
  PlatformFile? selectedFile;
  String? documentUrl;
  final _formKey = GlobalKey<FormState>();

  String role = 'dietitian';
  String licenseNo = '';
  String experience = '';
  String phone = '';
  String hospital = '';
  String city = '';

  bool isLoading = false;
  String applicationStatus = 'none'; // none, pending, approved, rejected

  @override
  void initState() {
    super.initState();
    checkApplicationStatus();
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        selectedFile = result.files.first;
      });
    }
  }

  Future<String?> uploadFile() async {
    if (selectedFile == null) return null;

    final file = selectedFile!;
    final path = 'expert_documents/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

    final ref = FirebaseStorage.instance.ref().child(path);

    await ref.putData(file.bytes!);

    final url = await ref.getDownloadURL();
    return url;
  }


  Future<void> checkApplicationStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('expert_applications')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        applicationStatus = snapshot.docs.first['status'];
      });
    }
  }

  Future<void> submitApplication() async {
    if (isLoading) return;
    if (selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen belge yükleyin 📄"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);

    // 📄 belge upload
    final uploadedUrl = await uploadFile();

    await FirebaseFirestore.instance.collection('expert_applications').add({
      'uid': user.uid,
      'email': user.email,
      'fullName': user.displayName ?? '',
      'role': role,
      'licenseNumber': licenseNo,
      'experience': experience,
      'phone': phone,
      'hospital': hospital,
      'city': city,
      'documentUrl': uploadedUrl, // 💥 EKLENDİ
      'status': 'pending',
      'createdAt': Timestamp.now(),
    });

    await FirebaseFirestore.instance.collection('notification').add({
      'uid': user.uid,
      'title': 'Uzman Başvurusu Alındı',
      'message': 'Başvurun alındı. Admin onayı bekleniyor ⏳',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Başvurun alındı 🙏")),
    );

    Navigator.pop(context);
  }

  Widget buildStatusView() {
    if (applicationStatus == 'pending') {
      return const Center(
        child: Text(
          "⏳ Başvurunuz inceleniyor...",
          style: TextStyle(fontSize: 18, color: Colors.orange),
        ),
      );
    }

    if (applicationStatus == 'approved') {
      return const Center(
        child: Text(
          "✅ Zaten uzmansınız!",
          style: TextStyle(fontSize: 18, color: Colors.green),
        ),
      );
    }

    if (applicationStatus == 'rejected') {
      return const Center(
        child: Text(
          "❌ Başvurunuz reddedildi. Tekrar deneyebilirsiniz.",
          style: TextStyle(fontSize: 18, color: Colors.red),
        ),
      );
    }

    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        title: const Text("Uzman Başvurusu"),
        backgroundColor: Colors.pink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: applicationStatus != 'none'
            ? buildStatusView()
            : Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField(
                  value: role,
                  items: const [
                    DropdownMenuItem(
                      value: 'dietitian',
                      child: Text("Diyetisyen"),
                    ),
                    DropdownMenuItem(
                      value: 'gynecologist',
                      child: Text("Jinekolog"),
                    ),
                  ],
                  onChanged: (val) => setState(() => role = val!),
                  decoration:
                  const InputDecoration(labelText: "Uzmanlık Alanı"),
                ),

                TextFormField(
                  decoration: const InputDecoration(
                      labelText: "Lisans / Sicil No"),
                  onChanged: (v) => licenseNo = v,
                  validator: (v) =>
                  v!.isEmpty ? "Zorunlu alan" : null,
                ),

                TextFormField(
                  decoration:
                  const InputDecoration(labelText: "Deneyim"),
                  onChanged: (v) => experience = v,
                ),

                TextFormField(
                  decoration:
                  const InputDecoration(labelText: "Telefon"),
                  keyboardType: TextInputType.phone,
                  onChanged: (v) => phone = v,
                ),

                TextFormField(
                  decoration:
                  const InputDecoration(labelText: "Çalıştığı Kurum"),
                  onChanged: (v) => hospital = v,
                ),

                TextFormField(
                  decoration:
                  const InputDecoration(labelText: "Şehir"),
                  onChanged: (v) => city = v,
                ),

                const SizedBox(height: 30),

                ElevatedButton.icon(
                  onPressed: pickFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Belge Yükle"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                  ),
                ),

                const SizedBox(height: 10),

                if (selectedFile != null)
                  Text(
                    "Seçilen dosya: ${selectedFile!.name}",
                    style: const TextStyle(color: Colors.green),
                  ),

                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      submitApplication();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 40),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                      : const Text(
                    "Başvuruyu Gönder",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}