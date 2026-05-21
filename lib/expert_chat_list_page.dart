import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_page.dart';
import 'l10n/app_localizations.dart';

class ExpertChatListPage extends StatelessWidget {
  const ExpertChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.messages),
        backgroundColor: Theme.of(context).colorScheme.primary,
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

          final chats = snapshot.data?.docs ?? [];

          return FutureBuilder<List<_ExpertChatItem>>(
            future: _mergeChatsWithAssignedClients(uid, chats),
            builder: (context, mergedSnap) {
              if (mergedSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final mergedChats = mergedSnap.data ?? [];

              if (mergedChats.isEmpty) {
                return Center(
                  child: Text(
                    l10n.noMessagesYet,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: mergedChats.length,
                itemBuilder: (context, index) {
                  final chat = mergedChats[index];
                  final data = chat.data;
                  final otherUserId = chat.otherUserId;

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection("users")
                        .doc(otherUserId)
                        .get(),
                    builder: (context, userSnap) {
                      if (userSnap.connectionState == ConnectionState.waiting) {
                        return ListTile(
                          title: Text(
                            l10n.loading,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        );
                      }

                      if (!userSnap.hasData || userSnap.data!.data() == null) {
                        return ListTile(title: Text(l10n.userNotFound));
                      }

                      final userData =
                          userSnap.data!.data() as Map<String, dynamic>;
                      final name = userData["name"] ?? "";
                      final surname = userData["surname"] ?? "";
                      final timeText = _formatTime(data["lastMessageTime"]);

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("messages")
                            .where("chatId", isEqualTo: chat.chatId)
                            .snapshots(),
                        builder: (context, msgSnap) {
                          int unreadCount = 0;

                          if (msgSnap.hasData) {
                            unreadCount = msgSnap.data!.docs.where((doc) {
                              final d = doc.data() as Map<String, dynamic>;
                              return d["isRead"] == false &&
                                  d["senderId"] != uid;
                            }).length;
                          }

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              child: Icon(
                                Icons.person,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            title: Text(
                              "$name $surname",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              data["lastMessage"] ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  timeText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                if (unreadCount > 0)
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      unreadCount.toString(),
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimary,
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
                                    chatId: chat.chatId,
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
          );
        },
      ),
    );
  }

  Future<List<_ExpertChatItem>> _mergeChatsWithAssignedClients(
    String uid,
    List<QueryDocumentSnapshot<Object?>> chatDocs,
  ) async {
    final items = <_ExpertChatItem>[];
    final existingOtherUsers = <String>{};

    for (final doc in chatDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final users = List<String>.from(data["users"] ?? []);
      String? otherUserId;
      for (final userId in users) {
        if (userId != uid) {
          otherUserId = userId;
          break;
        }
      }

      if (otherUserId == null) {
        continue;
      }

      existingOtherUsers.add(otherUserId);
      items.add(
        _ExpertChatItem(
          chatId: doc.id,
          otherUserId: otherUserId,
          data: data,
        ),
      );
    }

    final currentUser = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();
    final role = (currentUser.data()?["role"] ?? "").toString();
    final assignedField = role == "dietitian"
        ? "assignedDietitian"
        : "assignedDoctor";

    final assignedClients = await FirebaseFirestore.instance
        .collection("users")
        .where(assignedField, isEqualTo: uid)
        .get();

    for (final client in assignedClients.docs) {
      if (existingOtherUsers.contains(client.id)) continue;

      final chatId = await _getOrCreateChat(uid, client.id);
      existingOtherUsers.add(client.id);
      items.add(
        _ExpertChatItem(
          chatId: chatId,
          otherUserId: client.id,
          data: const {
            "lastMessage": "",
            "lastMessageTime": null,
          },
        ),
      );
    }

    return items;
  }

  Future<String> _getOrCreateChat(String expertId, String clientId) async {
    final existing = await FirebaseFirestore.instance
        .collection("chats")
        .where("users", arrayContains: expertId)
        .get();

    for (final doc in existing.docs) {
      final users = List<String>.from(doc.data()["users"] ?? []);
      if (users.contains(clientId)) return doc.id;
    }

    final created = await FirebaseFirestore.instance.collection("chats").add({
      "users": [expertId, clientId],
      "lastMessage": "",
      "lastMessageTime": FieldValue.serverTimestamp(),
    });

    return created.id;
  }

  String _formatTime(dynamic raw) {
    if (raw is! Timestamp) return "";
    final date = raw.toDate();
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
}

class _ExpertChatItem {
  final String chatId;
  final String otherUserId;
  final Map<String, dynamic> data;

  const _ExpertChatItem({
    required this.chatId,
    required this.otherUserId,
    required this.data,
  });
}
