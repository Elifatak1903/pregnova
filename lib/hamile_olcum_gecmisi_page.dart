import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HamileOlcumGecmisiPage extends StatelessWidget {
  const HamileOlcumGecmisiPage({super.key});

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

              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "Risk Geçmişi",
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
                      .collection('risk_olcumleri')
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
                          "Henüz risk kaydı yok 💗",
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

                        return Card(
                          elevation: 6,
                          margin:
                          const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [

                                Text(
                                  "${tarih.day}.${tarih.month}.${tarih.year}  "
                                      "${tarih.hour}:${tarih.minute}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.pink,
                                  ),
                                ),

                                const Divider(),

                                const Text(
                                  "Preeklampsi",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                _satir(
                                  "Tansiyon",
                                  "${data['sistolik'] ?? "-"} / ${data['diastolik'] ?? "-"}",),
                                _satir("Baş ağrısı",
                                    _boolText(data['basAgrisi'])),
                                _satir("Görme bozukluğu",
                                    _boolText(data['gormeBozuklugu'])),
                                _satir("Şişlik",
                                    _boolText(data['sislik'])),
                                _satir(
                                  "Risk Sonucu",
                                  data['preeklampsiRisk'] ?? "-",
                                ),

                                const SizedBox(height: 10),

                                const Text(
                                  "Gestasyonel Diyabet",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                _satir("Açlık",
                                    "${data['aclikSeker'] ?? "-"}"),
                                _satir("Tokluk",
                                    "${data['toklukSeker'] ?? "-"}"),
                                _satir("Aşırı susama",
                                    _boolText(data['asiriSusama'])),
                                _satir("Sık idrar",
                                    _boolText(data['sikIdrar'])),
                                _satir(
                                  "Risk Sonucu",
                                  data['diyabetRisk'] ?? "-",
                                ),

                                const SizedBox(height: 10),

                                const Text(
                                  "Preterm Risk",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                _satir("Kasılma",
                                    _boolText(data['karinKasilma'])),
                                _satir("Akıntı",
                                    _boolText(data['akinti'])),
                                _satir("Bel ağrısı",
                                    _boolText(data['belAgrisi'])),
                                _satir("Stres",
                                    "${data['stresSeviyesi'] ?? "-"}"),
                                _satir(
                                  "Risk Sonucu",
                                  data['pretermRisk'] ?? "-",
                                ),

                                const SizedBox(height: 10),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      FirebaseFirestore.instance
                                          .collection('risk_olcumleri')
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

  Widget _satir(String title, String value) {

    Color color = Colors.black;

    if (value == "HIGH") color = Colors.red;
    if (value == "MEDIUM") color = Colors.orange;
    if (value == "LOW") color = Colors.green;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static String _boolText(bool? value) {
    if (value == null) return "-";
    return value ? "Evet" : "Hayır";
  }
}