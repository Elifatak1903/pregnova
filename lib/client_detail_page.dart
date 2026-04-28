import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'besin_analiz_detay_page.dart';

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

    final docs = query.docs;

    if (docs.isEmpty) return ChartData([], []);

    docs.sort((a, b) {
      final ta = a["tarih"];
      final tb = b["tarih"];

      if (ta == null && tb == null) return 0;
      if (ta == null) return -1;
      if (tb == null) return 1;

      return (ta as Timestamp).compareTo(tb as Timestamp);
    });

    List<FlSpot> spots = [];
    List<DateTime> dates = [];

    for (var doc in docs) {

      final data = doc.data() as Map<String, dynamic>;

      final rawKilo = data["kilo"];
      final ts = data["tarih"];

      if (rawKilo == null || ts == null) continue;

      double kilo;
      if (rawKilo is int) {
        kilo = rawKilo.toDouble();
      } else if (rawKilo is double) {
        kilo = rawKilo;
      } else if (rawKilo is String) {
        kilo = double.tryParse(rawKilo) ?? 0;
      } else {
        kilo = 0;
      }

      if (kilo <= 0) continue;

      final date = ts is Timestamp
          ? ts.toDate()
          : ts as DateTime;

      double x = spots.length.toDouble();

      spots.add(FlSpot(x, kilo));
      dates.add(date);
    }

    return ChartData(spots, dates);
  }

  Future<ChartData> getCalorieSpots() async {

    final query = await FirebaseFirestore.instance
        .collection("besin_analizleri")
        .where("uid", isEqualTo: widget.clientId)
        .get();

    final docs = query.docs;

    if (docs.isEmpty) return ChartData([], []);

    // 🔥 createdAt'e göre sırala
    docs.sort((a, b) {
      final ta = a["createdAt"];
      final tb = b["createdAt"];

      if (ta == null && tb == null) return 0;
      if (ta == null) return -1;
      if (tb == null) return 1;

      return (ta as Timestamp).compareTo(tb as Timestamp);
    });

    List<FlSpot> spots = [];
    List<DateTime> dates = [];

    for (var doc in docs) {

      final data = doc.data() as Map<String, dynamic>;

      final raw = data["kalori"];

      double kalori;
      if (raw is int) {
        kalori = raw.toDouble();
      } else if (raw is double) {
        kalori = raw;
      } else if (raw is String) {
        kalori = double.tryParse(raw) ?? 0;
      } else {
        kalori = 0;
      }

      if (kalori <= 0) continue;

      final ts = data["createdAt"];
      if (ts == null) continue;

      final date = ts is Timestamp
          ? ts.toDate()
          : ts as DateTime;

      double x = spots.length.toDouble();

      spots.add(FlSpot(x, kalori));
      dates.add(date);
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

                    if (!snapshot.hasData) {
                      return const SizedBox(
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final spots = snapshot.data!.spots;
                    final dates = snapshot.data!.dates;

                    return Container(
                      height: 220,
                      padding: const EdgeInsets.all(10),
                      child: spots.isEmpty
                          ? const Center(child: Text("Veri yok"))
                          : LineChart(
                        LineChartData(
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
                                getTitlesWidget: (value, meta) {

                                  int index = value.toInt();

                                  if (index < 0 || index >= dates.length) {
                                    return const SizedBox();
                                  }

                                  final d = dates[index];

                                  return Text(
                                    "${d.day}/${d.month}",
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
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

                    /// ❌ HATA
                    if (snapshot.hasError) {
                      print("❌ CALORIE ERROR: ${snapshot.error}");
                      return const SizedBox(
                        height: 220,
                        child: Center(child: Text("Hata oluştu")),
                      );
                    }

                    /// ⏳ LOADING
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      print("⏳ CALORIE LOADING...");
                      return const SizedBox(
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    /// 🚨 DATA YOK
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

                    /// 📭 BOŞ VERİ
                    if (spots.isEmpty) {
                      print("⚠️ CALORIE BOŞ");
                      return const SizedBox(
                        height: 220,
                        child: Center(child: Text("Veri yok")),
                      );
                    }

                    return Container(
                      height: 220,
                      padding: const EdgeInsets.all(10),

                      child: LineChart(
                        LineChartData(

                          /// 📈 ÇİZGİ
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              barWidth: 3,
                              color: Theme.of(context).colorScheme.primary,
                              dotData: FlDotData(show: true),
                            ),
                          ],

                          /// 🧭 AXIS
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,

                                getTitlesWidget: (value, meta) {

                                  int index = value.toInt();

                                  if (index < 0 || index >= dates.length) {
                                    return const SizedBox();
                                  }

                                  final d = dates[index];

                                  return Text(
                                    "${d.day}/${d.month}",
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),

                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),

                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),

                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),

                          /// 🎯 TOOLTIP
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

                    final docs = snapshot.data!.docs;

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {

                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final ts = data["createdAt"];
                        final tarih = ts is Timestamp
                            ? ts.toDate()
                            : null;

                        final rawKalori = data["kalori"];
                        double kalori;

                        if (rawKalori is int) {
                          kalori = rawKalori.toDouble();
                        } else if (rawKalori is double) {
                          kalori = rawKalori;
                        } else if (rawKalori is String) {
                          kalori = double.tryParse(rawKalori) ?? 0;
                        } else {
                          kalori = 0;
                        }

                        final takviyeler = (data["takviyeler"] as List?) ?? [];
                        final eksikler = (data["missingNutrients"] as List?) ?? [];

                        return _BesinCard(
                          tarih: tarih,
                          takviyeler: takviyeler,
                          kalori: kalori,
                          docId: doc.id,
                          missingNutrients: eksikler,
                        );
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