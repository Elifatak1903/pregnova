import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String title;

  const ChatPage({super.key, required this.chatId, required this.title});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final controller = TextEditingController();

  Future<void> sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection("messages").add({
      "chatId": widget.chatId,
      "senderId": uid,
      "text": text,
      "createdAt": FieldValue.serverTimestamp(),
      "isRead": false,
    });

    await FirebaseFirestore.instance
        .collection("chats")
        .doc(widget.chatId)
        .update({
      "lastMessage": text,
      "lastMessageTime": FieldValue.serverTimestamp(),
    });

    controller.clear();
  }
  Future<void> markMessagesAsRead() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final query = await FirebaseFirestore.instance
        .collection("messages")
        .where("chatId", isEqualTo: widget.chatId)
        .where("senderId", isNotEqualTo: uid)
        .where("isRead", isEqualTo: false)
        .get();

    for (var doc in query.docs) {
      doc.reference.update({"isRead": true});
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: Text(widget.title),
      ),
      body: Column(
        children: [

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("messages")
                  .where("chatId", isEqualTo: widget.chatId)
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {

                    final data =
                    messages[index].data() as Map<String, dynamic>;

                    final isMe = data["senderId"] == uid;

                    return Align(
                      alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.pink : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          data["text"] ?? "",
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: "Mesaj yaz...",
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.pink),
                onPressed: sendMessage,
              )
            ],
          )
        ],
      ),
    );
  }
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      markMessagesAsRead();
    });
  }
}