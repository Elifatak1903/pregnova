import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_page.dart';

class ExpertChatListPage extends StatelessWidget {
  const ExpertChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mesajlar"),
        backgroundColor: Colors.pink,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("chats")
            .where("users", arrayContains: uid)
            .orderBy("lastMessageTime", descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Henüz mesaj yok"));
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {

              final data =
              chats[index].data() as Map<String, dynamic>;

              final users = List<String>.from(data["users"]);

              final otherUserId =
              users.firstWhere((u) => u != uid);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("users")
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnap) {

                  /// 🔄 USER LOADING
                  if (userSnap.connectionState ==
                      ConnectionState.waiting) {
                    return const ListTile(
                        title: Text("Yükleniyor..."));
                  }

                  /// ❌ USER YOK
                  if (!userSnap.hasData ||
                      userSnap.data!.data() == null) {
                    return const ListTile(
                        title: Text("Kullanıcı bulunamadı"));
                  }

                  final userData =
                  userSnap.data!.data()
                  as Map<String, dynamic>;

                  final name = userData["name"] ?? "";
                  final surname = userData["surname"] ?? "";

                  String timeText = "";
                  if (data["lastMessageTime"] != null) {
                    final date =
                    (data["lastMessageTime"] as Timestamp)
                        .toDate();
                    timeText =
                    "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("messages")
                        .where("chatId", isEqualTo: chats[index].id)
                        .snapshots(),

                    builder: (context, msgSnap) {

                      int unreadCount = 0;

                      if (msgSnap.hasData) {
                        unreadCount = msgSnap.data!.docs.where((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          return d["isRead"] == false && d["senderId"] != uid;
                        }).length;
                      }

                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.pink,
                          child: Icon(Icons.person, color: Colors.white),
                        ),

                        title: Text(
                          "$name $surname",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        subtitle: Text(
                          data["lastMessage"] ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            /// ⏰ saat
                            Text(
                              timeText,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),

                            const SizedBox(height: 5),

                            /// 🔴 BADGE
                            if (unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatPage(
                                chatId: chats[index].id,
                                title: "$name $surname",
                              ),
                            ),
                          );
                        },
                      );
                    },
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