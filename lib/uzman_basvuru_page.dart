import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UzmanBasvuruPage extends StatefulWidget {
  @override
  State<UzmanBasvuruPage> createState() => _UzmanBasvuruPageState();
}

class _UzmanBasvuruPageState extends State<UzmanBasvuruPage> {
  final _formKey = GlobalKey<FormState>();

  String role = 'dietitian';
  String licenseNo = '';
  String experience = '';

  Future<void> submitApplication() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('expert_applications').add({
      'uid': user.uid,
      'email': user.email,
      'role': role,
      'licenseNumber': licenseNo,
      'experience': experience,
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


    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Başvurun alındı 🙏")),
    );

    Navigator.pop(context);
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
        child: Form(
          key: _formKey,
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
                decoration: const InputDecoration(labelText: "Uzmanlık Alanı"),
              ),

              TextFormField(
                decoration:
                const InputDecoration(labelText: "Lisans / Sicil No"),
                onChanged: (v) => licenseNo = v,
                validator: (v) =>
                v!.isEmpty ? "Zorunlu alan" : null,
              ),

              TextFormField(
                decoration:
                const InputDecoration(labelText: "Deneyim (örn: 5 yıl)"),
                onChanged: (v) => experience = v,
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    submitApplication();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                ),
                child: const Text(
                  "Başvuruyu Gönder",
                  style: TextStyle(color: Colors.white),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
