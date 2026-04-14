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
        .collection("besin_analizleri")
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

  Widget _buildRecentActivity() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("besin_analizleri")
          .where("dietitianId", isEqualTo: uid)
          .orderBy("tarih", descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Text("Henüz aktivite yok");
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {

            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            final tarih = data["tarih"];
            final patientId = data["uid"];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("users")
                  .doc(patientId)
                  .get(),
              builder: (context, userSnap) {

                if (!userSnap.hasData) {
                  return const SizedBox();
                }

                final userData =
                userSnap.data!.data() as Map<String, dynamic>?;

                final name = userData?["name"] ?? "";
                final surname = userData?["surname"] ?? "";

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClientDetailPage(
                          clientId: patientId,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 6)
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.restaurant, color: Colors.green),
                        const SizedBox(width: 10),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "$name $surname yeni analiz gönderdi",
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timeAgo(tarih),
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
                    "Bekleyen İstek",
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
                    "Son 7 Gün Aktif",
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
              _statCard(
                "Beslenme Modülü",
                "Aç",
                Icons.restaurant,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SelectClientForDietPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 30),

          const Text("Son Aktiviteler"),

          const SizedBox(height: 15),

          _buildRecentActivity(),
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

  Widget _buildMessagesPage() {
    return const ExpertChatListPage();
  }

  Widget _buildAccountPage() {
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

        final data =
        snapshot.data!.data() as Map<String, dynamic>?;
        final diplomaUrl = data?["diplomaUrl"];

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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6)
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.green,
                      child: Icon(Icons.person,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(email),
                        const Text(
                          "Diyetisyen",
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 15),

              ElevatedButton(
                onPressed: () {
                  // edit page açacağız
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Bilgileri Düzenle"),
              ),

              const SizedBox(height: 25),

              const Text(
                "Uzmanlık Bilgileri",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              _infoCard("Uzmanlık Alanı", expertise),
              _infoCard("Deneyim", experience),
              _infoCard("Çalıştığı Kurum", institution),

              const SizedBox(height: 25),

              _accountTile(
                Icons.description,
                "Diploma / Belgeler",
                    () {
                  if (diplomaUrl != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(
                            title: const Text("Diploma"),
                            backgroundColor: Colors.green,
                          ),
                          body: Center(
                            child: Image.network(diplomaUrl),
                          ),
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Henüz diploma eklenmemiş"),
                      ),
                    );
                  }
                },
              ),
              if (diplomaUrl != null)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.verified, color: Colors.green),
                      SizedBox(width: 8),
                      Text("Diploma yüklendi"),
                    ],
                  ),
                ),

              const SizedBox(height: 25),

              const Text(
                "Ayarlar",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              _accountTile(
                Icons.lock,
                "Şifre Değiştir",
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SifreDegistirPage(),
                    ),
                  );
                },
              ),

              _accountTile(
                Icons.logout,
                "Çıkış Yap",
                    () async {
                  await FirebaseAuth.instance.signOut();

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginPage(),
                    ),
                        (route) => false,
                  );
                },
                color: Colors.red,
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _infoCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }

  Widget _accountTile(
      IconData icon,
      String title,
      VoidCallback onTap,
      {Color color = Colors.black}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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

        actions: [
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
                    icon: const Icon(Icons.notifications),
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