import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'hasta_klinik_detay_page.dart';

class HastaDetayPage extends StatelessWidget {
  final String clientId;
  final String name;
  final String surname;

  const HastaDetayPage({
    super.key,
    required this.clientId,
    required this.name,
    required this.surname,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: const Text("Hasta Detayı"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [

            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("users")
                  .doc(clientId)
                  .get(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  );
                }

                final data =
                snapshot.data!.data() as Map<String, dynamic>?;

                final hafta = data?["hafta"] ?? "-";
                final risk = data?["riskLevel"] ?? "normal";

                Color riskColor =
                risk == "high"
                    ? Colors.red
                    : risk == "medium"
                    ? Colors.orange
                    : Colors.green;

                String riskText =
                risk == "high"
                    ? "Yüksek Risk"
                    : risk == "medium"
                    ? "Orta Risk"
                    : "Normal";

                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$name $surname",
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text("Gebelik Haftası: $hafta"),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: riskColor,
                          borderRadius:
                          BorderRadius.circular(20),
                        ),
                        child: Text(
                          riskText,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            const Text(
              "Son 7 Gün Ölçüm Grafikleri",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("risk_olcumleri")
                  .where("uid", isEqualTo: clientId)
                  .orderBy("tarih", descending: false)
                  .limit(7)
                  .snapshots(),
              builder: (context, snapshot) {

                if (snapshot.hasError) {
                  return Text("Hata: ${snapshot.error}");
                }

                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Text("Ölçüm bulunamadı");
                }

                return Column(
                  children: [
                    _buildTansiyonChart(docs),
                    const SizedBox(height: 30),
                    _buildSekerChart(docs),
                    const SizedBox(height: 30),
                    _buildKiloChart(docs),
                  ],
                );
              },
            ),

            const SizedBox(height: 30),

            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  minimumSize:
                  const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          HastaKlinikDetayPage(
                            clientId: clientId,
                            name: name,
                            surname: surname,
                            initialIndex: 0,
                          ),
                    ),
                  );
                },
                child: const Text(
                  "Detaylı Klinik Analizi Gör",
                  style:
                  TextStyle(color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTansiyonChart(
      List<QueryDocumentSnapshot> docs) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Text(
            "Tansiyon Grafiği (Sistolik)",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(height: 15),

        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              minY: 80,
              maxY: 200,
              barGroups:
              List.generate(docs.length, (i) {

                final data = docs[i].data() as Map<String, dynamic>;

                final sistolik =
                    double.tryParse(data["sistolik"]?.toString() ?? "0") ?? 0;

                final diastolik =
                    double.tryParse(data["diastolik"]?.toString() ?? "0") ?? 0;

                return BarChartGroupData(
                  x: i,
                  barsSpace: 4,
                  barRods: [
                    BarChartRodData(
                      toY: sistolik,
                      color: Colors.pink,
                      width: 8,
                    ),
                    BarChartRodData(
                      toY: diastolik,
                      color: Colors.blue,
                      width: 8,
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSekerChart(
      List<QueryDocumentSnapshot> docs) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Text(
            "Kan Şekeri (Açlık / Tokluk)",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(height: 15),

        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              minY: 60,
              maxY: 200,
              barGroups:
              List.generate(docs.length, (i) {

                final data =
                docs[i].data() as Map<String, dynamic>;

                final aclik =
                    double.tryParse(
                        data["aclikSeker"]
                            ?.toString() ??
                            "0") ??
                        0;

                final tokluk =
                    double.tryParse(
                        data["toklukSeker"]
                            ?.toString() ??
                            "0") ??
                        0;

                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: aclik,
                      color: Colors.orange,
                      width: 10,
                    ),
                    BarChartRodData(
                      toY: tokluk,
                      color: Colors.blue,
                      width: 10,
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKiloChart(List<QueryDocumentSnapshot> docs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Text(
            "Kilo Değişim Grafiği",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 15),

        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              minY: 40,
              maxY: 120,
              barGroups: List.generate(docs.length, (i) {

                final data =
                docs[i].data() as Map<String, dynamic>;

                final kilo =
                    double.tryParse(data["kilo"]?.toString() ?? "0") ?? 0;

                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: kilo,
                      color: Colors.purple,
                      width: 14,
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 6)
      ],
    );
  }
}