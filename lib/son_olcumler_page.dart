import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'hasta_klinik_detay_page.dart';

class SonOlcumlerPage extends StatefulWidget {
  final Timestamp? selectedTarih;
  final String? selectedUid;

  const SonOlcumlerPage({
    super.key,
    this.selectedTarih,
    this.selectedUid,
  });

  @override
  State<SonOlcumlerPage> createState() => _SonOlcumlerPageState();
}

class _SonOlcumlerPageState extends State<SonOlcumlerPage> {
  DateTime? selectedDate;
  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Son Ölçümler"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("risk_olcumleri")
            .orderBy("tarih", descending: true)
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
            return const Center(child: Text("Kayıt yok"));
          }

          /// 🔥 GÜNLER
          final dates = docs.map((doc) {
            final ts = doc["tarih"] as Timestamp;
            final d = ts.toDate();
            return DateTime(d.year, d.month, d.day);
          }).toSet().toList();

          dates.sort((a, b) => b.compareTo(a));

          /// 🔥 TIKLANAN GÜNE GİT
          if (widget.selectedTarih != null) {
            final d = widget.selectedTarih!.toDate();
            selectedDate = DateTime(d.year, d.month, d.day);
          } else {
            selectedDate ??= dates.first;
          }

          /// 🔥 FİLTRE
          final filteredDocs = docs.where((doc) {
            final ts = doc["tarih"] as Timestamp;
            final d = ts.toDate();
            final onlyDate = DateTime(d.year, d.month, d.day);
            return onlyDate == selectedDate;
          }).toList();

          /// 🔥 DOĞRU INDEX BUL
          int targetIndex = 0;

          if (widget.selectedTarih != null && widget.selectedUid != null) {
            targetIndex = filteredDocs.indexWhere((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return data["uid"] == widget.selectedUid &&
                  data["tarih"] == widget.selectedTarih;
            });

            if (targetIndex == -1) targetIndex = 0;
          }

          /// 🔥 SCROLL
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_controller.hasClients) {
              _controller.jumpTo(targetIndex * 160);
            }
          });

          return ListView(
            controller: _controller,
            padding: const EdgeInsets.all(16),
            children: [

              /// 🔥 DROPDOWN
              Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: DropdownButton<DateTime>(
                  value: selectedDate,
                  isExpanded: true,
                  underline: const SizedBox(),
                  onChanged: (value) {
                    setState(() {
                      selectedDate = value;
                    });
                  },
                  items: dates.map((date) {
                    return DropdownMenuItem(
                      value: date,
                      child: Text(
                        "📅 ${date.day}/${date.month}/${date.year}",
                      ),
                    );
                  }).toList(),
                ),
              ),

              /// 🔥 LİSTE
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredDocs.length,

                itemBuilder: (context, index) {

                  final data =
                  filteredDocs[index].data() as Map<String, dynamic>;

                  final patientId = data["uid"];
                  final tarih = data["tarih"] as Timestamp?;

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection("users")
                        .doc(patientId)
                        .get(),

                    builder: (context, userSnap) {

                      if (!userSnap.hasData) {
                        return const SizedBox();
                      }

                      final userData =
                      userSnap.data!.data() as Map<String, dynamic>?;

                      final name = userData?["name"] ?? "";
                      final surname = userData?["surname"] ?? "";

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "$name $surname",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    tarih != null ? _timeAgo(tarih) : "",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              _infoRow("Tansiyon",
                                  "${data["sistolik"] ?? "-"} / ${data["diastolik"] ?? "-"}"),
                              _infoRow("Açlık Şekeri", data["aclikSeker"]),
                              _infoRow("Tokluk Şekeri", data["toklukSeker"]),
                              _infoRow("Stres", data["stresSeviyesi"]),

                              const SizedBox(height: 10),

                              _riskRow(context, "Preeklampsi", data["preeklampsiRisk"]),
                              _riskRow(context, "Diyabet", data["diyabetRisk"]),
                              _riskRow(context, "Preterm", data["pretermRisk"]),

                              const SizedBox(height: 12),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            HastaKlinikDetayPage(
                                              clientId: patientId,
                                              name: name,
                                              surname: surname,
                                              initialIndex: index,
                                            ),
                                      ),
                                    );
                                  },
                                  child: const Text("Detaylı İncele ➜"),
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
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(value?.toString() ?? "-"),
        ],
      ),
    );
  }

  Widget _riskRow(BuildContext context, String title, dynamic value) {
    String text = value?.toString() ?? "-";
    Color color = Theme.of(context).colorScheme.onSurface;

    if (text == "HIGH") color = Colors.red;
    else if (text == "MEDIUM") color = Colors.orange;
    else if (text == "LOW") color = Colors.green;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return "${diff.inSeconds} sn önce";
    if (diff.inMinutes < 60) return "${diff.inMinutes} dk önce";
    if (diff.inHours < 24) return "${diff.inHours} saat önce";
    return "${diff.inDays} gün önce";
  }
}