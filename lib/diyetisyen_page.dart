import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'client_detail_page.dart';
import 'expert_chat_list_page.dart';

class DietitianHomePage extends StatefulWidget {
  const DietitianHomePage({super.key});

  @override
  State<DietitianHomePage> createState() =>
      _DietitianHomePageState();
}

class _DietitianHomePageState
    extends State<DietitianHomePage> {

  int _selectedIndex = 0;
  late final String uid;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser!.uid;
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
    final sevenDaysAgo =
    DateTime.now().subtract(const Duration(days: 7));

    final query = await FirebaseFirestore.instance
        .collection("risk_olcumleri")
        .where("expertId", isEqualTo: uid)
        .where("tarih", isGreaterThan: sevenDaysAgo)
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("expert_requests")
          .where("expertId", isEqualTo: uid)
          .where("status", isEqualTo: "pending")
          .snapshots(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Text("Bekleyen istek yok"),
          );
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

                if (!userSnapshot.hasData) {
                  return const SizedBox();
                }

                final userData =
                userSnapshot.data!.data() as Map<String, dynamic>?;

                final name = userData?["name"] ?? "";
                final surname = userData?["surname"] ?? "";
                final hafta = userData?["hafta"] ?? "-";

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),

                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.person, color: Colors.white),
                    ),

                    title: Text(
                      "$name $surname",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    subtitle: Text(
                      "Gebelik Haftası: $hafta",
                    ),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            doc.reference.update({'status': 'rejected'});
                          },
                        ),

                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () async {

                            try {
                              await doc.reference.update({'status': 'approved'});

                              await FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(clientId)
                                  .set({
                                "assignedDietitian": uid
                              }, SetOptions(merge: true));

                              final existingChats = await FirebaseFirestore.instance
                                  .collection("chats")
                                  .where("users", arrayContains: uid)
                                  .get();

                              bool chatExists = false;

                              for (var c in existingChats.docs) {
                                final users = List<String>.from(c["users"]);
                                if (users.contains(clientId)) {
                                  chatExists = true;
                                  break;
                                }
                              }

                              if (!chatExists) {
                                await FirebaseFirestore.instance
                                    .collection("chats")
                                    .add({
                                  "users": [clientId, uid],
                                  "lastMessage": "",
                                  "lastMessageTime": FieldValue.serverTimestamp(),
                                });
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Danışan başarıyla eklendi 🎉"),
                                  backgroundColor: Colors.green,
                                ),
                              );

                            } catch (e) {
                              print("HATA: $e");

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Bir hata oluştu ❌"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
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

  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Diyetisyen Paneli 🥗",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
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
                    "Danışan",
                    snapshot.data?.toString() ?? "...",
                    Icons.people,
                  );
                },
              ),

              FutureBuilder<int>(
                future: getPendingCount(),
                builder: (context, snapshot) {
                  return _statCard(
                    "Bekleyen İstek",
                    snapshot.data?.toString() ?? "...",
                    Icons.pending,
                  );
                },
              ),

              FutureBuilder<int>(
                future: getActiveThisWeek(),
                builder: (context, snapshot) {
                  return _statCard(
                    "Son 7 Gün Aktif",
                    snapshot.data?.toString() ?? "...",
                    Icons.timeline,
                  );
                },
              ),

              _statCard(
                "Beslenme Modülü",
                "Yakında",
                Icons.restaurant,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientsPage() {
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
          return const Center(
            child: Text("Henüz danışan bulunmuyor"),
          );
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

                final data =
                userSnapshot.data!.data() as Map<String, dynamic>?;

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

                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.person, color: Colors.white),
                    ),

                    title: Text(
                      "$name $surname",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    subtitle: Text(
                      "Gebelik Haftası: $hafta",
                    ),

                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClientDetailPage(
                            clientId: clientId,
                          ),
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

  //  MESSAGES

  Widget _buildMessagesPage() {
    return const ExpertChatListPage();
  }

  // ACCOUNT

  Widget _buildAccountPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [

          const SizedBox(height: 30),

          const Text(
            "Hesap Bilgileri",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 30),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Çıkış Yap",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.green, size: 26),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          Text(title),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,

      appBar: AppBar(
        title: const Text("PregNova"),
        backgroundColor: Colors.green,
      ),

      body: _buildBody(),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.home), label: "Ana Sayfa"),

          const BottomNavigationBarItem(
              icon: Icon(Icons.people), label: "Danışanlar"),

          const BottomNavigationBarItem(
              icon: Icon(Icons.pending), label: "İstekler"),

          // 💣 MESAJLAR (BADGE’Lİ)
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
                    return data["isRead"] == false &&
                        data["receiverId"] == uid;
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: "Mesajlar",
          ),

          const BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Hesap"),
        ],
      ),
    );
  }
}