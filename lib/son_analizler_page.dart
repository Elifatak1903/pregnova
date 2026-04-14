import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'client_detail_page.dart';

class SonAnalizlerPage extends StatelessWidget {
  const SonAnalizlerPage({super.key});

  @override
  Widget build(BuildContext context) {

    final sevenDaysAgo =
    DateTime.now().subtract(const Duration(days: 7));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Son Analizler"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("besin_analizleri")
            .where("tarih", isGreaterThan: sevenDaysAgo)
            .orderBy("tarih", descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("Son 7 günde analiz yok"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {

              final data =
              docs[index].data() as Map<String, dynamic>;

              final patientId = data["uid"];
              final tarih = data["tarih"] as Timestamp?;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("users")
                    .doc(patientId)
                    .get(),
                builder: (context, userSnap) {

                  if (!userSnap.hasData) {
                    return const SizedBox();
                  }

                  final userData =
                  userSnap.data!.data() as Map<String, dynamic>?;

                  final name = userData?["name"] ?? "";
                  final surname = userData?["surname"] ?? "";

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.restaurant, color: Colors.white),
                      ),

                      title: Text("$name $surname"),

                      subtitle: Text(
                        tarih != null ? _timeAgo(tarih) : "",
                      ),

                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClientDetailPage(
                              clientId: patientId,
                            ),
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

  String _timeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return "${diff.inSeconds} sn önce";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes} dk önce";
    } else if (diff.inHours < 24) {
      return "${diff.inHours} saat önce";
    } else {
      return "${diff.inDays} gün önce";
    }
  }
}