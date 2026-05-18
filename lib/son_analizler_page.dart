import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'client_detail_page.dart';
import 'food_units.dart';
import 'l10n/app_localizations.dart';
import 'nutrition_engine.dart';

class SonAnalizlerPage extends StatefulWidget {
  final Timestamp? selectedTarih;
  final String? selectedUid;

  const SonAnalizlerPage({super.key, this.selectedTarih, this.selectedUid});

  @override
  State<SonAnalizlerPage> createState() => _SonAnalizlerPageState();
}

class _SonAnalizlerPageState extends State<SonAnalizlerPage> {
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
    final sevenDaysAgo = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 7)),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.recentAnalyses),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("besin_analizleri")
            .where("createdAt", isGreaterThan: sevenDaysAgo)
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          }

          final docs = snapshot.data!.docs
              .where(
                (doc) => _readDate(doc.data() as Map<String, dynamic>) != null,
              )
              .toList();

          if (docs.isEmpty) {
            return Center(
              child: Text(
                l10n.noAnalysisLast7Days,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }

          final dates = docs
              .map((doc) {
                final date = _readDate(doc.data() as Map<String, dynamic>)!;
                return DateTime(date.year, date.month, date.day);
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
            final date = _readDate(doc.data() as Map<String, dynamic>)!;
            final onlyDate = DateTime(date.year, date.month, date.day);
            return onlyDate == selectedDate;
          }).toList();

          var targetIndex = 0;

          if (widget.selectedTarih != null && widget.selectedUid != null) {
            targetIndex = filteredDocs.indexWhere((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data["uid"] == widget.selectedUid &&
                  data["createdAt"] == widget.selectedTarih;
            });

            if (targetIndex == -1) targetIndex = 0;
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_controller.hasClients) {
              _controller.jumpTo(targetIndex * 250);
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
              ...filteredDocs.asMap().entries.map((entry) {
                final data = entry.value.data() as Map<String, dynamic>;
                final patientId = data["uid"]?.toString() ?? "";

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection("users")
                      .doc(patientId)
                      .get(),
                  builder: (context, userSnap) {
                    if (!userSnap.hasData) {
                      return ListTile(title: Text(l10n.loading));
                    }

                    final userData =
                        userSnap.data!.data() as Map<String, dynamic>?;
                    final name = userData?["name"] ?? "";
                    final surname = userData?["surname"] ?? "";

                    return _AnalysisCard(
                      index: entry.key,
                      data: data,
                      patientId: patientId,
                      name: "$name $surname".trim(),
                    );
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> data;
  final String patientId;
  final String name;

  const _AnalysisCard({
    required this.index,
    required this.data,
    required this.patientId,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final date = _readDate(data);
    final time = date == null ? "-" : DateFormat("HH:mm", locale).format(date);
    final foods = data["besinler"] as List? ?? [];
    final supplements = data["takviyeler"] as List? ?? [];
    final summary = _summaryFromAnalysis(data);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    name.isEmpty ? patientId : name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  l10n.analysisWithTime(index + 1, time),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (foods.isNotEmpty) ...[
              _sectionTitle(context, l10n.consumedFoods),
              ...foods.map((item) => _FoodLine(item: item)),
            ],
            if (supplements.isNotEmpty) ...[
              const SizedBox(height: 8),
              _sectionTitle(context, l10n.supplements),
              ...supplements.map((item) => _FoodLine(item: item)),
            ],
            const Divider(height: 24),
            Text(
              l10n.dailyTotalAnalysisResult,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.totalCalories(summary.calorie.toStringAsFixed(0))),
            _NutrientList(
              title: l10n.consumedNutrients,
              values: summary.consumed,
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            _NutrientList(
              title: l10n.missingNutrients,
              values: summary.missing,
              icon: Icons.warning,
              color: Colors.orange,
            ),
            _NutrientList(
              title: l10n.excessNutrients,
              values: summary.excess,
              icon: Icons.arrow_upward,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClientDetailPage(clientId: patientId),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.detailedReview),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _FoodLine extends StatelessWidget {
  final dynamic item;

  const _FoodLine({required this.item});

  @override
  Widget build(BuildContext context) {
    final data = item is Map ? Map<String, dynamic>.from(item) : {};

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(data["ad"]?.toString() ?? "-")),
          Text(
            "${data["miktar"] ?? ""} ${data["format"] ?? data["birim"] ?? ""}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _NutrientList extends StatelessWidget {
  final String title;
  final List<String> values;
  final IconData icon;
  final Color color;

  const _NutrientList({
    required this.title,
    required this.values,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          ...values.map(
            (value) => Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(value)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionSummary {
  final double calorie;
  final List<String> consumed;
  final List<String> missing;
  final List<String> excess;

  const _NutritionSummary({
    required this.calorie,
    required this.consumed,
    required this.missing,
    required this.excess,
  });
}

DateTime? _readDate(Map<String, dynamic> data) {
  final raw = data["createdAt"] ?? data["tarih"];
  if (raw is Timestamp) return raw.toDate();
  if (raw != null) return DateTime.tryParse(raw.toString());
  return null;
}

_NutritionSummary _summaryFromAnalysis(Map<String, dynamic> data) {
  final consumed = List<String>.from(data["consumedNutrients"] ?? []);
  final missing = List<String>.from(data["missingNutrients"] ?? []);
  final excess = List<String>.from(data["excessNutrients"] ?? []);

  if (consumed.isNotEmpty || missing.isNotEmpty || excess.isNotEmpty) {
    return _NutritionSummary(
      calorie: (data["kalori"] as num?)?.toDouble() ?? 0,
      consumed: consumed,
      missing: missing,
      excess: excess,
    );
  }

  final foods = <Map<String, dynamic>>[];
  final supplements = <Map<String, dynamic>>[];

  for (final raw in (data["besinler"] as List? ?? [])) {
    if (raw is! Map) continue;
    final item = Map<String, dynamic>.from(raw);
    final unitGram = FoodUnits.units[item["format"]] ?? 1;
    final amount = double.tryParse(item["miktar"].toString()) ?? 0;
    foods.add({"name": item["ad"], "amount": unitGram * amount});
  }

  for (final raw in (data["takviyeler"] as List? ?? [])) {
    if (raw is! Map) continue;
    final item = Map<String, dynamic>.from(raw);
    supplements.add({"name": item["ad"], "amount": item["miktar"]});
  }

  final result = NutritionEngine.analyzeFoods(foods, supplements);

  return _NutritionSummary(
    calorie: (result["totalCalories"] as num?)?.toDouble() ?? 0,
    consumed: List<String>.from(result["consumedNutrients"] ?? []),
    missing: List<String>.from(result["missingNutrients"] ?? []),
    excess: List<String>.from(result["excessNutrients"] ?? []),
  );
}
