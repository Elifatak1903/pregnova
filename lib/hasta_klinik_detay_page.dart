import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HastaKlinikDetayPage extends StatefulWidget {
  final String clientId;
  final String name;
  final String surname;
  final int initialIndex;

  const HastaKlinikDetayPage({
    super.key,
    required this.clientId,
    required this.name,
    required this.surname,
    required this.initialIndex,
  });

  @override
  State<HastaKlinikDetayPage> createState() =>
      _HastaKlinikDetayPageState();
}

class _HastaKlinikDetayPageState
    extends State<HastaKlinikDetayPage> {

  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: Text("${widget.name} ${widget.surname}"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("risk_olcumleri")
            .where("uid", isEqualTo: widget.clientId)
            .orderBy("tarih", descending: true)
            .limit(30)
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.hasError) {
            return Center(
              child: Text("Hata: ${snapshot.error}"),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("Kayıt bulunamadı"),
            );
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (widget.initialIndex < docs.length) {
              _controller.jumpTo(widget.initialIndex * 180);
            }
          });

          return ListView.builder(
            controller: _controller,
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {

              final data =
              docs[index].data() as Map<String, dynamic>;

              final Timestamp ts = data["tarih"];
              final date = ts.toDate();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6)
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    Text(
                      "${date.day}/${date.month}/${date.year}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 10),

                    _infoRow(
                      "Tansiyon",
                      "${data["sistolik"] ?? "-"} / ${data["diastolik"] ?? "-"}",
                    ),
                    _infoRow("Açlık Şekeri", data["aclikSeker"]),
                    _infoRow("Tokluk Şekeri", data["toklukSeker"]),
                    _infoRow("Stres Seviyesi", data["stresSeviyesi"]),

                    const Divider(height: 25),

                    _boolRow("Baş Ağrısı", data["basAgrisi"]),
                    _boolRow("Görme Bozukluğu", data["gormeBozuklugu"]),
                    _boolRow("Şişlik", data["sislik"]),
                    _boolRow("Karın Kasılması", data["karinKasilma"]),
                    _boolRow("Bel Ağrısı", data["belAgrisi"]),
                    _boolRow("Akıntı", data["akinti"]),

                    const SizedBox(height: 10),

                    _infoRow("Preeklampsi Risk", data["preeklampsiRisk"] ?? "-"),
                    _infoRow("Diyabet Risk", data["diyabetRisk"] ?? "-"),
                    _infoRow("Preterm Risk", data["pretermRisk"] ?? "-"),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _riskRow(String title, String? risk) {
    Color color = Colors.grey;

    if (risk == "HIGH") color = Colors.red;
    else if (risk == "MEDIUM") color = Colors.orange;
    else if (risk == "LOW") color = Colors.green;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            risk ?? "-",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        "$title: ${value ?? '-'}",
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _boolRow(String title, dynamic value) {
    String text = "-";
    Color color = Colors.grey;

    if (value == true) {
      text = "Var";
      color = Colors.red;
    } else if (value == false) {
      text = "Yok";
      color = Colors.green;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }
}