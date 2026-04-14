import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BesinAnalizDetayPage extends StatelessWidget {
  final String docId;

  const BesinAnalizDetayPage({
    super.key,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,

      appBar: AppBar(
        title: const Text("Besin Analizi Detayı"),
        backgroundColor: Colors.green,
      ),

      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("besin_analizleri")
            .doc(docId)
            .get(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("Analiz bulunamadı"),
            );
          }

          final data =
          snapshot.data!.data() as Map<String, dynamic>;

          final tarih = data["tarih"] != null
              ? (data["tarih"] as Timestamp).toDate()
              : null;

          final kalori = (data["kalori"] ?? 0).toDouble();

          final foods = data["foodDetails"] ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              Container(
                padding: const EdgeInsets.all(16),
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

                    Text(
                      tarih != null
                          ? "${tarih.day}/${tarih.month}/${tarih.year}"
                          : "Tarih yok",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Toplam Kalori: ${kalori.toInt()} kcal",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Tüketilen Besinler",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              ...foods.map((food) {

                final name = food["name"] ?? "";
                final amount = food["amount"] ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4)
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [

                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      Text(
                        "$amount gr",
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );

              }).toList(),
            ],
          );
        },
      ),
    );
  }
}