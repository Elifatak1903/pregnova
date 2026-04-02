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

    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: const Text("Bildirimler"),
        centerTitle: true,
      ),
      body: uid == null
          ? Center(
        child: Text(
          "Bildirimleri görmek için giriş yapmalısın",
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 16,
          ),
        ),
      )
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notification')
            .where('uid', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "Henüz bildirim yok 💕",
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
              final data = doc.data() as Map<String, dynamic>;

              final isRead = data['isRead'] ?? false;
              final type = data['type'] ?? "general";
              final title = data['title'] ?? "";
              final message = data['message'] ?? "";

              final createdAt = data['createdAt'] as Timestamp?;
              final timeText = timeAgo(createdAt);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isRead ? Colors.white : Colors.pink.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isRead
                        ? Colors.grey.shade300
                        : Colors.pink.shade300,
                  ),
                ),
                child: ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.pink,
                        child: Icon(
                          type == "risk_alert"
                              ? Icons.warning
                              : Icons.notifications,
                          color: Colors.white,
                        ),
                      ),
                      if (!isRead)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                      color: Colors.pink.shade800,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                  ),
                  onTap: () async {
                    if (!isRead) {
                      await doc.reference.update({'isRead': true});
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
