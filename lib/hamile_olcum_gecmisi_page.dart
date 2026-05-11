import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'l10n/app_localizations.dart';

class HamileOlcumGecmisiPage extends StatelessWidget {
  const HamileOlcumGecmisiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.riskHistory),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('risk_olcumleri')
                .where('uid', isEqualTo: uid)
                .orderBy('tarih', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    l10n.noRiskRecordYet,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final tarih = (data['tarih'] as Timestamp).toDate();

                  return Card(
                    color: Theme.of(context).colorScheme.surface,
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${tarih.day}.${tarih.month}.${tarih.year}  "
                            "${tarih.hour.toString().padLeft(2, '0')}:${tarih.minute.toString().padLeft(2, '0')}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const Divider(),
                          const Text(
                            "Preeklampsi",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          _satir(
                            context,
                            l10n.bloodPressure,
                            "${data['sistolik'] ?? "-"} / ${data['diastolik'] ?? "-"}",
                          ),
                          _satir(
                            context,
                            l10n.severeHeadache,
                            _boolText(context, data['basAgrisi']),
                          ),
                          _satir(
                            context,
                            l10n.visionProblem,
                            _boolText(context, data['gormeBozuklugu']),
                          ),
                          _satir(
                            context,
                            l10n.handFaceSwelling,
                            _boolText(context, data['sislik']),
                          ),
                          _satir(
                            context,
                            l10n.riskOutcome,
                            data['preeklampsiRisk'] ?? "-",
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.gestationalDiabetes,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          _satir(
                            context,
                            l10n.fasting,
                            "${data['aclikSeker'] ?? "-"}",
                          ),
                          _satir(
                            context,
                            l10n.postMeal,
                            "${data['toklukSeker'] ?? "-"}",
                          ),
                          _satir(
                            context,
                            l10n.excessiveThirst,
                            _boolText(context, data['asiriSusama']),
                          ),
                          _satir(
                            context,
                            l10n.frequentUrination,
                            _boolText(context, data['sikIdrar']),
                          ),
                          _satir(
                            context,
                            l10n.riskOutcome,
                            data['diyabetRisk'] ?? "-",
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.pretermRisk,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          _satir(
                            context,
                            l10n.contraction,
                            _boolText(context, data['karinKasilma']),
                          ),
                          _satir(
                            context,
                            l10n.increasedDischarge,
                            _boolText(context, data['akinti']),
                          ),
                          _satir(
                            context,
                            l10n.backPain,
                            _boolText(context, data['belAgrisi']),
                          ),
                          _satir(
                            context,
                            l10n.stress,
                            "${data['stresSeviyesi'] ?? "-"}",
                          ),
                          _satir(
                            context,
                            l10n.riskOutcome,
                            data['pretermRisk'] ?? "-",
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
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
      ),
    );
  }

  Widget _satir(BuildContext context, String title, String value) {
    var color = Theme.of(context).colorScheme.onSurface;

    if (value == "HIGH") color = Colors.red;
    if (value == "MEDIUM") color = Colors.orange;
    if (value == "LOW") color = Colors.green;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  static String _boolText(BuildContext context, bool? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null) return "-";
    return value ? l10n.yes : l10n.no;
  }
}
