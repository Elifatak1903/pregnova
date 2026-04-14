import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

String timeAgo(Timestamp? timestamp) {
  if (timestamp == null) return "";

  final now = DateTime.now();
  final date = timestamp.toDate();
  final diff = now.difference(date);

  if (diff.inSeconds < 60) return "Az önce";
  if (diff.inMinutes < 60) return "${diff.inMinutes} dk önce";
  if (diff.inHours < 24) return "${diff.inHours} saat önce";
  if (diff.inDays < 7) return "${diff.inDays} gün önce";

  return "${date.day}.${date.month}.${date.year}";
}

class NotificationPanel extends StatelessWidget {
  const NotificationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Giriş yapılmamış")),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get(),
      builder: (context, userSnap) {

        if (!userSnap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData =
        userSnap.data!.data() as Map<String, dynamic>?;

        final role = userData?["role"] ?? "pregnant";

        final primaryColor =
        role == "dietitian" ? Colors.green : Colors.pink;

        final backgroundColor =
        role == "dietitian"
            ? Colors.green.shade50
            : Colors.pink.shade50;

        return Scaffold(
          backgroundColor: backgroundColor,

          appBar: AppBar(
            backgroundColor: primaryColor,
            title: const Text(
              "Bildirimler",
              style: TextStyle(color: Colors.white),
            ),
            centerTitle: true,
          ),

          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notification')
                .where('uid', isEqualTo: uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {

              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              if (!snapshot.hasData ||
                  snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    "Henüz bildirim yok",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {

                  final doc = docs[index];
                  final data =
                  doc.data() as Map<String, dynamic>;

                  final isRead = data['isRead'] ?? false;
                  final type = data['type'] ?? "general";
                  final title = data['title'] ?? "";
                  final message = data['message'] ?? "";

                  final createdAt =
                  data['createdAt'] as Timestamp?;
                  final timeText = timeAgo(createdAt);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isRead
                          ? Colors.white
                          : primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isRead
                            ? Colors.grey.shade300
                            : primaryColor,
                      ),
                    ),
                    child: ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: primaryColor,
                            child: Icon(
                              type == "risk_alert"
                                  ? Icons.warning
                                  : Icons.notifications,
                              color: Colors.white,
                            ),
                          ),
                          if (!isRead)
                            const Positioned(
                              right: 0,
                              top: 0,
                              child: CircleAvatar(
                                radius: 5,
                                backgroundColor: Colors.black,
                              ),
                            ),
                        ],
                      ),

                      title: Text(
                        title,
                        style: TextStyle(
                          fontWeight: isRead
                              ? FontWeight.w500
                              : FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),

                      subtitle: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            message,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),

                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),

                      onTap: () async {
                        if (!isRead) {
                          await doc.reference
                              .update({'isRead': true});
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}