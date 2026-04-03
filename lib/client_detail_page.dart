import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class ClientDetailPage extends StatelessWidget {
  final String clientId;

  const ClientDetailPage({super.key, required this.clientId});

  Future<List<FlSpot>> getWeightSpots() async {
    final query = await FirebaseFirestore.instance
        .collection("risk_olcumleri")
        .where("uid", isEqualTo: clientId)
        .get();

    final docs = query.docs;

    if (docs.isEmpty) return [];

    docs.sort((a, b) {
      final ta = a["tarih"] as Timestamp?;
      final tb = b["tarih"] as Timestamp?;
      if (ta == null || tb == null) return 0;
      return ta.compareTo(tb);
    });

    List<FlSpot> spots = [];

    for (int i = 0; i < docs.length; i++) {

      final rawKilo = docs[i]["kilo"];

      final kilo = (rawKilo is int)
          ? rawKilo.toDouble()
          : (rawKilo is double)
          ? rawKilo
          : 0.0;

      spots.add(FlSpot(i.toDouble(), kilo));
    }

    return spots;
  }

  Future<List<FlSpot>> getCalorieSpots() async {

    final query = await FirebaseFirestore.instance
        .collection("besin_analizleri")
        .where("uid", isEqualTo: clientId)
        .get();

    final docs = query.docs;

    if (docs.isEmpty) return [];

    docs.sort((a, b) {
      final ta = a["tarih"] as Timestamp?;
      final tb = b["tarih"] as Timestamp?;
      if (ta == null || tb == null) return 0;
      return ta.compareTo(tb);
    });

    List<FlSpot> spots = [];

    for (int i = 0; i < docs.length; i++) {

      final rawKalori = docs[i]["kalori"];

      final kalori = (rawKalori is int)
          ? rawKalori.toDouble()
          : (rawKalori is double)
          ? rawKalori
          : 0.0;

      spots.add(FlSpot(i.toDouble(), kalori));
    }

    return spots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text("Danışan Detayı"),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("users")
            .doc(clientId)
            .get(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data =
          snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) {
            return const Center(
              child: Text("Danışan bulunamadı"),
            );
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
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
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

                const Text(
                  "Kilo Grafiği",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                FutureBuilder<List<FlSpot>>(
                  future: getWeightSpots(),
                  builder: (context, snapshot) {

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final spots = snapshot.data ?? [];

                    return Container(
                      height: 220,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: spots.isEmpty
                          ? const Center(
                        child: Text(
                          "Henüz kilo ölçümü girilmemiş",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                          : LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(show: false),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: Colors.green,
                              barWidth: 3,
                              dotData: FlDotData(show: true),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                const Text(
                  "Günlük Kalori Alımı",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                FutureBuilder<List<FlSpot>>(
                  future: getCalorieSpots(),
                  builder: (context, snapshot) {

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final spots = snapshot.data ?? [];

                    return Container(
                      height: 220,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: spots.isEmpty
                          ? const Center(
                        child: Text(
                          "Henüz kalori verisi girilmemiş",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                          : LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(show: false),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: Colors.orange,
                              barWidth: 3,
                              dotData: FlDotData(show: true),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                const Text(
                  "Besin Analizi Geçmişi",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("besin_analizleri")
                      .where("uid", isEqualTo: clientId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    print("BESIN SNAPSHOT COUNT: ${snapshot.data?.docs.length}");

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          "Henüz besin girişi yapılmamış",
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    docs.sort((a, b) {
                      final ta = a["tarih"] as Timestamp?;
                      final tb = b["tarih"] as Timestamp?;
                      if (ta == null || tb == null) return 0;
                      return tb.compareTo(ta);
                    });

                    return Column(
                      children: docs.map((doc) {

                        final tarih =
                        (doc["tarih"] as Timestamp?)?.toDate();

                        final takviyeler =
                            doc["takviyeler"] as List<dynamic>? ?? [];

                        return _BesinCard(
                          tarih: tarih,
                          takviyeler: takviyeler,
                        );

                      }).toList(),
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
class _BesinCard extends StatefulWidget {
  final DateTime? tarih;
  final List<dynamic> takviyeler;

  const _BesinCard({
    required this.tarih,
    required this.takviyeler,
  });

  @override
  State<_BesinCard> createState() => _BesinCardState();
}

class _BesinCardState extends State<_BesinCard> {

  bool expanded = false;

  @override
  Widget build(BuildContext context) {

    final visibleItems = expanded
        ? widget.takviyeler
        : widget.takviyeler.take(5).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          //  Tarih
          Text(
            widget.tarih != null
                ? "${widget.tarih!.day}/${widget.tarih!.month}/${widget.tarih!.year}"
                : "Tarih Yok",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 12),

          //  Besinler
          if (widget.takviyeler.isEmpty)
            const Text(
              "Bu tarihte besin girişi yapılmış ancak analiz yapılmamış",
              style: TextStyle(color: Colors.grey),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: visibleItems.map((t) {

                final ad = t["ad"] ?? "";
                final miktar = t["miktar"] ?? "";

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text("• $ad ($miktar)"),
                );

              }).toList(),
            ),

          if (widget.takviyeler.length > 5)
            TextButton(
              onPressed: () {
                setState(() {
                  expanded = !expanded;
                });
              },
              child: Text(
                expanded ? "Daha Az Göster" : "Tümünü Gör",
                style: const TextStyle(color: Colors.green),
              ),
            ),

          const SizedBox(height: 8),

          const Text(
            "Analiz yapılmadı",
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}