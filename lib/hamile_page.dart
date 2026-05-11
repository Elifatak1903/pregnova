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
import 'hamile_diet_page.dart';
import 'l10n/app_localizations.dart';

class HamileAnaSayfa extends StatefulWidget {
  const HamileAnaSayfa({super.key});

  @override
  State<HamileAnaSayfa> createState() => _HamileAnaSayfaState();
}

class _HamileAnaSayfaState extends State<HamileAnaSayfa> {
  int? userWeek;
  int _selectedIndex = 2;
  late final List<Widget> pages;

  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;

  @override
  void initState() {
    super.initState();

    pages = [
      const MessagePage(),
      const UzmanAraPage(),
      Container(),
      const DiyetPage(),
      isLoggedIn ? HesabimPage() : const LoginPage(),
    ];

    loadUserWeek();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showBilgiFormuDialog();
    });
  }

  Future<void> loadUserWeek() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final data = doc.data();
    if (data == null) return;

    final parsedWeek = calculatePregnancyWeek(data);

    if (data['hafta'] != parsedWeek) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'hafta': parsedWeek,
      }, SetOptions(merge: true));
    }

    setState(() {
      userWeek = parsedWeek;
    });

    await haftalikBildirimKontrol();
  }

  int calculatePregnancyWeek(Map<String, dynamic> data) {
    final start = data['gebelikBaslangicTarihi'];

    if (start == null) {
      final week = data['hafta'];
      return (week is int) ? week : int.tryParse(week.toString()) ?? 1;
    }

    DateTime startDate;
    if (start is Timestamp) {
      startDate = start.toDate();
    } else if (start is DateTime) {
      startDate = start;
    } else {
      startDate = DateTime.tryParse(start.toString()) ?? DateTime.now();
    }

    final days = DateTime.now().difference(startDate).inDays;
    final week = days ~/ 7;

    return week.clamp(1, 42);
  }

  Future<void> haftalikBildirimKontrol() async {
    if (userWeek == null) return;
    if (!mounted) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final week = userWeek!;
    final l10n = AppLocalizations.of(context)!;

    final query = await FirebaseFirestore.instance
        .collection('notification')
        .where('uid', isEqualTo: uid)
        .where('week', isEqualTo: week)
        .get();

    if (query.docs.isNotEmpty) return;

    await FirebaseFirestore.instance.collection('notification').add({
      'uid': uid,
      'week': week,
      'title': l10n.weeklyInfoTitle(week),
      'message': l10n.weeklyInfoMessage,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

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

    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.pregnancyInfoTitle),
        content: Text(l10n.pregnancyInfoPrompt),
        actions: [
          TextButton(
            child: Text(l10n.later),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .update({'infoLater': true});
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: Text(l10n.fillNow),
            onPressed: () {
              Navigator.pop(dialogContext);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,

      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
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
                      .where(
                        'uid',
                        isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                      )
                      .where('isRead', isEqualTo: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox();
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SizedBox();
                    }

                    return const Positioned(
                      right: 10,
                      top: 10,
                      child: CircleAvatar(
                        radius: 5,
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const MessagePage(),
          const UzmanAraPage(),
          _buildHomeContent(),
          const DiyetPage(), //
          isLoggedIn ? HesabimPage() : const LoginPage(),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble_outline),
            label: l10n.message,
          ),

          BottomNavigationBarItem(
            icon: const Icon(Icons.search),
            label: l10n.searchExpert,
          ),

          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: l10n.home,
          ),

          BottomNavigationBarItem(
            icon: const Icon(Icons.restaurant_menu),
            label: l10n.diet,
          ),

          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: l10n.account,
          ),
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              l10n.welcomeMother,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Center(
            child: Text(
              l10n.pregnantHomeSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),

          const SizedBox(height: 25),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.baby_changing_station,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.current,
                      style: const TextStyle(color: Colors.white70),
                    ),

                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Text(
                            l10n.loading,
                            style: const TextStyle(color: Colors.white),
                          );
                        }

                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;

                        final week = data['hafta'] ?? 1;

                        return Text(
                          l10n.pregnancyWeek(week),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          riskDashboard(),

          gridButton(
            title: l10n.riskMeasurement,
            icon: Icons.health_and_safety,
            color: Colors.deepPurple.shade400,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RiskTakipFormuPage()),
            ),
          ),

          gridButton(
            title: l10n.nutritionAnalysis,
            icon: Icons.restaurant_menu,
            color: Colors.indigo.shade400,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HamileBesinPage()),
            ),
          ),

          gridButton(
            title: l10n.lastMeasurementHistory,
            icon: Icons.history,
            color: Colors.deepPurple.shade400,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HamileOlcumGecmisiPage()),
            ),
          ),

          gridButton(
            title: l10n.nutritionSupplementHistory,
            icon: Icons.medication,
            color: Colors.indigo.shade400,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HamileBesinGecmisiPage()),
            ),
          ),
        ],
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
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const SizedBox();
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const SizedBox();
      }

      final l10n = AppLocalizations.of(context)!;
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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.latestRiskStatus,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            riskRow(
              context,
              "Preeklampsi",
              data["preeklampsiRisk"] ?? "LOW",
              riskColor,
            ),
            riskRow(
              context,
              l10n.diabetes,
              data["diyabetRisk"] ?? "LOW",
              riskColor,
            ),
            riskRow(
              context,
              "Preterm",
              data["pretermRisk"] ?? "LOW",
              riskColor,
            ),
          ],
        ),
      );
    },
  );
}

Widget riskRow(
  BuildContext context,
  String title,
  String risk,
  Color Function(String) color,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        Text(
          risk,
          style: TextStyle(color: color(risk), fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}
