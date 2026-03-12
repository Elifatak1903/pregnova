import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'hamile_olcum_page.dart';
import 'hamile_besin_page.dart';
import 'login_page.dart';
import 'hesabim_page.dart';
import 'notification_page.dart';
import 'message_page.dart';
import 'uzman_ara_page.dart';
import 'hamile_info_page.dart';
import 'hamile_olcum_gecmisi_page.dart';
import 'hamile_besin_gecmisi_page.dart';


class HamileAnaSayfa extends StatefulWidget {
  const HamileAnaSayfa({super.key});

  @override
  State<HamileAnaSayfa> createState() => _HamileAnaSayfaState();
}

class _HamileAnaSayfaState extends State<HamileAnaSayfa> {
  int userWeek = 23; // şimdilik sabit
  int _selectedIndex = 2; // Ana sayfa ortada

  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;

  @override
  void initState() {
    super.initState();
    haftalikBildirimKontrol();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showBilgiFormuDialog();
    });
  }

  // BİLGİ FORMU POP UP
  Future<void> showBilgiFormuDialog() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final data = doc.data();
    if (data == null) return;

    if (data['profilTamamlandi'] == true || data['infoLater'] == true) {
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text("Gebelik Bilgileri"),
        content: const Text(
          "Gebelik bilgilerini doldurmak ister misin?\n\n"
              "Bu bilgiler sana daha doğru öneriler sunmamızı sağlar 💕",
        ),
        actions: [
          TextButton(
            child: const Text("Daha Sonra"),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .update({'infoLater': true});
              Navigator.pop(context);
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
            ),
            child: const Text("Şimdi Doldur"),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HamileBilgiFormuPage(uid: uid),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Haftalık bildirim
  Future<void> haftalikBildirimKontrol() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final query = await FirebaseFirestore.instance
        .collection('notification')
        .where('uid', isEqualTo: uid)
        .where('week', isEqualTo: userWeek)
        .get();

    if (query.docs.isNotEmpty) return;

    await FirebaseFirestore.instance.collection('notification').add({
      'uid': uid,
      'week': userWeek,
      'title': 'Hafta $userWeek Bilgilendirmesi',
      'message':
      'Bu haftada demir ve protein ihtiyacın artıyor. Beslenmene dikkat et 💕',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,

      // ---------------- APPBAR ----------------
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: const Text("PregNova"),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => isLoggedIn
                          ? const NotificationPanel()
                          : const LoginPage(),
                    ),
                  );
                },
              ),
              if (isLoggedIn)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notification')
                      .where('uid',
                      isEqualTo:
                      FirebaseAuth.instance.currentUser!.uid)
                      .where('isRead', isEqualTo: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return const SizedBox();
                    }
                    return const Positioned(
                      right: 10,
                      top: 10,
                      child: CircleAvatar(radius: 5, backgroundColor: Colors.red),
                    );
                  },
                ),
            ],
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            "Hoş geldin anne 💕",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.pink.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Sağlık ve beslenme takibini kolayca yapabilirsin.",
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 25),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.pink, Colors.purple],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.baby_changing_station,
                    color: Colors.white, size: 40),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Şu an", style: TextStyle(color: Colors.white70)),
                  Text(
                    "$userWeek. Hafta",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                ]),
              ],
            ),
          ),

          const SizedBox(height: 30),

          riskDashboard(),

          gridButton(
            title: "Risk Ölçüm",
            icon: Icons.health_and_safety,
            color: Colors.red.shade400,
            onTap: () =>
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => RiskTakipFormuPage())),
          ),
          gridButton(
            title: "Besin Analizi",
            icon: Icons.restaurant_menu,
            color: Colors.green.shade400,
            onTap: () =>
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => HamileBesinPage())),
          ),
          gridButton(
            title: "Son Ölçüm Geçmişi",
            icon: Icons.history,
            color: Colors.orange.shade400,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const HamileOlcumGecmisiPage(),
              ),
            ),
          ),

          gridButton(
            title: "Besin & Takviye Geçmişi",
            icon: Icons.medication,
            color: Colors.blue.shade400,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const HamileBesinGecmisiPage(),
              ),
            ),
          ),

        ]),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        onTap: (index) async {
          if (index == 2) return;

          if (index == 0) {
            await Navigator.push(
                context, MaterialPageRoute(builder: (_) => const MessagePage()));
          }

          if (index == 1) {
            await Navigator.push(
                context, MaterialPageRoute(builder: (_) => const UzmanAraPage()));
          }

          if (index == 3) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => isLoggedIn
                    ? HesabimPage()
                    : const LoginPage(),
              ),
            );
          }

          setState(() => _selectedIndex = 2);
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: "Mesajlar"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Ara"),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Ana Sayfa"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Hesabım"),
        ],
      ),
    );
  }

  Widget gridButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Text(
            title,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ]),
      ),
    );
  }
}

Widget riskDashboard() {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) return const SizedBox();

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection("risk_olcumleri")
        .where("uid", isEqualTo: uid)
        .orderBy("tarih", descending: true)
        .limit(1)
        .snapshots(),
    builder: (context, snapshot) {

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const SizedBox();
      }

      final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;

      Color riskColor(String risk) {
        if (risk == "HIGH") return Colors.red;
        if (risk == "MEDIUM") return Colors.orange;
        return Colors.green;
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Son Risk Durumu",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            riskRow("Preeklampsi", data["preeklampsiRisk"], riskColor),
            riskRow("Diyabet", data["diyabetRisk"], riskColor),
            riskRow("Preterm", data["pretermRisk"], riskColor),

          ],
        ),
      );
    },
  );
}

Widget riskRow(String title, String risk, Function color) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Text(
          risk,
          style: TextStyle(
            color: color(risk),
            fontWeight: FontWeight.bold,
          ),
        )
      ],
    ),
  );
}
