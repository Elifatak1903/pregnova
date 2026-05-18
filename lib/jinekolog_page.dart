import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'gynecologist_patient_detail_page.dart';
import 'login_page.dart';
import 'notification_page.dart';
import 'expert_chat_list_page.dart';
import 'son_olcumler_page.dart';
import 'edit_gynecologist_profile_page.dart';
import 'sifre_degistir_page.dart';
import 'language_selector.dart';
import 'l10n/app_localizations.dart';

class GynecologistHomePage extends StatefulWidget {
  const GynecologistHomePage({super.key});

  @override
  State<GynecologistHomePage> createState() => _GynecologistHomePageState();
}

class _GynecologistHomePageState extends State<GynecologistHomePage> {
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

  Future<int> getHighRiskCount() async {
    final query = await FirebaseFirestore.instance
        .collection("risk_olcumleri")
        .get();

    final uniquePatients = <String>{};

    for (var doc in query.docs) {
      final data = doc.data();
      final uid = data["uid"];
      final hasHighRisk =
          data["preeklampsiRisk"] == "HIGH" ||
          data["diyabetRisk"] == "HIGH" ||
          data["pretermRisk"] == "HIGH";

      if (uid != null && hasHighRisk) {
        uniquePatients.add(uid);
      }
    }

    return uniquePatients.length;
  }

  Future<Map<String, int>> getActiveThisWeek() async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    final query = await FirebaseFirestore.instance
        .collection("risk_olcumleri")
        .where(
          "tarih",
          isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo),
        )
        .get();

    final uniquePatients = <String>{};

    for (var doc in query.docs) {
      final data = doc.data();
      final uid = data["uid"];

      if (uid != null) {
        uniquePatients.add(uid);
      }
    }

    return {
      "measurements": query.docs.length,
      "patients": uniquePatients.length,
    };
  }

  Future<Map<String, int>> getRiskDistribution() async {
    final normal = await FirebaseFirestore.instance
        .collection("users")
        .where("assignedDoctor", isEqualTo: uid)
        .where("riskLevel", isEqualTo: "normal")
        .get();

    final medium = await FirebaseFirestore.instance
        .collection("users")
        .where("assignedDoctor", isEqualTo: uid)
        .where("riskLevel", isEqualTo: "medium")
        .get();

    final high = await FirebaseFirestore.instance
        .collection("users")
        .where("assignedDoctor", isEqualTo: uid)
        .where("riskLevel", isEqualTo: "high")
        .get();

    return {
      "normal": normal.docs.length,
      "medium": medium.docs.length,
      "high": high.docs.length,
    };
  }

  Widget _buildRecentActivity() {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("risk_olcumleri")
          .orderBy("tarih", descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Text(l10n.noActivityYet);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(docs.length, (index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            final tarih = data["tarih"];
            final uid = data["uid"];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("users")
                  .doc(uid)
                  .get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) {
                  return const SizedBox();
                }

                final userData = userSnap.data!.data() as Map<String, dynamic>?;

                final name = userData?["name"] ?? "";
                final surname = userData?["surname"] ?? "";

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SonOlcumlerPage(
                            selectedTarih: tarih,
                            selectedUid: uid,
                          ),
                        ),
                      );
                    },

                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
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
                              Icons.timeline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 10),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.newMeasurementSent("$name $surname"),
                                    style: const TextStyle(fontSize: 14),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    timeAgo(tarih, l10n),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        );
      },
    );
  }

  Widget _buildHighRiskSummaryBanner() {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<int>(
      future: getHighRiskCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        if (count <= 0) {
          return const SizedBox();
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SonOlcumlerPage()),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.warning, color: Colors.red),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.highRiskPatientWarning,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.highRiskPatientCount(count),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.review,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _selectedIndex = 0;
  String _patientRiskFilter = "all";
  late final String uid;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser!.uid;
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
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NotificationPanel(),
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

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomePage();

      case 1:
        return _buildPatientsPage();

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

  Widget _buildHomePage() {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          Text(
            l10n.gynecologistPanel,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          const SizedBox(height: 25),

          _buildHighRiskSummaryBanner(),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.1,
            children: [
              FutureBuilder<int>(
                future: getApprovedCount(),
                builder: (context, snapshot) {
                  return _premiumStatCard(
                    l10n.clients,
                    snapshot.data?.toString() ?? "...",
                    Colors.pink,
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
                  return _premiumStatCard(
                    l10n.pending,
                    snapshot.data?.toString() ?? "...",
                    Colors.orange,
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
                future: getHighRiskCount(),
                builder: (context, snapshot) {
                  return _premiumStatCard(
                    l10n.highRisk,
                    snapshot.data?.toString() ?? "...",
                    Colors.red,
                    Icons.warning,
                    null,
                  );
                },
              ),

              FutureBuilder<Map<String, int>>(
                future: getActiveThisWeek(),
                builder: (context, snapshot) {
                  final data = snapshot.data;

                  final text = data == null
                      ? "..."
                      : l10n.activeThisWeekSummary(
                          data["measurements"] ?? 0,
                          data["patients"] ?? 0,
                        );

                  return _premiumStatCard(
                    l10n.last7Days,
                    text,
                    Colors.green,
                    Icons.timeline,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SonOlcumlerPage(),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 30),

          _buildRiskChart(),

          const SizedBox(height: 30),

          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (_selectedIndex != 2) {
                setState(() {
                  _selectedIndex = 2;
                });
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.consultationRequests,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 10),

                _buildPatientRequests(),
              ],
            ),
          ),

          const SizedBox(height: 30),

          Text(
            l10n.recentActivities,
            style: TextStyle(
              fontSize: 22,
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

  Widget _buildPatientsPage() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _buildPatientRiskFilters(l10n),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("expert_requests")
                .where("expertId", isEqualTo: uid)
                .where("status", isEqualTo: "approved")
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    l10n.noClientsYet,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                      final doctorRiskFlags = _doctorRiskFlags(data);

                      if (!_matchesPatientRiskFilter(doctorRiskFlags)) {
                        return const SizedBox.shrink();
                      }

                      final name = data?["name"] ?? "";
                      final surname = data?["surname"] ?? "";
                      final hafta = data?["hafta"] ?? "-";
                      final risk = data?["riskLevel"] ?? "normal";
                      final doctorRiskLabels = _doctorRiskLabels(
                        l10n,
                        doctorRiskFlags,
                      );

                      Color riskColor;
                      String riskText;

                      if (risk == "high") {
                        riskColor = Colors.red;
                        riskText = l10n.highRisk;
                      } else if (risk == "medium") {
                        riskColor = Colors.orange;
                        riskText = l10n.mediumRisk;
                      } else {
                        riskColor = Colors.green;
                        riskText = l10n.normalRisk;
                      }

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).shadowColor.withValues(alpha: 0.2),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),

                            leading: CircleAvatar(
                              radius: 26,
                              backgroundColor: riskColor,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),

                            title: Text(
                              "$name $surname",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text("${l10n.pregnancyWeekInput}: $hafta"),
                                const SizedBox(height: 4),
                                Text(
                                  "${l10n.riskStatus}: $riskText",
                                  style: TextStyle(
                                    color: riskColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (doctorRiskLabels.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: doctorRiskLabels.map((label) {
                                      return Chip(
                                        label: Text(label),
                                        visualDensity: VisualDensity.compact,
                                        backgroundColor: Colors.red.withValues(
                                          alpha: 0.10,
                                        ),
                                        labelStyle: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),

                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                            ),

                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HastaDetayPage(
                                    clientId: clientId,
                                    name: name,
                                    surname: surname,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPatientRiskFilters(AppLocalizations l10n) {
    final filters = [
      ("all", l10n.all),
      ("preeklampsi", l10n.preeklampsiTracking),
      ("diabetes", l10n.gestationalDiabetes),
      ("preterm", l10n.pretermRisk),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: filters.map((filter) {
          final selected = _patientRiskFilter == filter.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected,
              label: Text(filter.$2),
              onSelected: (_) {
                setState(() {
                  _patientRiskFilter = filter.$1;
                });
              },
              selectedColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.18),
              labelStyle: TextStyle(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _matchesPatientRiskFilter(Map<String, dynamic> flags) {
    if (_patientRiskFilter == "all") return true;
    return flags[_patientRiskFilter] == true;
  }

  Map<String, dynamic> _doctorRiskFlags(Map<String, dynamic>? data) {
    final rawFlags = data?["doctorRiskFlags"];
    if (rawFlags is Map) {
      return Map<String, dynamic>.from(rawFlags);
    }
    return <String, dynamic>{};
  }

  List<String> _doctorRiskLabels(
    AppLocalizations l10n,
    Map<String, dynamic> flags,
  ) {
    return [
      if (flags["preeklampsi"] == true) l10n.preeklampsiTracking,
      if (flags["diabetes"] == true) l10n.gestationalDiabetes,
      if (flags["preterm"] == true) l10n.pretermRisk,
    ];
  }

  Widget _buildMessagesPage() {
    return const ExpertChatListPage();
  }

  Widget _buildAccountPage() {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        final name = data?["name"] ?? "";
        final email = user.email ?? "";

        final license = data?["licenseNumber"] ?? "-";
        final experience = data?["experience"] ?? "-";
        final hospital = data?["hospital"] ?? "-";
        final diplomaUrl = data?["diplomaUrl"] ?? data?["diploma"];

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
                      child: Icon(Icons.person, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dr. $name",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(email),
                        Text(
                          l10n.gynecologist,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditGynecologistProfilePage(),
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

              const SizedBox(height: 20),

              Text(
                l10n.expertiseInfo,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              _infoCard(l10n.licenseNumber, license),
              _infoCard(l10n.experience, experience),
              _infoCard(l10n.institution, hospital),

              const SizedBox(height: 25),

              _accountTile(Icons.description, l10n.diplomaDocuments, () {
                final url = diplomaUrl?.toString().trim();
                if (url == null || url.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.noDiplomaAdded)));
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(
                        title: const Text("Diploma"),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      body: Center(
                        child: InteractiveViewer(
                          child: Image.network(
                            url,
                            errorBuilder: (_, __, ___) {
                              return Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  l10n.documentPreviewUnavailable,
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              if (diplomaUrl != null && diplomaUrl.toString().trim().isNotEmpty)
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
                      const SizedBox(width: 8),
                      Text(l10n.diplomaUploaded),
                    ],
                  ),
                ),

              const SizedBox(height: 25),

              Text(
                l10n.settings,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  MaterialPageRoute(builder: (_) => LoginPage()),
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
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(title: Text(title), subtitle: Text(value)),
    );
  }

  Widget _accountTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(
          icon,
          color: color ?? Theme.of(context).colorScheme.onSurface,
        ),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildRequestsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildPatientRequests(),
    );
  }

  Widget _premiumStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 10),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }

  Widget _requestInfoChip(String title, dynamic value) {
    final text = value?.toString().trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            text == null || text.isEmpty ? "-" : text,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskChart() {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<Map<String, int>>(
      future: getRiskDistribution(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        final normal = data["normal"]!.toDouble();
        final medium = data["medium"]!.toDouble();
        final high = data["high"]!.toDouble();

        final total = normal + medium + high;

        if (total == 0) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            Text(
              l10n.riskDistribution,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(color: Colors.green, value: normal),
                    PieChartSectionData(color: Colors.orange, value: medium),
                    PieChartSectionData(color: Colors.red, value: high),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
          ],
        );
      },
    );
  }

  Widget _buildPatientRequests() {
    final l10n = AppLocalizations.of(context)!;

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
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Text(l10n.noPendingRequests),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
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

                final data = userSnapshot.data!.data() as Map<String, dynamic>?;

                final name = data?["name"] ?? "";
                final surname = data?["surname"] ?? "";
                final hafta = data?["hafta"] ?? "-";
                final email = data?["email"] ?? "-";
                final phone = data?["phone"] ?? "-";
                final boy = data?["boy"] ?? "-";
                final kilo = data?["kilo"] ?? "-";
                final bmi = data?["bmi"] ?? data?["BMI"] ?? "-";
                final allergy = data?["allergy"] ?? data?["alerji"] ?? "-";
                final risk = data?["riskLevel"] ?? "-";

                return ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: _cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$name $surname - ${l10n.weekLabel(hafta)}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 10),

                        Text("${l10n.patientId}: $clientId"),
                        Text("${l10n.requestId}: ${doc.id}"),
                        const SizedBox(height: 8),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _requestInfoChip(l10n.email, email),
                            _requestInfoChip(l10n.phone, phone),
                            _requestInfoChip(l10n.pregnancyWeekInput, hafta),
                            _requestInfoChip(l10n.heightCm, "$boy cm"),
                            _requestInfoChip(l10n.currentWeightKg, "$kilo kg"),
                            _requestInfoChip(l10n.bmi, bmi),
                            _requestInfoChip(l10n.risk, _riskText(risk)),
                            _requestInfoChip(l10n.allergy, allergy),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            /// KABUL
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () async {
                                final doctorUid =
                                    FirebaseAuth.instance.currentUser!.uid;

                                await FirebaseFirestore.instance
                                    .collection("expert_requests")
                                    .doc(doc.id)
                                    .update({
                                      "status": "approved",
                                      "approvedAt":
                                          FieldValue.serverTimestamp(),
                                    });

                                await FirebaseFirestore.instance
                                    .collection("users")
                                    .doc(clientId)
                                    .update({"assignedDoctor": doctorUid});

                                await FirebaseFirestore.instance
                                    .collection("notification")
                                    .add({
                                      "uid": clientId,
                                      "type": "expert_request",
                                      "title": "Doktor Onayı",
                                      "message":
                                          "Doktorunuz sizi danışan olarak kabul etti.",
                                      "isRead": false,
                                      "createdAt": FieldValue.serverTimestamp(),
                                    });

                                debugPrint(
                                  "ASSIGNED DOCTOR: $doctorUid to $clientId",
                                );
                              },
                              child: Text(l10n.accept),
                            ),

                            const SizedBox(width: 10),

                            /// REDDET
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection("expert_requests")
                                    .doc(doc.id)
                                    .update({
                                      "status": "rejected",
                                      "rejectedAt":
                                          FieldValue.serverTimestamp(),
                                    });

                                await FirebaseFirestore.instance
                                    .collection("notification")
                                    .add({
                                      "uid": clientId,
                                      "type": "expert_request",
                                      "title": "İstek Reddedildi",
                                      "message":
                                          "Gönderdiğiniz doktor isteği reddedildi.",
                                      "isRead": false,
                                      "createdAt": FieldValue.serverTimestamp(),
                                    });
                              },
                              child: Text(l10n.reject),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).shadowColor.withValues(alpha: 0.2),
          blurRadius: 6,
        ),
      ],
    );
  }

  String timeAgo(Timestamp timestamp, AppLocalizations l10n) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) {
      return l10n.secondsAgo(diff.inSeconds);
    } else if (diff.inMinutes < 60) {
      return l10n.minutesAgo(diff.inMinutes);
    } else if (diff.inHours < 24) {
      return l10n.hoursAgo(diff.inHours);
    } else {
      return l10n.daysAgo(diff.inDays);
    }
  }

  String _riskText(dynamic risk) {
    if (risk == "high") return "Yüksek";
    if (risk == "medium") return "Orta";
    if (risk == "normal") return "Normal";
    return risk?.toString() ?? "-";
  }
}
