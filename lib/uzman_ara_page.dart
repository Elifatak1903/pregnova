import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UzmanAraPage extends StatefulWidget {
  const UzmanAraPage({super.key});

  @override
  State<UzmanAraPage> createState() => _UzmanAraPageState();
}

class _UzmanAraPageState extends State<UzmanAraPage> {
  String selectedRole = 'all';
  late Stream<QuerySnapshot> expertsStream;

  @override
  void initState() {
    super.initState();
    expertsStream = _createStream();
  }

  Stream<QuerySnapshot> _createStream() {
    final ref = FirebaseFirestore.instance.collection('users');

    if (selectedRole == 'dietitian') {
      return ref.where('role', isEqualTo: 'dietitian').snapshots();
    }

    if (selectedRole == 'gynecologist') {
      return ref.where('role', isEqualTo: 'gynecologist').snapshots();
    }

    return ref
        .where('role', whereIn: ['dietitian', 'gynecologist'])
        .snapshots();
  }

  void _updateFilter(String value) {
    setState(() {
      selectedRole = value;
      expertsStream = _createStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "Uzman Ara 🔍",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _filterChip("Tümü", "all"),
                    _filterChip("Diyetisyen", "dietitian"),
                    _filterChip("Jinekolog", "gynecologist"),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: expertsStream,
                  builder: (context, snapshot) {

                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text("Bir hata oluştu 😢"),
                      );
                    }

                    if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "Uygun uzman bulunamadı 😔",
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }

                    final experts = snapshot.data!.docs;

                    return ListView.builder(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: experts.length,
                      itemBuilder: (context, index) {

                        final doc = experts[index];
                        final role = doc['role'] ?? '';

                        return Card(
                          elevation: 6,
                          margin: const EdgeInsets.symmetric(
                              vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(18),
                          ),
                          child: ListTile(
                            contentPadding:
                            const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              radius: 26,
                              backgroundColor:
                              role == 'dietitian'
                                  ? Colors.green
                                  : Colors.teal,
                              child: const Icon(
                                Icons.medical_services,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              doc['email'] ?? "Uzman",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              role == 'dietitian'
                                  ? "Diyetisyen"
                                  : "Jinekolog",
                            ),
                            trailing: ElevatedButton(
                              onPressed: () async {

                                final currentUserId =
                                    FirebaseAuth.instance.currentUser!.uid;

                                await FirebaseFirestore.instance
                                    .collection("expert_requests")
                                    .add({
                                  "clientId": currentUserId,
                                  "expertId": doc.id, // uzman uid
                                  "status": "pending",
                                  "createdAt": FieldValue.serverTimestamp(),
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("İstek gönderildi ✅"),
                                  ),
                                );
                              },
                              child: const Text("Danışan Olmak İstiyorum"),
                            ),
                          ),
                        );
                      },
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

  Widget _filterChip(String label, String value) {
    final isSelected = selectedRole == value;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.pink,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
      onSelected: (_) => _updateFilter(value),
    );
  }
}