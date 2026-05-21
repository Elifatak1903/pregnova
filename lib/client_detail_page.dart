import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'besin_analiz_detay_page.dart';
import 'food_units.dart';
import 'l10n/app_localizations.dart';
import 'nutrition_engine.dart';

class ChartData {
  final List<FlSpot> spots;
  final List<DateTime> dates;

  ChartData(this.spots, this.dates);
}

class ClientDetailPage extends StatefulWidget {
  final String clientId;

  const ClientDetailPage({super.key, required this.clientId});

  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage> {
  late Future<ChartData> calorieFuture;
  late Future<ChartData> weightFuture;

  @override
  void initState() {
    super.initState();

    calorieFuture = getCalorieSpots();
    weightFuture = getWeightSpots();
  }

  Future<ChartData> getWeightSpots() async {
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.clientId)
        .get();
    final profileWeight = _readDouble(userDoc.data()?["kilo"]);

    final query = await FirebaseFirestore.instance
        .collection("risk_olcumleri")
        .where("uid", isEqualTo: widget.clientId)
        .get();

    final now = DateTime.now();
    final startDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    List<DateTime> dates = [];
    for (int i = 0; i < 7; i++) {
      dates.add(startDate.add(Duration(days: i)));
    }

    Map<String, double> weightMap = {};
    double latestMeasurementWeight = 0;
    DateTime? latestMeasurementDate;

    for (var doc in query.docs) {
      final data = doc.data();

      if (!data.containsKey("tarih") || !data.containsKey("kilo")) {
        continue;
      }

      final ts = data["tarih"];
      final rawKilo = data["kilo"];

      if (ts == null || rawKilo == null) {
        continue;
      }

      DateTime date;

      if (ts is Timestamp) {
        date = ts.toDate();
      } else {
        continue;
      }

      if (date.isBefore(startDate) || date.isAfter(endDate)) {
        continue;
      }

      double kilo = _readDouble(rawKilo);
      if (kilo <= 0) {
        continue;
      }

      if (latestMeasurementDate == null || date.isAfter(latestMeasurementDate)) {
        latestMeasurementDate = date;
        latestMeasurementWeight = kilo;
      }

      String key = "${date.year}-${date.month}-${date.day}";

      weightMap[key] = kilo;
    }

    List<FlSpot> spots = [];

    for (int i = 0; i < dates.length; i++) {
      final d = dates[i];
      String key = "${d.year}-${d.month}-${d.day}";

      double kilo;

      if (weightMap.containsKey(key)) {
        kilo = weightMap[key]!;
      } else if (profileWeight > 0) {
        kilo = profileWeight;
      } else {
        kilo = latestMeasurementWeight;
      }

      spots.add(FlSpot(i.toDouble(), kilo));
    }

    return ChartData(spots, dates);
  }

  double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? "") ?? 0;
  }

  Future<ChartData> getCalorieSpots() async {
    final query = await FirebaseFirestore.instance
        .collection("besin_analizleri")
        .where("uid", isEqualTo: widget.clientId)
        .get();

    final now = DateTime.now();
    final startDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    List<DateTime> dates = [];
    for (int i = 0; i < 7; i++) {
      dates.add(startDate.add(Duration(days: i)));
    }

    Map<String, double> calorieMap = {};

    for (var doc in query.docs) {
      final data = doc.data();

      if (!(data.containsKey("createdAt") || data.containsKey("tarih")) ||
          !data.containsKey("kalori")) {
        continue;
      }

      final ts = data["createdAt"] ?? data["tarih"];
      final raw = data["kalori"];

      if (ts == null || raw == null) {
        continue;
      }

      DateTime date;

      if (ts is Timestamp) {
        date = ts.toDate();
      } else {
        continue;
      }

      if (date.isBefore(startDate) || date.isAfter(endDate)) {
        continue;
      }

      double kalori = (raw is int)
          ? raw.toDouble()
          : (raw is double)
          ? raw
          : double.tryParse(raw.toString()) ?? 0;

      if (kalori <= 0) {
        continue;
      }

      String key = "${date.year}-${date.month}-${date.day}";

      calorieMap[key] = (calorieMap[key] ?? 0) + kalori;
    }

    List<FlSpot> spots = [];

    for (int i = 0; i < dates.length; i++) {
      final d = dates[i];
      String key = "${d.year}-${d.month}-${d.day}";

      double kalori;

      kalori = calorieMap[key] ?? 0;

      spots.add(FlSpot(i.toDouble(), kalori));
    }

    return ChartData(spots, dates);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.clientDetail),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "remove") {
                _removeClientFromDietitian(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: "remove",
                child: Text(
                  _localized(context, "Danışanla Bağı Kes", "Remove Client"),
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("users")
            .doc(widget.clientId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) {
            return Center(child: Text(l10n.noClientFound));
          }

          final name = data["name"] ?? "";
          final surname = data["surname"] ?? "";
          final hafta = data["hafta"] ?? "-";
          final kilo = data["kilo"] ?? "-";
          final boy = data["boy"] ?? "-";
          final bmi = data["bmi"] ?? "-";
          final alerji = data["alerjiler"] ?? "";
          final chronicDiseases = _chronicDiseaseLabels(l10n, data);
          final riskLevel = _riskLevelText(l10n, data["riskLevel"]);
          final followUpRisks = _doctorRiskLabels(l10n, data["doctorRiskFlags"]);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$name $surname",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text("${l10n.pregnancyWeekInput}: $hafta"),
                        const SizedBox(height: 10),
                        Text("${l10n.currentWeightKg}: $kilo kg"),
                        const SizedBox(height: 10),
                        Text("${l10n.heightCm}: $boy cm"),
                        const SizedBox(height: 10),
                        Text("${l10n.bmi}: $bmi"),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text("${l10n.allergies}: $alerji"),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "${l10n.chronicDisease}: ${chronicDiseases.isEmpty ? l10n.notExists : chronicDiseases.join(", ")}",
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "${l10n.riskStatus}: $riskLevel",
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "${_localized(context, "Takip Riskleri", "Follow-up Risks")}: ${followUpRisks.isEmpty ? l10n.notExists : followUpRisks.join(", ")}",
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                Text(
                  l10n.weightChart,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 20),

                FutureBuilder<ChartData>(
                  future: weightFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      return SizedBox(
                        height: 220,
                        child: Center(
                          child: Text(
                            l10n.errorWithMessage(snapshot.error ?? ""),
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return SizedBox(
                        height: 220,
                        child: Center(child: Text(l10n.dataCouldNotBeLoaded)),
                      );
                    }

                    final spots = snapshot.data!.spots;
                    final dates = snapshot.data!.dates;

                    return Container(
                      height: 220,

                      padding: const EdgeInsets.fromLTRB(4, 10, 10, 10),

                      child: spots.isEmpty
                          ? Center(child: Text(l10n.noData))
                          : LineChart(
                              LineChartData(
                                minX: 0,
                                maxX: 6,

                                minY: spots.isEmpty
                                    ? 0
                                    : spots
                                              .map((e) => e.y)
                                              .reduce((a, b) => a < b ? a : b) -
                                          2,

                                maxY: spots.isEmpty
                                    ? 10
                                    : spots
                                              .map((e) => e.y)
                                              .reduce((a, b) => a > b ? a : b) +
                                          2,

                                lineBarsData: [
                                  LineChartBarData(
                                    spots: spots,
                                    isCurved: true,
                                    curveSmoothness: 0.3,
                                    barWidth: 3,
                                    dotData: FlDotData(show: true),
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ],

                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 1,
                                      reservedSize: 30,

                                      getTitlesWidget: (value, meta) {
                                        int index = value.toInt();

                                        if (index < 0 ||
                                            index > 6 ||
                                            index >= dates.length) {
                                          return const SizedBox();
                                        }

                                        final d = dates[index];

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 6,
                                          ),
                                          child: Text(
                                            "${d.day}/${d.month}",
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 5,
                                      reservedSize: 38,

                                      getTitlesWidget: (value, meta) {
                                        if (value % 5 != 0) {
                                          return const SizedBox();
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: Text(
                                            value.toInt().toString(),
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),

                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),

                                gridData: FlGridData(
                                  show: true,
                                  horizontalInterval: 5,
                                  verticalInterval: 1,

                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey.withValues(alpha: 0.2),
                                      strokeWidth: 1,
                                    );
                                  },

                                  getDrawingVerticalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey.withValues(
                                        alpha: 0.15,
                                      ),
                                      strokeWidth: 1,
                                    );
                                  },
                                ),

                                lineTouchData: LineTouchData(
                                  touchTooltipData: LineTouchTooltipData(
                                    getTooltipItems: (touchedSpots) {
                                      return touchedSpots.map((spot) {
                                        int index = spot.x.toInt();

                                        if (index < 0 ||
                                            index > 6 ||
                                            index >= dates.length) {
                                          return null;
                                        }

                                        final d = dates[index];

                                        return LineTooltipItem(
                                          "${d.day}/${d.month}\n${spot.y.toStringAsFixed(1)} kg",
                                          const TextStyle(color: Colors.white),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ),
                              ),
                            ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                Text(
                  l10n.calorieChart,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 20),

                FutureBuilder<ChartData>(
                  future: calorieFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return SizedBox(
                        height: 220,
                        child: Center(child: Text(l10n.genericError)),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (!snapshot.hasData) {
                      return SizedBox(
                        height: 220,
                        child: Center(child: Text(l10n.dataCouldNotBeLoaded)),
                      );
                    }

                    final spots = snapshot.data!.spots;
                    final dates = snapshot.data!.dates;

                    if (spots.isEmpty) {
                      return SizedBox(
                        height: 220,
                        child: Center(child: Text(l10n.noData)),
                      );
                    }

                    return Container(
                      height: 220,
                      padding: const EdgeInsets.fromLTRB(4, 10, 10, 10),

                      child: LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: 6,

                          minY: spots.isEmpty
                              ? 0
                              : spots
                                        .map((e) => e.y)
                                        .reduce((a, b) => a < b ? a : b) -
                                    100,

                          maxY: spots.isEmpty
                              ? 100
                              : spots
                                        .map((e) => e.y)
                                        .reduce((a, b) => a > b ? a : b) +
                                    100,

                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              barWidth: 3,
                              dotData: FlDotData(show: true),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],

                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  int index = value.toInt();
                                  if (index < 0 || index >= dates.length) {
                                    return const SizedBox();
                                  }

                                  final d = dates[index];

                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      "${d.day}/${d.month}",
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                },
                              ),
                            ),

                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 100,
                                reservedSize: 38,
                                getTitlesWidget: (value, meta) {
                                  if (value % 100 != 0) {
                                    return const SizedBox();
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      value.toInt().toString(),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                },
                              ),
                            ),

                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),

                          gridData: FlGridData(
                            show: true,
                            horizontalInterval: 100,
                            verticalInterval: 1,
                          ),

                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  int index = spot.x.toInt();
                                  if (index >= dates.length) {
                                    return null;
                                  }

                                  final d = dates[index];

                                  return LineTooltipItem(
                                    "${d.day}/${d.month}\n${spot.y.toInt()} kcal",
                                    const TextStyle(color: Colors.white),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),

                Text(
                  l10n.analysisHistory,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 20),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("besin_analizleri")
                      .where("uid", isEqualTo: widget.clientId)
                      .orderBy("createdAt", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l10n.noAnalysisYet),
                      );
                    }

                    final groups = _groupBesinDocsByDay(snapshot.data!.docs);

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        return _BesinDayCard(group: groups[index]);
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _removeClientFromDietitian(BuildContext context) async {
    final dietitianId = FirebaseAuth.instance.currentUser?.uid;
    if (dietitianId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            _localized(context, "Danışanla Bağı Kes", "Remove Client"),
          ),
          content: Text(
            _localized(
              context,
              "Bu danışan listenizden çıkarılsın mı?",
              "Remove this client from your list?",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(_localized(context, "İptal", "Cancel")),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(_localized(context, "Çıkar", "Remove")),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final requestQuery = await FirebaseFirestore.instance
        .collection("expert_requests")
        .where("expertId", isEqualTo: dietitianId)
        .where("clientId", isEqualTo: widget.clientId)
        .where("status", isEqualTo: "approved")
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in requestQuery.docs) {
      batch.update(doc.reference, {
        "status": "removed",
        "removedAt": FieldValue.serverTimestamp(),
      });
    }

    batch.update(
      FirebaseFirestore.instance.collection("users").doc(widget.clientId),
      {"assignedDietitian": FieldValue.delete()},
    );

    await batch.commit();

    if (!context.mounted) return;
    Navigator.pop(context);
  }

  String _localized(BuildContext context, String tr, String en) {
    return Localizations.localeOf(context).languageCode == "tr" ? tr : en;
  }

  List<String> _chronicDiseaseLabels(
    AppLocalizations l10n,
    Map<String, dynamic> data,
  ) {
    return [
      if (data["chronicHypertension"] == true) l10n.hypertension,
      if (data["diabetes"] == true) l10n.diabetes,
      if (data["thyroidDisease"] == true) l10n.thyroidDisease,
    ];
  }

  List<String> _doctorRiskLabels(AppLocalizations l10n, dynamic rawFlags) {
    if (rawFlags is! Map) return [];

    final flags = Map<String, dynamic>.from(rawFlags);
    return [
      if (flags["preeklampsi"] == true) l10n.preeklampsiTracking,
      if (flags["diabetes"] == true) l10n.gestationalDiabetes,
      if (flags["preterm"] == true) l10n.pretermRisk,
    ];
  }

  String _riskLevelText(AppLocalizations l10n, dynamic rawRiskLevel) {
    final normalized = rawRiskLevel?.toString().trim().toLowerCase() ?? "";

    if (normalized == "high" ||
        normalized == "high_risk" ||
        normalized == "yüksek") {
      return l10n.highRisk;
    }

    if (normalized == "medium" || normalized == "orta") {
      return l10n.mediumRisk;
    }

    if (normalized == "low" ||
        normalized == "normal" ||
        normalized == "düşük") {
      return l10n.lowRisk;
    }

    return l10n.normalRisk;
  }
}

class _BesinDayCard extends StatelessWidget {
  final _BesinDayGroup group;

  const _BesinDayCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summary = _summarizeBesinDay(group.items);
    final firstTime =
        "${group.items.first.date.hour.toString().padLeft(2, '0')}:${group.items.first.date.minute.toString().padLeft(2, '0')}";
    final lastTime =
        "${group.items.last.date.hour.toString().padLeft(2, '0')}:${group.items.last.date.minute.toString().padLeft(2, '0')}";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BesinAnalizDetayPage(
                docIds: group.items.map((item) => item.id).toList(),
                dayLabel: group.dayLabel,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      group.dayLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                group.items.length == 1
                    ? l10n.analysisWithTime(1, firstTime)
                    : "${group.items.length} analiz ($firstTime - $lastTime)",
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 10),
              const Divider(),
              Text(
                l10n.dailyTotalCalories(summary.calorie.toStringAsFixed(0)),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (summary.missing.isNotEmpty)
                ...summary.missing.take(4).map(
                      (m) => Row(
                        children: [
                          const Icon(Icons.close, color: Colors.red, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              m,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              if (summary.consumed.isNotEmpty)
                Text(
                  "${l10n.consumedNutrients}: ${summary.consumed.take(4).join(", ")}",
                  style: const TextStyle(color: Colors.green),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BesinDayGroup {
  final String dayLabel;
  final List<_BesinAnalysisItem> items;

  const _BesinDayGroup({required this.dayLabel, required this.items});
}

class _BesinAnalysisItem {
  final String id;
  final DateTime date;
  final Map<String, dynamic> data;

  const _BesinAnalysisItem({
    required this.id,
    required this.date,
    required this.data,
  });

  double get calorie {
    final raw = data["kalori"];
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? "") ?? 0;
  }
}

class _BesinSummary {
  final double calorie;
  final List<String> consumed;
  final List<String> missing;

  const _BesinSummary({
    required this.calorie,
    required this.consumed,
    required this.missing,
  });
}

List<_BesinDayGroup> _groupBesinDocsByDay(List<QueryDocumentSnapshot> docs) {
  final groups = <String, List<_BesinAnalysisItem>>{};

  for (final doc in docs) {
    final data = doc.data() as Map<String, dynamic>;
    final date = _readBesinAnalysisDate(data);
    if (date == null) {
      continue;
    }

    final key = "${date.day}/${date.month}/${date.year}";
    groups
        .putIfAbsent(key, () => [])
        .add(_BesinAnalysisItem(id: doc.id, date: date, data: data));
  }

  return groups.entries.map((entry) {
    entry.value.sort((a, b) => a.date.compareTo(b.date));
    return _BesinDayGroup(dayLabel: entry.key, items: entry.value);
  }).toList();
}

DateTime? _readBesinAnalysisDate(Map<String, dynamic> data) {
  final raw = data["createdAt"] ?? data["tarih"];
  if (raw is Timestamp) return raw.toDate();
  if (raw != null) return DateTime.tryParse(raw.toString());
  return null;
}

_BesinSummary _summarizeBesinDay(List<_BesinAnalysisItem> items) {
  final foods = <Map<String, dynamic>>[];
  final supplements = <Map<String, dynamic>>[];

  for (final item in items) {
    final besinler = item.data["besinler"] as List? ?? [];
    final takviyeler = item.data["takviyeler"] as List? ?? [];

    for (final raw in besinler) {
      if (raw is Map) {
        final data = Map<String, dynamic>.from(raw);

        final unitGram = FoodUnits.units[data["format"]] ?? 1;
        final amount = double.tryParse(data["miktar"]?.toString() ?? "0") ?? 0;
        final name = data["ad"]?.toString() ?? "";

        if (name.isNotEmpty && amount > 0) {
          foods.add({"name": name, "amount": unitGram * amount});
        }
      } else if (raw is String) {
        if (raw.trim().isNotEmpty) {
          foods.add({"name": raw.trim(), "amount": 1});
        }
      }
    }

    for (final raw in takviyeler) {
      if (raw is Map) {
        final data = Map<String, dynamic>.from(raw);

        final name = data["ad"]?.toString() ?? "";
        final amount = double.tryParse(data["miktar"]?.toString() ?? "1") ?? 1;

        if (name.isNotEmpty) {
          supplements.add({"name": name, "amount": amount});
        }
      } else if (raw is String) {
        if (raw.trim().isNotEmpty) {
          supplements.add({"name": raw.trim(), "amount": 1});
        }
      }
    }
  }

  final result = NutritionEngine.analyzeFoods(foods, supplements);

  return _BesinSummary(
    calorie: (result["totalCalories"] as num?)?.toDouble() ?? 0,
    consumed: List<String>.from(result["consumedNutrients"] ?? []),
    missing: List<String>.from(result["missingNutrients"] ?? []),
  );
}
