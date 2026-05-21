import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'gynecologist_patient_detail_page.dart';
import 'l10n/app_localizations.dart';

class SonOlcumlerPage extends StatefulWidget {
  final Timestamp? selectedTarih;
  final String? selectedUid;

  const SonOlcumlerPage({super.key, this.selectedTarih, this.selectedUid});

  @override
  State<SonOlcumlerPage> createState() => _SonOlcumlerPageState();
}

class _SonOlcumlerPageState extends State<SonOlcumlerPage> {
  DateTime? selectedDate;
  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.recentMeasurements),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: FutureBuilder<Set<String>>(
        future: _getAssignedPatientIds(),
        builder: (context, assignedSnapshot) {
          if (!assignedSnapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          }

          final assignedPatientIds = assignedSnapshot.data!;

          if (assignedPatientIds.isEmpty) {
            return Center(child: Text(l10n.noRecords));
          }

          return StreamBuilder<QuerySnapshot>(
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

              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final patientId = data["uid"]?.toString();
                if (patientId == null || !assignedPatientIds.contains(patientId)) {
                  return false;
                }
                if (widget.selectedUid != null) {
                  return patientId == widget.selectedUid;
                }
                return true;
              }).toList();

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

              if (widget.selectedTarih != null) {
                final d = widget.selectedTarih!.toDate();
                selectedDate = DateTime(d.year, d.month, d.day);
              } else {
                selectedDate ??= dates.first;
              }

              final filteredDocs = docs.where((doc) {
                final ts = doc["tarih"] as Timestamp;
                final d = ts.toDate();
                final onlyDate = DateTime(d.year, d.month, d.day);
                return onlyDate == selectedDate;
              }).toList();

              int targetIndex = 0;

              if (widget.selectedTarih != null && widget.selectedUid != null) {
                targetIndex = filteredDocs.indexWhere((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  return data["uid"] == widget.selectedUid &&
                      data["tarih"] == widget.selectedTarih;
                });

                if (targetIndex == -1) targetIndex = 0;
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_controller.hasClients) {
                  _controller.jumpTo(targetIndex * 160);
                }
              });

              return ListView(
            controller: _controller,
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 15),
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
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final data =
                      filteredDocs[index].data() as Map<String, dynamic>;

                  final patientId = data["uid"]?.toString() ?? "";
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
                                    tarih != null ? _timeAgo(tarih, l10n) : "",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _infoRow(
                                l10n.bloodPressure,
                                "${data["sistolik"] ?? "-"} / ${data["diastolik"] ?? "-"}",
                              ),
                              _infoRow(
                                l10n.fastingBloodSugar,
                                data["aclikSeker"],
                              ),
                              _infoRow(
                                l10n.postMealBloodSugar,
                                data["toklukSeker"],
                              ),
                              _infoRow(
                                l10n.stress,
                                data["stresSeviyesi"] ?? data["stres"],
                              ),
                              const SizedBox(height: 8),
                              Divider(
                                color: Theme.of(context).dividerColor,
                                height: 18,
                              ),
                              _boolRow(
                                l10n.severeHeadache,
                                data["basAgrisi"],
                                missingMeansNo: true,
                              ),
                              _boolRow(
                                l10n.visionProblem,
                                data["gormeBozuklugu"] ?? data["gorme"],
                                missingMeansNo: true,
                              ),
                              _boolRow(
                                l10n.swelling,
                                data["sislik"],
                                missingMeansNo: true,
                              ),
                              _boolRow(
                                l10n.contraction,
                                data["karinKasilma"] ?? data["kasilma"],
                                missingMeansNo: true,
                              ),
                              _boolRow(
                                l10n.backPain,
                                data["belAgrisi"] ?? data["bel"],
                                missingMeansNo: true,
                              ),
                              _boolRow(
                                l10n.discharge,
                                data["akinti"],
                                missingMeansNo: true,
                              ),
                              const SizedBox(height: 10),
                              _riskRow(
                                context,
                                l10n.preeklampsiTracking,
                                data["preeklampsiRisk"],
                              ),
                              _riskRow(
                                context,
                                l10n.diabetes,
                                data["diyabetRisk"],
                              ),
                              _riskRow(
                                context,
                                l10n.preterm,
                                data["pretermRisk"],
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => HastaDetayPage(
                                          clientId: patientId,
                                          name: name,
                                          surname: surname,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(l10n.detailedReview),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                      ),
                                    ],
                                  ),
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
          );
        },
      ),
    );
  }

  Future<Set<String>> _getAssignedPatientIds() async {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;
    if (doctorId == null) return {};

    final assignedPatients = await FirebaseFirestore.instance
        .collection("users")
        .where("assignedDoctor", isEqualTo: doctorId)
        .get();

    return assignedPatients.docs.map((doc) => doc.id).toSet();
  }

  Widget _infoRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(title), Text(value?.toString() ?? "-")],
      ),
    );
  }

  Widget _riskRow(BuildContext context, String title, dynamic value) {
    final l10n = AppLocalizations.of(context)!;
    final risk = value?.toString();
    final text = _riskText(l10n, risk);
    Color color = Theme.of(context).colorScheme.onSurface;

    if (risk == "HIGH") {
      color = Colors.red;
    } else if (risk == "MEDIUM") {
      color = Colors.orange;
    } else if (risk == "LOW") {
      color = Colors.green;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            text,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _boolRow(
    String title,
    dynamic value, {
    bool missingMeansNo = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    String text = "-";
    Color color = Theme.of(context).colorScheme.onSurface;
    final normalized = _normalizeBool(value);

    if (normalized == true) {
      text = l10n.exists;
      color = Colors.red;
    } else if (normalized == false || missingMeansNo) {
      text = l10n.notExists;
      color = Colors.green;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title)),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  bool? _normalizeBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty) return null;
    if (["true", "evet", "var", "yes", "1"].contains(text)) return true;
    if (["false", "hayır", "hayir", "yok", "no", "0"].contains(text)) {
      return false;
    }

    return null;
  }

  String _timeAgo(Timestamp timestamp, AppLocalizations l10n) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return l10n.secondsAgo(diff.inSeconds);
    if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
    return l10n.daysAgo(diff.inDays);
  }

  String _riskText(AppLocalizations l10n, String? risk) {
    if (risk == "HIGH") return l10n.highRisk;
    if (risk == "MEDIUM") return l10n.mediumRisk;
    if (risk == "LOW") return l10n.lowRisk;
    return risk ?? "-";
  }
}
