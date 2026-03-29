import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';

class MessagePage extends StatelessWidget {
  const MessagePage({super.key});

  Future<String> getOrCreateChat(String otherUserId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final query = await FirebaseFirestore.instance
        .collection("chats")
        .where("users", arrayContains: currentUserId)
        .get();

    for (var doc in query.docs) {
      final users = List<String>.from(doc["users"]);
      if (users.contains(otherUserId)) {
        return doc.id;
      }
    }

    final newChat = await FirebaseFirestore.instance
        .collection("chats")
        .add({
      "users": [currentUserId, otherUserId],
      "lastMessage": "",
      "lastMessageTime": FieldValue.serverTimestamp(),
    });

    return newChat.id;
  }



  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          final doctorId = data?["assignedDoctor"];
          final dietitianId = data?["assignedDietitian"];

          print("UID: $uid");
          print("Doctor: $doctorId");

          if (doctorId == null && dietitianId == null) {
            return const Center(child: Text("Henüz uzman yok 😔"));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (doctorId != null && doctorId.toString().isNotEmpty)
                _card(context, doctorId, "Doktor"),

              if (dietitianId != null && dietitianId.toString().isNotEmpty)
                _card(context, dietitianId, "Diyetisyen"),
            ],
          );
        },
      ),
    );
  }

  Widget _card(BuildContext context, String otherUserId, String role) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder(
      future: getOrCreateChat(otherUserId),
      builder: (context, chatSnapshot) {

        if (!chatSnapshot.hasData) return const SizedBox();

        final chatId = chatSnapshot.data as String;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection("chats")
              .doc(chatId)
              .snapshots(),
          builder: (context, chatSnap) {

            if (!chatSnap.hasData) return const SizedBox();

            final chatData =
            chatSnap.data!.data() as Map<String, dynamic>?;

            final lastMessage = chatData?["lastMessage"] ?? "";
            final time = chatData?["lastMessageTime"];

            String timeText = "";
            if (time != null) {
              final date = (time as Timestamp).toDate();
              timeText =
              "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
            }

            // 🔥 USER ÇEK
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("users")
                  .doc(otherUserId)
                  .get(),
              builder: (context, userSnap) {

                if (!userSnap.hasData) {
                  return const ListTile(title: Text("Yükleniyor..."));
                }

                final userData =
                userSnap.data!.data() as Map<String, dynamic>?;

                final name = userData?["name"] ?? role;

                // 🔥 PREFIX
                String prefix = "";
                if (role == "Doktor") prefix = "Dr.";
                if (role == "Diyetisyen") prefix = "Dyt.";

                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.pink,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text("$prefix $name"),
                  subtitle: Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(timeText),

                      const SizedBox(height: 4),

                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("messages")
                            .where("chatId", isEqualTo: chatId)
                            .snapshots(),
                        builder: (context, snap) {

                          if (!snap.hasData) return const SizedBox();

                          final uid = FirebaseAuth.instance.currentUser!.uid;

                          final unreadCount = snap.data!.docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return data["isRead"] == false && data["senderId"] != uid;
                          }).length;

                          if (unreadCount == 0) return const SizedBox();

                          return Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          chatId: chatId,
                          title: "$prefix $name",
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
  }
}