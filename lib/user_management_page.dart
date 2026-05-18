import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'language_selector.dart';
import 'l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.users),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: const [LanguageActionButton()],
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
                hintText: l10n.searchUser,
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
                filterBtn("all", l10n.all),
                filterBtn("pregnant", l10n.pregnantRole),
                filterBtn("gynecologist", l10n.doctorRole),
                filterBtn("dietitian", l10n.dietitian),
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
                  return Center(child: Text(l10n.userNotFound));
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
    final l10n = AppLocalizations.of(context)!;

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

        final displayName = data["name"] ?? l10n.userFallback;

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
                      child: Text(displayName.toString()[0].toUpperCase()),
                    ),
                    Chip(label: Text(getRoleText(data["role"]))),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("${l10n.email}: ${data["email"] ?? "-"}"),
                Text("${l10n.createdAt}: ${formatDate(data["createdAt"])}"),
                const SizedBox(height: 10),
                if (data["role"] != "pregnant")
                  Text(
                    "${l10n.status}: ${getStatusText(status)}",
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
    final l10n = AppLocalizations.of(context)!;

    if (role == "pregnant") return l10n.pregnantRole;
    if (role == "dietitian") return l10n.dietitian;
    if (role == "gynecologist") return l10n.doctorRole;
    if (role == "admin") return l10n.adminPanel;
    return role ?? "-";
  }

  String getStatusText(String? status) {
    final l10n = AppLocalizations.of(context)!;

    if (status == "approved") return l10n.approvedStatus;
    if (status == "rejected") return l10n.rejectedStatus;
    if (status == "pending") return l10n.pendingStatus;
    return "-";
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
