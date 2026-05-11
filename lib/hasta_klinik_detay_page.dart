import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

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
  State<HastaKlinikDetayPage> createState() => _HastaKlinikDetayPageState();
}

class _HastaKlinikDetayPageState extends State<HastaKlinikDetayPage> {
  DateTime? selectedDate;
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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

          final userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};

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

              if (docs.isEmpty) {
                return Center(child: Text(l10n.noRecords));
              }

              final dates = docs
                  .map((doc) {
                    final ts = doc["tarih"] as Timestamp;
                    final d = ts.toDate();
                    return DateTime(d.year, d.month, d.day);
                  })
                  .toSet()
                  .toList();

              dates.sort((a, b) => b.compareTo(a));
              selectedDate ??= dates.first;

              final filteredDocs = docs.where((doc) {
                final ts = doc["tarih"] as Timestamp;
                final d = ts.toDate();
                final onlyDate = DateTime(d.year, d.month, d.day);
                return onlyDate == selectedDate;
              }).toList();

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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
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
                          child: Text("${date.day}/${date.month}/${date.year}"),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ...filteredDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final date = (data["tarih"] as Timestamp).toDate();
                    return _buildRiskCard(context, data, date);
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHealthCard(BuildContext context, Map<String, dynamic> userData) {
    final l10n = AppLocalizations.of(context)!;
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

    final hastaliklar = <String>[];
    if (hipertansiyon) hastaliklar.add(l10n.hypertension);
    if (diyabet) hastaliklar.add(l10n.diabetes);
    if (tiroid) hastaliklar.add(l10n.thyroidDisease);

    final hastalikText = hastaliklar.isEmpty
        ? l10n.notExists
        : hastaliklar.join(", ");

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.personalHealthInfo,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow(l10n.age, yas),
          _infoRow(l10n.currentWeightKg, "$kilo kg"),
          _infoRow(l10n.heightCm, "$boy cm"),
          _infoRow(l10n.pregnancyWeekInput, hafta),
          _infoRow(l10n.bmi, bmi),
          const SizedBox(height: 10),
          Text(
            alerji.isEmpty
                ? "${l10n.allergies}: ${l10n.notExists}"
                : "${l10n.allergies}: $alerji",
            style: TextStyle(
              color: alerji.isEmpty ? null : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "${l10n.chronicDisease}: $hastalikText",
            style: TextStyle(
              color: hastaliklar.isEmpty ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          _infoRow(
            l10n.previousPretermBirth,
            previousPreterm ? l10n.exists : l10n.notExists,
          ),
          _infoRow(
            l10n.multiplePregnancy,
            multiplePregnancy ? l10n.exists : l10n.notExists,
          ),
          _infoRow(l10n.smoking, smoker ? l10n.yes : l10n.no),
        ],
      ),
    );
  }

  Widget _buildRiskCard(
    BuildContext context,
    Map<String, dynamic> data,
    DateTime date,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.2),
            blurRadius: 6,
          ),
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
            l10n.bloodPressure,
            "${data["sistolik"] ?? "-"} / ${data["diastolik"] ?? "-"}",
          ),
          _infoRow(l10n.fastingBloodSugar, data["aclikSeker"]),
          _infoRow(l10n.postMealBloodSugar, data["toklukSeker"]),
          _infoRow(l10n.stressLevel, data["stresSeviyesi"]),
          const Divider(height: 25),
          _boolRow(l10n.severeHeadache, data["basAgrisi"]),
          _boolRow(l10n.visionProblem, data["gormeBozuklugu"]),
          _boolRow(l10n.swelling, data["sislik"]),
          _boolRow(l10n.contraction, data["karinKasilma"]),
          _boolRow(l10n.backPain, data["belAgrisi"]),
          _boolRow(l10n.discharge, data["akinti"]),
          const SizedBox(height: 10),
          _riskRow(l10n.preeklampsiTracking, data["preeklampsiRisk"]),
          _riskRow(l10n.diabetes, data["diyabetRisk"]),
          _riskRow(l10n.preterm, data["pretermRisk"]),
        ],
      ),
    );
  }

  Widget _riskRow(String title, dynamic risk) {
    final l10n = AppLocalizations.of(context)!;
    Color color = Colors.grey;
    final normalized = risk?.toString();

    if (normalized == "HIGH") {
      color = Colors.red;
    } else if (normalized == "MEDIUM") {
      color = Colors.orange;
    } else if (normalized == "LOW") {
      color = Colors.green;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Text(
          _riskText(l10n, normalized),
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
    final l10n = AppLocalizations.of(context)!;
    String text = "-";
    Color color = Colors.grey;

    if (value == true) {
      text = l10n.exists;
      color = Colors.red;
    } else if (value == false) {
      text = l10n.notExists;
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

  String _riskText(AppLocalizations l10n, String? risk) {
    if (risk == "HIGH") return l10n.highRisk;
    if (risk == "MEDIUM") return l10n.mediumRisk;
    if (risk == "LOW") return l10n.lowRisk;
    return risk ?? "-";
  }
}
