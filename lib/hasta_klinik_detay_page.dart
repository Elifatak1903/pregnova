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
  DateTime? selectedDate;

  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {

    final sevenDaysAgo =
    DateTime.now().subtract(const Duration(days: 7));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text("${widget.name} ${widget.surname}"),
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(widget.clientId)
            .snapshots(),
        builder: (context, userSnap) {

          if (!userSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData =
              userSnap.data!.data() as Map<String, dynamic>? ?? {};

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("risk_olcumleri")
                .where("uid", isEqualTo: widget.clientId)
                .orderBy("tarih", descending: true)
                .limit(30)
                .snapshots(),

            builder: (context, snapshot) {

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              /// 🔥 TÜM GÜNLERİ ÇIKAR
              final dates = docs.map((doc) {
                final ts = doc["tarih"] as Timestamp;
                final d = ts.toDate();
                return DateTime(d.year, d.month, d.day);
              }).toSet().toList();

              dates.sort((a, b) => b.compareTo(a));

              /// 🔥 DEFAULT SON GÜN
              selectedDate ??= dates.first;

              /// 🔥 FİLTRE
              final filteredDocs = docs.where((doc) {
                final ts = doc["tarih"] as Timestamp;
                final d = ts.toDate();
                final onlyDate = DateTime(d.year, d.month, d.day);
                return onlyDate == selectedDate;
              }).toList();

              if (docs.isEmpty) {
                return const Center(child: Text("Kayıt bulunamadı"));
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_controller.hasClients) {
                  _controller.jumpTo(widget.initialIndex * 160);
                }
              });

              return ListView(
                controller: _controller,
                padding: const EdgeInsets.all(16),
                children: [

                  _buildHealthCard(context, userData),

                  const SizedBox(height: 10),
                  /// 🔥 GÜN SEÇİCİ
                  Container(
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
                            "${date.day}/${date.month}/${date.year}",
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  ...filteredDocs.map((doc) {

                    final data =
                    doc.data() as Map<String, dynamic>;

                    final date =
                    (data["tarih"] as Timestamp).toDate();

                    return _buildRiskCard(context, data, date);

                  }).toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHealthCard(
      BuildContext context,
      Map<String, dynamic> userData) {

    final yas = userData["yas"] ?? "-";
    final kilo = userData["kilo"] ?? "-";
    final boy = userData["boy"] ?? "-";
    final hafta = userData["hafta"] ?? "-";
    final bmi = userData["bmi"] ?? "-";
    final alerji = userData["alerjiler"] ?? "";

    final hipertansiyon = userData["chronicHypertension"] == true;
    final diyabet = userData["diabetes"] == true;
    final tiroid = userData["thyroidDisease"] == true;

    final previousPreterm = userData["previousPreterm"] == true;
    final multiplePregnancy = userData["multiplePregnancy"] == true;
    final smoker = userData["smoker"] == true;

    List<String> hastaliklar = [];
    if (hipertansiyon) hastaliklar.add("Hipertansiyon");
    if (diyabet) hastaliklar.add("Diyabet");
    if (tiroid) hastaliklar.add("Tiroid");

    final hastalikText =
    hastaliklar.isEmpty ? "Yok" : hastaliklar.join(", ");

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context)
                .shadowColor
                .withOpacity(0.1),
            blurRadius: 6,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            "Kişi Sağlık Bilgileri",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          const SizedBox(height: 12),

          _infoRow("Yaş", yas),
          _infoRow("Kilo", "$kilo kg"),
          _infoRow("Boy", "$boy cm"),
          _infoRow("Gebelik Haftası", hafta),
          _infoRow("BMI", bmi),

          const SizedBox(height: 10),

          Text(
            alerji.isEmpty
                ? "Alerji: Yok"
                : "Alerjiler: $alerji",
            style: TextStyle(
              color: alerji.isEmpty ? null : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "Kronik Hastalık: $hastalikText",
            style: TextStyle(
              color: hastaliklar.isEmpty
                  ? Colors.green
                  : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 10),

          _infoRow("Önceki Erken Doğum",
              previousPreterm ? "Var" : "Yok"),
          _infoRow("Çoğul Gebelik",
              multiplePregnancy ? "Var" : "Yok"),
          _infoRow("Sigara",
              smoker ? "İçiyor" : "İçmiyor"),
        ],
      ),
    );
  }

  Widget _buildRiskCard(
      BuildContext context,
      Map<String, dynamic> data,
      DateTime date) {

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.2),
            blurRadius: 6,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            "${date.day}/${date.month}/${date.year}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
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

          _riskRow("Preeklampsi", data["preeklampsiRisk"]),
          _riskRow("Diyabet", data["diyabetRisk"]),
          _riskRow("Preterm", data["pretermRisk"]),
        ],
      ),
    );
  }

  Widget _riskRow(String title, String? risk) {
    Color color = Colors.grey;

    if (risk == "HIGH") color = Colors.red;
    else if (risk == "MEDIUM") color = Colors.orange;
    else if (risk == "LOW") color = Colors.green;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Text(
          risk ?? "-",
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _infoRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text("$title: ${value ?? '-'}"),
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}