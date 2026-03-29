import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'kisisel_bilgi_page.dart';

class KisiselBilgilerGoruntulePage extends StatelessWidget {
  const KisiselBilgilerGoruntulePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kişisel Bilgiler"),
        backgroundColor: Colors.pink,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.centerLeft,
                child: const Text(
                  "Kişisel Bilgiler",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
              ),

              Expanded(
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .get(),
                  builder: (context, snapshot) {

                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    final data =
                    snapshot.data!.data() as Map<String, dynamic>?;

                    if (data == null) {
                      return const Center(
                          child: Text("Veri bulunamadı"));
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [

                          bilgiKart(
                            "Kronik Hipertansiyon",
                            (data['chronicHypertension'] ?? false) ? "Var" : "Yok",
                            Icons.monitor_heart,
                          ),

                          bilgiKart(
                            "Diyabet",
                            (data['diabetes'] ?? false) ? "Var" : "Yok",
                            Icons.bloodtype,
                          ),

                          bilgiKart(
                            "Tiroid Hastalığı",
                            (data['thyroidDisease'] ?? false) ? "Var" : "Yok",
                            Icons.health_and_safety,
                          ),

                          bilgiKart(
                            "Önceki Preterm",
                            (data['previousPreterm'] ?? false) ? "Var" : "Yok",
                            Icons.warning,
                          ),

                          bilgiKart(
                            "Çoğul Gebelik",
                            (data['multiplePregnancy'] ?? false) ? "Var" : "Yok",
                            Icons.groups,
                          ),

                          bilgiKart(
                            "Sigara",
                            (data['smoker'] ?? false) ? "Var" : "Yok",
                            Icons.smoking_rooms,
                          ),

                          const Spacer(),

                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const KisiselBilgilerPage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              child: const Text(
                                "Bilgileri Düzenle",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget bilgiKart(String title, String value, IconData icon) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.pink.shade100,
          child: Icon(icon, color: Colors.pink),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          value.isEmpty ? "Belirtilmemiş" : value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}