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
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: const Text("Mesajlar"),
      ),
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
              if (doctorId != null)
                _card(context, doctorId, "Doktor"),

              if (dietitianId != null)
                _card(context, dietitianId, "Diyetisyen"),
            ],
          );;
        },
      ),
    );
  }

  Widget _card(BuildContext context, String otherUserId, String title) {
    return FutureBuilder(
      future: getOrCreateChat(otherUserId),
      builder: (context, snapshot) {

        if (!snapshot.hasData) return const SizedBox();

        final chatId = snapshot.data as String;

        return ListTile(
          title: Text(title),
          leading: const Icon(Icons.person),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatPage(
                  chatId: chatId,
                  title: title,
                ),
              ),
            );
          },
        );
      },
    );
  }
}