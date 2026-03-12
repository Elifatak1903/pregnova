import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

class UzmanHomePage extends StatefulWidget {
  const UzmanHomePage({super.key});

  @override
  State<UzmanHomePage> createState() => _UzmanHomePageState();
}

class _UzmanHomePageState extends State<UzmanHomePage> {
  int _selectedIndex = 0;

  final uid = FirebaseAuth.instance.currentUser!.uid;

  Future<String> getRole() async {
    final doc =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['role'] ?? 'unknown';
  }

  Future<int> getDanisanSayisi() async {
    final query = await FirebaseFirestore.instance
        .collection("expert_requests")
        .where("expertId", isEqualTo: uid)
        .where("status", isEqualTo: "approved")
        .get();

    return query.docs.length;
  }

  Future<int> getRiskliHastaSayisi() async {
    final query = await FirebaseFirestore.instance
        .collection("risk_olcumleri")
        .where("expertId", isEqualTo: uid)
        .where("riskLevel", isEqualTo: "high")
        .get();

    return query.docs.length;
  }

  void signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getRole(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snapshot.data!;
        final isDietitian = role == 'dietitian';
        final mainColor = isDietitian ? Colors.green : Colors.pink;

        return Scaffold(
          backgroundColor: mainColor.shade50,
          appBar: AppBar(
            title: Text(
                isDietitian ? "Diyetisyen Paneli" : "Jinekolog Paneli"),
            backgroundColor: mainColor,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => signOut(context),
              ),
            ],
          ),
          body: _buildBody(isDietitian, mainColor),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
            type: BottomNavigationBarType.fixed,

            selectedItemColor: mainColor,
            unselectedItemColor: mainColor.withOpacity(0.6),

            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),

            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home), label: "Ana Sayfa"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.people), label: "Danışanlar"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.pending), label: "İstekler"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: "Profil"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(bool isDietitian, MaterialColor mainColor) {
    if (_selectedIndex == 1) return _buildDanisanlar();
    if (_selectedIndex == 2) return _buildPendingRequests();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Hoş geldin 👋",
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FutureBuilder<int>(
                  future: getDanisanSayisi(),
                  builder: (context, snapshot) {
                    return _statCard(
                        "Danışan",
                        snapshot.data?.toString() ?? "...",
                        mainColor);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FutureBuilder<int>(
                  future: getRiskliHastaSayisi(),
                  builder: (context, snapshot) {
                    return _statCard(
                        isDietitian ? "Eksik Besin" : "Riskli Hasta",
                        snapshot.data?.toString() ?? "...",
                        Colors.red);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5)
        ],
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 6),
          Text(title),
        ],
      ),
    );
  }

  Widget _buildDanisanlar() {
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
          return const Center(child: Text("Henüz danışan yok"));
        }

        return ListView(
          children: docs.map((doc) {
            return ListTile(
              title: Text("Danışan UID: ${doc["clientId"]}"),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPendingRequests() {
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
          return const Center(child: Text("Bekleyen istek yok"));
        }

        return ListView.builder(
          itemCount: docs.length,
            itemBuilder: (context, index) {
              final requestDoc = docs[index];
              final clientId = requestDoc["clientId"];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(clientId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text("Yükleniyor..."));
                  }
                  final userData = userSnapshot.data!.data() as Map<
                      String,
                      dynamic>?;
                  final name = userData?["name"] ?? "";
                  final surname = userData?["surname"] ?? "";

                  return Card(
                    child: ListTile(
                      title: Text("$name $surname",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold
                        ),),
                      subtitle: Text("ID: $clientId"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () {
                              requestDoc.reference
                                  .update({"status": "approved"});
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.red),
                            onPressed: () {
                              requestDoc.reference
                                  .update({"status": "rejected"});
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
}