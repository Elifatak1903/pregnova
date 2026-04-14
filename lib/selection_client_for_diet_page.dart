import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'create_diet_page.dart';

class SelectClientForDietPage extends StatelessWidget {
  const SelectClientForDietPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text("Danışan Seç"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("expert_requests")
            .where("expertId", isEqualTo: uid)
            .where("status", isEqualTo: "approved")
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("Danışan bulunamadı"),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {

              final clientId = docs[index]["clientId"];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("users")
                    .doc(clientId)
                    .get(),
                builder: (context, userSnap) {

                  if (!userSnap.hasData) return const SizedBox();

                  final data = userSnap.data!.data() as Map<String, dynamic>;

                  final name = data["name"] ?? "";
                  final surname = data["surname"] ?? "";

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      title: Text("$name $surname"),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CreateDietPage(clientId: clientId),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}