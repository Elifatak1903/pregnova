import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'client_detail_page.dart';
import 'expert_chat_list_page.dart';
import 'notification_page.dart';
import 'son_analizler_page.dart';
import 'sifre_degistir_page.dart';
import 'selection_client_for_diet_page.dart';
import 'edit_dietitian_profile_page.dart';
import 'language_selector.dart';
import 'l10n/app_localizations.dart';

class DietitianHomePage extends StatefulWidget {
  const DietitianHomePage({super.key});

  @override
  State<DietitianHomePage> createState() => _DietitianHomePageState();
}

class _DietitianHomePageState extends State<DietitianHomePage> {
  int _selectedIndex = 0;
  late final String uid;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser!.uid;
  }

  Future<void> _getOrCreateChat(String expertId, String clientId) async {
    final existing = await FirebaseFirestore.instance
        .collection("chats")
        .where("users", arrayContains: expertId)
        .get();

    for (final doc in existing.docs) {
      final users = List<String>.from(doc.data()["users"] ?? []);
      if (users.contains(clientId)) return;
    }

    await FirebaseFirestore.instance.collection("chats").add({
      "users": [expertId, clientId],
      "lastMessage": "",
      "lastMessageTime": FieldValue.serverTimestamp(),
    });
  }

  Future<int> getApprovedCount() async {
    final query = await FirebaseFirestore.instance
        .collection("expert_requests")
        .where("expertId", isEqualTo: uid)
        .where("status", isEqualTo: "approved")
        .get();
    return query.docs.length;
  }

  Future<int> getPendingCount() async {
    final query = await FirebaseFirestore.instance
        .collection("expert_requests")
        .where("expertId", isEqualTo: uid)
        .where("status", isEqualTo: "pending")
        .get();
    return query.docs.length;
  }

  Future<int> getActiveThisWeek() async {
    final sevenDaysAgo = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 7)),
    );

    final query = await FirebaseFirestore.instance
        .collection("besin_analizleri")
        .where("createdAt", isGreaterThan: sevenDaysAgo)
        .get();

    return query.docs.length;
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return _buildClientsPage();
      case 2:
        return _buildRequestsPage();
      case 3:
        return _buildMessagesPage();
      case 4:
        return _buildAccountPage();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildRequestsPage() {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("expert_requests")
          .where("expertId", isEqualTo: uid)
          .where("status", isEqualTo: "pending")
          .snapshots(includeMetadataChanges: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return Center(child: Text(l10n.noData));
        }

        if (snapshot.data!.metadata.isFromCache) {
          return const SizedBox();
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(child: Text(l10n.noPendingRequests));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final clientId = doc["clientId"];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("users")
                  .doc(clientId)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(10),
                    child: LinearProgressIndicator(),
                  );
                }

                final userData =
                    userSnapshot.data?.data() as Map<String, dynamic>? ?? {};

                final name = userData["name"] ?? "";
                final surname = userData["surname"] ?? "";
                final hafta = userData["hafta"] ?? "-";
                final email = userData["email"] ?? "-";
                final phone = userData["phone"] ?? "-";
                final boy = userData["boy"] ?? "-";
                final kilo = userData["kilo"] ?? "-";
                final bmi = userData["bmi"] ?? userData["BMI"] ?? "-";
                final allergy =
                    userData["allergy"] ?? userData["alerji"] ?? "-";
                final risk = userData["riskLevel"] ?? "-";

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),

                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),

                    title: Text(
                      "$name $surname",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${l10n.patientId}: $clientId"),
                          Text("${l10n.requestId}: ${doc.id}"),
                          const SizedBox(height: 6),
                          Text("${l10n.email}: $email"),
                          Text("${l10n.phone}: $phone"),
                          Text("${l10n.pregnancyWeekInput}: $hafta"),
                          Text("${l10n.heightWeight}: $boy cm / $kilo kg"),
                          Text("${l10n.bmi}: $bmi"),
                          Text("${l10n.risk}: ${_riskText(risk)}"),
                          Text("${l10n.allergy}: $allergy"),
                        ],
                      ),
                    ),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () async {
                            await doc.reference.update({
                              'status': 'rejected',
                              'rejectedAt': FieldValue.serverTimestamp(),
                            });

                            await FirebaseFirestore.instance
                                .collection("notification")
                                .add({
                                  'uid': clientId,
                                  'type': 'expert_request',
                                  'title': 'İstek Reddedildi',
                                  'message':
                                      'Gönderdiğiniz diyetisyen isteği reddedildi.',
                                  'isRead': false,
                                  'createdAt': FieldValue.serverTimestamp(),
                                });
                          },
                        ),

                        IconButton(
                          icon: Icon(
                            Icons.check,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () async {
                            await doc.reference.update({
                              'status': 'approved',
                              'approvedAt': FieldValue.serverTimestamp(),
                            });

                            await FirebaseFirestore.instance
                                .collection("users")
                                .doc(clientId)
                                .set({
                                  'assignedDietitian': uid,
                                }, SetOptions(merge: true));

                            await _getOrCreateChat(uid, clientId);

                            await FirebaseFirestore.instance
                                .collection("notification")
                                .add({
                                  'uid': clientId,
                                  'type': 'expert_request',
                                  'title': 'Diyetisyen Onayı',
                                  'message':
                                      'Diyetisyeniniz sizi danışan olarak kabul etti.',
                                  'isRead': false,
                                  'createdAt': FieldValue.serverTimestamp(),
                                });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRecentActivity() {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("besin_analizleri")
          .where("dietitianId", isEqualTo: uid)
          .orderBy("createdAt", descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text(l10n.noActivityYet);
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            final createdAt = data["createdAt"];
            final patientId = data["uid"];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("users")
                  .doc(patientId)
                  .get(),
              builder: (context, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting) {
                  return const SizedBox();
                }

                final userData =
                    userSnap.data?.data() as Map<String, dynamic>? ?? {};

                final name = userData["name"] ?? "";
                final surname = userData["surname"] ?? "";

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SonAnalizlerPage(
                          selectedUid: patientId,
                          selectedTarih: createdAt is Timestamp
                              ? createdAt
                              : null,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).shadowColor.withValues(alpha: 0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.restaurant,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.newAnalysisSent("$name $surname"),
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 4),

                              Text(
                                formatDate(createdAt, l10n),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHomePage() {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dietitianPanel,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 25),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.9,
            children: [
              FutureBuilder<int>(
                future: getApprovedCount(),
                builder: (context, snapshot) {
                  return _statCard(
                    l10n.clients,
                    snapshot.data?.toString() ?? "...",
                    Icons.people,
                    () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                  );
                },
              ),

              FutureBuilder<int>(
                future: getPendingCount(),
                builder: (context, snapshot) {
                  return _statCard(
                    l10n.pendingRequest,
                    snapshot.data?.toString() ?? "...",
                    Icons.pending,
                    () {
                      setState(() {
                        _selectedIndex = 2;
                      });
                    },
                  );
                },
              ),

              FutureBuilder<int>(
                future: getActiveThisWeek(),
                builder: (context, snapshot) {
                  return _statCard(
                    l10n.activeLast7Days,
                    snapshot.data?.toString() ?? "...",
                    Icons.timeline,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SonAnalizlerPage(),
                        ),
                      );
                    },
                  );
                },
              ),
              _statCard(l10n.nutritionModule, l10n.open, Icons.restaurant, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SelectClientForDietPage(),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 30),

          Text(
            "Son Aktiviteler",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          const SizedBox(height: 15),

          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildClientsPage() {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("expert_requests")
          .where("expertId", isEqualTo: uid)
          .where("status", isEqualTo: "approved")
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(child: Text(l10n.noClientsYet));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final clientId = docs[index]["clientId"];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("users")
                  .doc(clientId)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const SizedBox();
                }

                final data = userSnapshot.data!.data() as Map<String, dynamic>?;

                final name = data?["name"] ?? "";
                final surname = data?["surname"] ?? "";
                final hafta = data?["hafta"] ?? "-";

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),

                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),

                    title: Text(
                      "$name $surname",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    subtitle: Text("${l10n.pregnancyWeekInput}: $hafta"),

                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClientDetailPage(clientId: clientId),
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

  Widget _buildMessagesPage() {
    return const ExpertChatListPage();
  }

  Widget _buildAccountPage() {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final diplomaUrl = data?["diplomaUrl"] ?? data?["diploma"];

        final name = data?["name"] ?? "";
        final email = user.email ?? "";

        final expertise = data?["expertise"] ?? "-";
        final experience = data?["experience"] ?? "-";
        final institution = data?["institution"] ?? "-";

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).shadowColor.withValues(alpha: 0.2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.surface,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(email),
                        Text(
                          l10n.dietitian,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditDietitianProfilePage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(l10n.editInfo),
              ),

              const SizedBox(height: 25),

              Text(
                l10n.expertiseInfo,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 10),

              _infoCard(l10n.expertiseArea, expertise),
              _infoCard(l10n.experience, experience),
              _infoCard(l10n.institution, institution),

              const SizedBox(height: 25),

              _accountTile(Icons.description, l10n.diplomaDocuments, () {
                if (diplomaUrl != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(
                          title: const Text("Diploma"),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                        ),
                        body: Center(child: Image.network(diplomaUrl)),
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.noDiplomaAdded)));
                }
              }),
              if (diplomaUrl != null)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: 8),
                      Text(l10n.diplomaUploaded),
                    ],
                  ),
                ),

              const SizedBox(height: 25),

              Text(
                l10n.settings,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 10),

              _accountTile(Icons.lock, l10n.changePassword, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SifreDegistirPage()),
                );
              }),

              _accountTile(
                Icons.language,
                l10n.language,
                () => showLanguageDialog(context),
              ),

              _accountTile(Icons.logout, l10n.logoutAction, () async {
                await FirebaseAuth.instance.signOut();

                if (!context.mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }, color: Colors.red),
            ],
          ),
        );
      },
    );
  }

  Widget _infoCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(title: Text(title), subtitle: Text(value)),
    );
  }

  Widget _accountTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color color = Colors.black,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 26),

            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            Text(title),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,

      appBar: AppBar(
        title: const Text("PregNova"),
        backgroundColor: Theme.of(context).colorScheme.primary,

        actions: [
          const LanguageActionButton(),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("notification")
                .where("uid", isEqualTo: uid)
                .where("isRead", isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              bool hasNotif =
                  snapshot.hasData && snapshot.data!.docs.isNotEmpty;

              return Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationPanel(),
                        ),
                      );
                    },
                  ),

                  if (hasNotif)
                    const Positioned(
                      right: 10,
                      top: 10,
                      child: CircleAvatar(
                        radius: 5,
                        backgroundColor: Colors.red,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),

      body: _buildBody(),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: l10n.home,
          ),

          BottomNavigationBarItem(
            icon: const Icon(Icons.people),
            label: l10n.clients,
          ),

          BottomNavigationBarItem(
            icon: const Icon(Icons.pending),
            label: l10n.requests,
          ),

          BottomNavigationBarItem(
            icon: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("messages")
                  .snapshots(),
              builder: (context, snapshot) {
                int unreadCount = 0;

                if (snapshot.hasData) {
                  unreadCount = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data["isRead"] == false && data["receiverId"] == uid;
                  }).length;
                }

                return Stack(
                  children: [
                    const Icon(Icons.message),

                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 99 ? "99+" : unreadCount.toString(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: l10n.messages,
          ),

          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: l10n.accountShort,
          ),
        ],
      ),
    );
  }
}

String formatDate(dynamic timestamp, AppLocalizations l10n) {
  if (timestamp == null) return l10n.noDate;

  final date = timestamp.toDate();

  return "${date.day.toString().padLeft(2, '0')}."
      "${date.month.toString().padLeft(2, '0')}."
      "${date.year} "
      "${date.hour.toString().padLeft(2, '0')}:"
      "${date.minute.toString().padLeft(2, '0')}";
}

String _riskText(dynamic risk) {
  if (risk == "high") return "Yüksek";
  if (risk == "medium") return "Orta";
  if (risk == "normal") return "Normal";
  return risk?.toString() ?? "-";
}
