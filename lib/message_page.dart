import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_page.dart';
import 'l10n/app_localizations.dart';

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

    final newChat = await FirebaseFirestore.instance.collection("chats").add({
      "users": [currentUserId, otherUserId],
      "lastMessage": "",
      "lastMessageTime": FieldValue.serverTimestamp(),
    });

    return newChat.id;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          final doctorId = data?["assignedDoctor"];
          final dietitianId = data?["assignedDietitian"];

          if (doctorId == null && dietitianId == null) {
            return Center(
              child: Text(
                l10n.noExpertYet,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.messages.toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (doctorId != null && doctorId.toString().isNotEmpty)
                _card(context, doctorId, l10n.doctor, "Dr."),
              if (dietitianId != null && dietitianId.toString().isNotEmpty)
                _card(context, dietitianId, l10n.dietitian, "Dyt."),
            ],
          );
        },
      ),
    );
  }

  Widget _card(
    BuildContext context,
    String otherUserId,
    String roleLabel,
    String prefix,
  ) {
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

            final chatData = chatSnap.data!.data() as Map<String, dynamic>?;

            final lastMessage = chatData?["lastMessage"] ?? "";
            final time = chatData?["lastMessageTime"];

            String timeText = "";
            if (time != null) {
              final date = (time as Timestamp).toDate();
              timeText =
                  "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
            }

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("users")
                  .doc(otherUserId)
                  .get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) {
                  return const SizedBox();
                }

                final userData = userSnap.data!.data() as Map<String, dynamic>?;
                final name = userData?["name"] ?? roleLabel;
                final title = "$prefix $name";

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      timeText,
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ChatPage(chatId: chatId, title: title),
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
    );
  }
}
