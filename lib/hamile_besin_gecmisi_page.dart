import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'food_units.dart';
import 'l10n/app_localizations.dart';
import 'nutrition_engine.dart';

class HamileBesinGecmisiPage extends StatelessWidget {
  const HamileBesinGecmisiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  l10n.nutritionSupplementHistory,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('besin_analizleri')
                      .where('uid', isEqualTo: uid)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          l10n.noRecordYet,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      );
                    }

                    final groups = _groupDocsByDay(
                      snapshot.data!.docs,
                      Localizations.localeOf(context).toString(),
                    );

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        return _DayCard(group: group);
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

class _DayCard extends StatelessWidget {
  final _DayGroup group;

  const _DayCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summary = _summarizeDay(group.items);

    return Card(
      color: Theme.of(context).colorScheme.surface,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.dayLabel,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Divider(),
            ...group.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _AnalysisSection(index: index, item: item);
            }),
            const Divider(),
            Text(
              l10n.dailyTotalAnalysisResult,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.totalCalories(summary.calorie.toStringAsFixed(0))),
            const SizedBox(height: 8),
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
          ],
        ),
      ),
    );
  }
}

class _AnalysisSection extends StatelessWidget {
  final int index;
  final _AnalysisItem item;

  const _AnalysisSection({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final time = DateFormat("HH:mm", locale).format(item.date);
    final besinler = item.data['besinler'] as List? ?? [];
    final takviyeler = item.data['takviyeler'] as List? ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.analysisWithTime(index + 1, time),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          ...besinler.map((b) => _FoodLine(item: b)),
          ...takviyeler.map((t) => _FoodLine(item: t)),
          Text(
            l10n.calories(
              NumberFormat.decimalPattern(locale).format(item.calorie),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodLine extends StatelessWidget {
  final dynamic item;

  const _FoodLine({required this.item});

  @override
  Widget build(BuildContext context) {
    final data = Map<String, dynamic>.from(item as Map);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(data['ad']?.toString() ?? "-")),
          Text(
            "${data['miktar'] ?? ''} ${data['format'] ?? data['birim'] ?? ''}",
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

class _DayGroup {
  final String dayLabel;
  final List<_AnalysisItem> items;

  const _DayGroup({required this.dayLabel, required this.items});
}

class _AnalysisItem {
  final String id;
  final DateTime date;
  final Map<String, dynamic> data;

  const _AnalysisItem({
    required this.id,
    required this.date,
    required this.data,
  });

  double get calorie {
    final raw = data['kalori'];
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }
}

class _DaySummary {
  final double calorie;
  final List<String> consumed;
  final List<String> missing;
  final List<String> excess;

  const _DaySummary({
    required this.calorie,
    required this.consumed,
    required this.missing,
    required this.excess,
  });
}

List<_DayGroup> _groupDocsByDay(
  List<QueryDocumentSnapshot> docs,
  String locale,
) {
  final groups = <String, List<_AnalysisItem>>{};

  for (final doc in docs) {
    final data = doc.data() as Map<String, dynamic>;
    final date = readAnalysisDate(data);
    if (date == null) continue;

    final key = DateFormat("dd MMMM yyyy", locale).format(date);
    groups
        .putIfAbsent(key, () => [])
        .add(_AnalysisItem(id: doc.id, date: date, data: data));
  }

  return groups.entries.map((entry) {
    entry.value.sort((a, b) => a.date.compareTo(b.date));
    return _DayGroup(dayLabel: entry.key, items: entry.value);
  }).toList();
}

DateTime? readAnalysisDate(Map<String, dynamic> data) {
  final raw = data['createdAt'] ?? data['tarih'];
  if (raw is Timestamp) return raw.toDate();
  if (raw != null) return DateTime.tryParse(raw.toString());
  return null;
}

_DaySummary _summarizeDay(List<_AnalysisItem> items) {
  final foods = <Map<String, dynamic>>[];
  final supplements = <Map<String, dynamic>>[];

  for (final item in items) {
    for (final raw in (item.data['besinler'] as List? ?? [])) {
      final data = Map<String, dynamic>.from(raw as Map);
      final unitGram = FoodUnits.units[data['format']] ?? 1;
      final amount = double.tryParse(data['miktar'].toString()) ?? 0;

      foods.add({'name': data['ad'], 'amount': unitGram * amount});
    }

    for (final raw in (item.data['takviyeler'] as List? ?? [])) {
      final data = Map<String, dynamic>.from(raw as Map);

      supplements.add({'name': data['ad'], 'amount': data['miktar']});
    }
  }

  final result = NutritionEngine.analyzeFoods(foods, supplements);

  return _DaySummary(
    calorie: (result['totalCalories'] as num?)?.toDouble() ?? 0,
    consumed: List<String>.from(result['consumedNutrients'] ?? []),
    missing: List<String>.from(result['missingNutrients'] ?? []),
    excess: List<String>.from(result['excessNutrients'] ?? []),
  );
}
