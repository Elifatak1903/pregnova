import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HamileBesinGecmisiPage extends StatelessWidget {
  const HamileBesinGecmisiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              // Başlık
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "Besin & Takviye Geçmişi",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('besin_analizleri')
                      .where('uid', isEqualTo: uid)
                      .orderBy('tarih', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {

                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "Henüz kayıt yok 💗",
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {

                        final data =
                        docs[index].data() as Map<String, dynamic>;

                        final tarih =
                        (data['tarih'] as Timestamp).toDate();

                        final formattedDate =
                        DateFormat("dd MMMM yyyy - HH:mm", "tr_TR")
                            .format(tarih);

                        final List besinler =
                            data['besinler'] ?? [];

                        final List takviyeler =
                            data['takviyeler'] ?? [];

                        final List consumed = data['consumedNutrients'] ?? [];

                        final List missing = data['missingNutrients'] ?? [];

                        final List excess =
                            data['excessNutrients'] ?? [];

                        return Card(
                          elevation: 6,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [

                                // Tarih
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.pink,
                                  ),
                                ),

                                const Divider(),

                                // BESİNLER
                                if (besinler.isNotEmpty) ...[
                                  const Text(
                                    "Besinler",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ...besinler.map((b) {
                                    return Padding(
                                      padding:
                                      const EdgeInsets.symmetric(vertical: 3),
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(b['ad']),
                                          Text(
                                            "${b['miktar']} ${b['format']}",
                                            style: const TextStyle(
                                                fontWeight:
                                                FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  const SizedBox(height: 10),
                                ],

                                // TAKVİYELER
                                if (takviyeler.isNotEmpty) ...[
                                  const Text(
                                    "Takviyeler",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ...takviyeler.map((t) {
                                    return Padding(
                                      padding:
                                      const EdgeInsets.symmetric(vertical: 3),
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(t['ad']),
                                          Text(
                                            "${t['miktar']} ${t['format']}",
                                            style: const TextStyle(
                                                fontWeight:
                                                FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],

                                const SizedBox(height: 10),

                                if (consumed.isNotEmpty) ...[
                                  const Text("Alınan Besin Öğeleri", style: TextStyle(fontWeight: FontWeight.bold),),
                                  const SizedBox(height: 6),

                                  ...consumed.map((n) {
                                    return Row(
                                      children: [
                                        const Icon(Icons.check_circle,
                                            color: Colors.green, size: 18),
                                        const SizedBox(width: 6),
                                        Text(n),
                                      ],
                                    );
                                  }).toList(),
                                  const SizedBox(height: 10),
                                ],

                                if (missing.isNotEmpty) ...[
                                  const Text("Eksik Besib Öğeleri",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),

                                  ...missing.map((n) {
                                    return Row(
                                      children: [
                                        const Icon(Icons.warning,
                                          color: Colors.orange, size: 18),
                                        const SizedBox(width: 6),
                                        Text(n),
                                      ],
                                    );
                                  }).toList(),
                                ],

                                if (excess.isNotEmpty) ...[
                                  const Text(
                                    "Fazla Besin Öğeleri",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),

                                  const SizedBox(height: 6),

                                  ...excess.map((n) {
                                    return Row(
                                      children: [
                                        const Icon(Icons.arrow_upward,
                                            color: Colors.red, size: 18),
                                        const SizedBox(width: 6),
                                        Text(n),
                                      ],
                                    );
                                  }).toList(),
                                ],

                                const SizedBox(height: 10),

                                // Silme butonu
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      FirebaseFirestore.instance
                                          .collection('besin_analizleri')
                                          .doc(docs[index].id)
                                          .delete();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}