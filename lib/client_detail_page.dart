import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'besin_analiz_detay_page.dart';
import 'food_units.dart';
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

    final query = await FirebaseFirestore.instance
        .collection("risk_olcumleri")
        .where("uid", isEqualTo: widget.clientId)
        .get();

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));

    List<DateTime> dates = [];
    for (int i = 0; i < 7; i++) {
      dates.add(startDate.add(Duration(days: i)));
    }

    Map<String, double> weightMap = {};

    for (var doc in query.docs) {
      final data = doc.data() as Map<String, dynamic>;

      if (!data.containsKey("tarih") || !data.containsKey("kilo")) continue;

      final ts = data["tarih"];
      final rawKilo = data["kilo"];

      if (ts == null || rawKilo == null) continue;

      DateTime date;

      if (ts is Timestamp) {
        date = ts.toDate();
      } else {
        continue;
      }

      if (date.isBefore(startDate)) continue;

      double kilo = (rawKilo is int)
          ? rawKilo.toDouble()
          : (rawKilo is double)
          ? rawKilo
          : double.tryParse(rawKilo.toString()) ?? 0;
      if (kilo <= 0) continue;
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
      } else {
        kilo = i > 0 ? spots[i - 1].y : 0;
      }

      spots.add(FlSpot(i.toDouble(), kilo));
    }

    return ChartData(spots, dates);
  }

  Future<ChartData> getCalorieSpots() async {

    final query = await FirebaseFirestore.instance
        .collection("besin_analizleri")
        .where("uid", isEqualTo: widget.clientId)
        .get();

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));

    List<DateTime> dates = [];
    for (int i = 0; i < 7; i++) {
      dates.add(startDate.add(Duration(days: i)));
    }

    Map<String, double> calorieMap = {};

    for (var doc in query.docs) {
      final data = doc.data() as Map<String, dynamic>;

      if (!data.containsKey("createdAt") || !data.containsKey("kalori")) continue;

      final ts = data["createdAt"];
      final raw = data["kalori"];

      if (ts == null || raw == null) continue;

      DateTime date;

      if (ts is Timestamp) {
        date = ts.toDate();
      } else {
        continue;
      }

      if (date.isBefore(startDate)) continue;

      double kalori = (raw is int)
          ? raw.toDouble()
          : (raw is double)
          ? raw
          : double.tryParse(raw.toString()) ?? 0;

      if (kalori <= 0) continue;

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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Danışan Detayı"),
        backgroundColor: Theme.of(context).colorScheme.primary,
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

          final data =
          snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) {
            return const Center(child: Text("Danışan bulunamadı"));
          }

          final name = data["name"] ?? "";
          final surname = data["surname"] ?? "";
          final hafta = data["hafta"] ?? "-";
          final kilo = data["kilo"] ?? "-";
          final alerji = data["alerjiler"] ?? "";

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
                        Text("Gebelik Haftası: $hafta"),
                        const SizedBox(height: 10),
                        Text("Güncel Kilo: $kilo kg"),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.red, size: 18),
                            const SizedBox(width: 6),
                            Text("Alerjiler: $alerji"),
                          ],
                        )
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                Text(
                  "Kilo Grafiği",
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
                      print("❌ WEIGHT ERROR: ${snapshot.error}");
                      return SizedBox(
                        height: 220,
                        child: Center(
                          child: Text("Hata: ${snapshot.error}"),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const SizedBox(
                        height: 220,
                        child: Center(child: Text("Veri alınamadı")),
                      );
                    }

                    final spots = snapshot.data!.spots;
                    final dates = snapshot.data!.dates;

                    return Container(
                      height: 220,

                      padding: const EdgeInsets.fromLTRB(4, 10, 10, 10),

                      child: spots.isEmpty
                          ? const Center(child: Text("Veri yok"))
                          : LineChart(
                        LineChartData(

                          minX: 0,
                          maxX: 6,


                          minY: spots.isEmpty
                              ? 0
                              : spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 2,

                          maxY: spots.isEmpty
                              ? 10
                              : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 2,

                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              curveSmoothness: 0.3,
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

                                  if (index < 0 || index > 6 || index >= dates.length) {
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
                                interval: 5,
                                reservedSize: 38,

                                getTitlesWidget: (value, meta) {
                                  if (value % 5 != 0) return const SizedBox();

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
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
                                color: Colors.grey.withOpacity(0.2),
                                strokeWidth: 1,
                              );
                            },

                            getDrawingVerticalLine: (value) {
                              return FlLine(
                                color: Colors.grey.withOpacity(0.15),
                                strokeWidth: 1,
                              );
                            },
                          ),

                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  int index = spot.x.toInt();

                                  if (index < 0 || index > 6 || index >= dates.length) {
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
                  "Kalori Grafiği",
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
                      print("❌ CALORIE ERROR: ${snapshot.error}");
                      return const SizedBox(
                        height: 220,
                        child: Center(child: Text("Hata oluştu")),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      print("⏳ CALORIE LOADING...");
                      return const SizedBox(
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (!snapshot.hasData) {
                      print("❌ CALORIE DATA YOK");
                      return const SizedBox(
                        height: 220,
                        child: Center(child: Text("Veri alınamadı")),
                      );
                    }

                    final spots = snapshot.data!.spots;
                    final dates = snapshot.data!.dates;

                    print("📊 CALORIE SPOTS: ${spots.length}");

                    if (spots.isEmpty) {
                      print("⚠️ CALORIE BOŞ");
                      return const SizedBox(
                        height: 220,
                        child: Center(child: Text("Veri yok")),
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
                              : spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 100,

                          maxY: spots.isEmpty
                              ? 100
                              : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 100,

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

                                  if (value % 100 != 0) return const SizedBox();

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
                                  if (index >= dates.length) return null;

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
                  "Analiz Geçmişi",
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
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text("Henüz analiz yok"),
                      );
                    }

                    final groups = groupBesinDocsByDay(snapshot.data!.docs);

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
}

class _BesinCard extends StatelessWidget {
  final DateTime? tarih;
  final List<dynamic> takviyeler;
  final double kalori;
  final String docId;
  final List<dynamic> missingNutrients;

  const _BesinCard({
    required this.tarih,
    required this.takviyeler,
    required this.kalori,
    required this.docId,
    required this.missingNutrients,
  });

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BesinAnalizDetayPage(docId: docId),
          ),
        );
      },

      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.15),
              blurRadius: 6,
            )
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              tarih != null
                  ? "${tarih!.day}/${tarih!.month}/${tarih!.year}"
                  : "Tarih Yok",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Toplam Kalori: ${kalori.toStringAsFixed(0)} kcal",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 10),

            if (missingNutrients.isNotEmpty)
              ...missingNutrients.take(3).map((m) {
                return Row(
                  children: [
                    const Icon(Icons.close, color: Colors.red, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        m.toString(),
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                );
              }),

            if (takviyeler.isNotEmpty)
              ...takviyeler.take(3).map((t) {

                final name = t is Map ? t["ad"] ?? "" : t.toString();

                return Row(
                  children: [
                    Icon(Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                        size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                );
              }),

            if (takviyeler.length > 3)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text("..."),
              ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Detaylı İncele",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BesinDayCard extends StatelessWidget {
  final _BesinDayGroup group;

  const _BesinDayCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final summary = summarizeBesinDay(group.items);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.15),
            blurRadius: 6,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.dayLabel,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          ...group.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final takviyeler = (item.data["takviyeler"] as List?) ?? [];
            final time =
                "${item.date.hour.toString().padLeft(2, '0')}:${item.date.minute.toString().padLeft(2, '0')}";

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BesinAnalizDetayPage(docId: item.id),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${index + 1}. Analiz - $time",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text("Kalori: ${item.calorie.toStringAsFixed(0)} kcal"),
                    if (takviyeler.isNotEmpty)
                      Text(
                        "Takviyeler: ${takviyeler.map((t) => t is Map ? t["ad"] ?? "" : t.toString()).take(3).join(", ")}",
                      ),
                  ],
                ),
              ),
            );
          }),
          const Divider(),
          Text(
            "Günlük Toplam: ${summary.calorie.toStringAsFixed(0)} kcal",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (summary.missing.isNotEmpty)
            ...summary.missing.take(4).map((m) => Row(
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
                )),
          if (summary.consumed.isNotEmpty)
            Text(
              "Alınanlar: ${summary.consumed.take(4).join(", ")}",
              style: const TextStyle(color: Colors.green),
            ),
        ],
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

List<_BesinDayGroup> groupBesinDocsByDay(List<QueryDocumentSnapshot> docs) {
  final groups = <String, List<_BesinAnalysisItem>>{};

  for (final doc in docs) {
    final data = doc.data() as Map<String, dynamic>;
    final date = readBesinAnalysisDate(data);
    if (date == null) continue;

    final key = "${date.day}/${date.month}/${date.year}";
    groups.putIfAbsent(key, () => []).add(
          _BesinAnalysisItem(id: doc.id, date: date, data: data),
        );
  }

  return groups.entries.map((entry) {
    entry.value.sort((a, b) => a.date.compareTo(b.date));
    return _BesinDayGroup(dayLabel: entry.key, items: entry.value);
  }).toList();
}

DateTime? readBesinAnalysisDate(Map<String, dynamic> data) {
  final raw = data["createdAt"] ?? data["tarih"];
  if (raw is Timestamp) return raw.toDate();
  if (raw != null) return DateTime.tryParse(raw.toString());
  return null;
}

_BesinSummary summarizeBesinDay(List<_BesinAnalysisItem> items) {
  final foods = <Map<String, dynamic>>[];
  final supplements = <Map<String, dynamic>>[];

  for (final item in items) {
    for (final raw in (item.data["besinler"] as List? ?? [])) {
      final data = Map<String, dynamic>.from(raw as Map);
      final unitGram = FoodUnits.units[data["format"]] ?? 1;
      final amount = double.tryParse(data["miktar"].toString()) ?? 0;

      foods.add({
        "name": data["ad"],
        "amount": unitGram * amount,
      });
    }

    for (final raw in (item.data["takviyeler"] as List? ?? [])) {
      final data = Map<String, dynamic>.from(raw as Map);

      supplements.add({
        "name": data["ad"],
        "amount": data["miktar"],
      });
    }
  }

  final result = NutritionEngine.analyzeFoods(foods, supplements);

  return _BesinSummary(
    calorie: (result["totalCalories"] as num?)?.toDouble() ?? 0,
    consumed: List<String>.from(result["consumedNutrients"] ?? []),
    missing: List<String>.from(result["missingNutrients"] ?? []),
  );
}
