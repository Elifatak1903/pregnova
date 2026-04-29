import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {

  String searchText = "";
  String roleFilter = "all";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Kullanıcılar"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),

      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Kullanıcı ara...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                filterBtn("all", "Tümü"),
                filterBtn("pregnant", "Hamile"),
                filterBtn("gynecologist", "Doktor"),
                filterBtn("dietitian", "Diyetisyen"),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs.where((doc) {

                  final data = doc.data() as Map<String, dynamic>;

                  if (roleFilter != "all" && data["role"] != roleFilter) {
                    return false;
                  }

                  final email = (data["email"] ?? "").toLowerCase();
                  final name = (data["name"] ?? "").toLowerCase();

                  return email.contains(searchText) ||
                      name.contains(searchText);

                }).toList();

                if (users.isEmpty) {
                  return const Center(child: Text("Kullanıcı bulunamadı"));
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {

                    final doc = users[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return userCard(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget userCard(String userId, Map<String, dynamic> data) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection("expert_applications")
          .where("uid", isEqualTo: userId)
          .get(),

      builder: (context, snapshot) {

        String status = "none";

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          status = snapshot.data!.docs.first["status"] ?? "pending";
        }

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      child: Text(
                        (data["name"] ?? "U")[0].toUpperCase(),
                      ),
                    ),
                    Chip(label: Text(getRoleText(data["role"]))),
                  ],
                ),

                const SizedBox(height: 10),

                Text(
                  data["name"] ?? "Kullanıcı",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                Text("📧 ${data["email"] ?? "-"}"),
                Text("📅 ${formatDate(data["createdAt"])}"),

                const SizedBox(height: 10),

                if (data["role"] != "pregnant")
                  Text(
                    "Durum: $status",
                    style: TextStyle(
                      color: status == "approved"
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [

                        /// APPROVE
                        if (status != "approved" && data["role"] != "pregnant")
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () async {

                              final snap = await FirebaseFirestore.instance
                                  .collection("expert_applications")
                                  .where("uid", isEqualTo: userId)
                                  .get();

                              if (snap.docs.isNotEmpty) {
                                await FirebaseFirestore.instance
                                    .collection("expert_applications")
                                    .doc(snap.docs.first.id)
                                    .update({"status": "approved"});
                              }

                              await FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(userId)
                                  .update({"isApproved": true});
                            },
                          ),

                        /// DELETE
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection("users")
                                .doc(userId)
                                .delete();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget filterBtn(String role, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            roleFilter = role;
          });
        },
        child: Text(text),
      ),
    );
  }

  String getRoleText(String? role) {
    if (role == "pregnant") return "Hamile";
    if (role == "dietitian") return "Diyetisyen";
    if (role == "gynecologist") return "Doktor";
    if (role == "admin") return "Admin";
    return role ?? "-";
  }

  String formatDate(dynamic timestamp) {
    if (timestamp == null) return "-";

    DateTime date;

    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else {
      date = DateTime.tryParse(timestamp.toString()) ?? DateTime.now();
    }

    return "${date.day}/${date.month}/${date.year}";
  }
}