import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'food_units.dart';
import 'l10n/app_localizations.dart';
import 'nutrition_engine.dart';

class BesinAnalizDetayPage extends StatelessWidget {
  final List<String> docIds;
  final String? dayLabel;

  BesinAnalizDetayPage({
    super.key,
    String? docId,
    List<String>? docIds,
    this.dayLabel,
  }) : docIds = docIds ?? [docId!];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.nutritionAnalysisDetail),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _loadDocs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs =
              snapshot.data?.where((doc) => doc.exists).toList() ?? [];

          if (docs.isEmpty) {
            return Center(child: Text(l10n.analysisNotFound));
          }

          final analyses = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _AnalysisDetailItem(
              data: data,
              date: _readDate(data),
              foods: _readFoods(data),
              supplements: _readSupplements(data),
              calories: (data["kalori"] as num?)?.toDouble() ?? 0,
            );
          }).toList()
            ..sort((a, b) {
              final first = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
              final second = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
              return first.compareTo(second);
            });

          final totalFoods = <Map<String, dynamic>>[];
          final totalSupplements = <Map<String, dynamic>>[];

          for (final analysis in analyses) {
            totalFoods.addAll(analysis.foods);
            totalSupplements.addAll(analysis.supplements);
          }

          final totalAnalysis = NutritionEngine.analyzeFoods(
            totalFoods,
            totalSupplements,
          );

          final totalCalories =
              (totalAnalysis["totalCalories"] as num?)?.toDouble() ??
                  analyses.fold<double>(
                    0,
                    (total, item) => total + item.calories,
                  );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(context, radius: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayLabel ?? _dateLabel(analyses.first.date, l10n),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.totalCalories(totalCalories.toStringAsFixed(0)),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _summaryCard(context, totalAnalysis),
              const SizedBox(height: 20),
              Text(
                l10n.consumedFoods,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              if (totalFoods.isEmpty && totalSupplements.isEmpty)
                Center(child: Text(l10n.noItemsYet))
              else ...[
                ...totalFoods.map((food) => _itemCard(context, food, "gr")),
                if (totalSupplements.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.supplements,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...totalSupplements.map(
                    (supplement) => _itemCard(context, supplement, ""),
                  ),
                ],
              ],
              const SizedBox(height: 20),
              Text(
                l10n.analysisHistory,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              ...analyses.asMap().entries.map((entry) {
                final index = entry.key;
                final analysis = entry.value;
                final time = analysis.date == null
                    ? "-"
                    : "${analysis.date!.hour.toString().padLeft(2, '0')}:${analysis.date!.minute.toString().padLeft(2, '0')}";

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: _cardDecoration(context, radius: 14),
                  child: Text(
                    "${l10n.analysisWithTime(index + 1, time)} - ${l10n.calories(analysis.calories.toStringAsFixed(0))}",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Future<List<DocumentSnapshot>> _loadDocs() {
    return Future.wait(
      docIds.map(
        (id) => FirebaseFirestore.instance
            .collection("besin_analizleri")
            .doc(id)
            .get(),
      ),
    );
  }

  DateTime? _readDate(Map<String, dynamic> data) {
    final raw = data["createdAt"] ?? data["tarih"];
    if (raw is Timestamp) return raw.toDate();
    if (raw != null) return DateTime.tryParse(raw.toString());
    return null;
  }

  String _dateLabel(DateTime? date, AppLocalizations l10n) {
    if (date == null) return l10n.noDate;
    return "${date.day}/${date.month}/${date.year}";
  }

  List<Map<String, dynamic>> _readFoods(Map<String, dynamic> data) {
    final normalized = <Map<String, dynamic>>[];
    final rawFoods = data["besinler"] as List? ?? [];

    for (final raw in rawFoods) {
      if (raw is! Map) continue;

      final food = Map<String, dynamic>.from(raw);
      final unitGram = FoodUnits.units[food["format"]] ?? 1;
      final amount = double.tryParse(food["miktar"]?.toString() ?? "0") ?? 0;
      final name = food["ad"]?.toString() ?? "";

      if (name.isNotEmpty && amount > 0) {
        normalized.add({"name": name, "amount": unitGram * amount});
      }
    }

    if (normalized.isNotEmpty) {
      return normalized;
    }

    final foodDetails = data["foodDetails"] as List? ?? [];
    for (final raw in foodDetails) {
      if (raw is! Map) continue;
      final food = Map<String, dynamic>.from(raw);
      normalized.add({
        "name": food["name"] ?? food["ad"] ?? "",
        "amount": food["amount"] ?? food["miktar"] ?? 0,
      });
    }

    return normalized;
  }

  List<Map<String, dynamic>> _readSupplements(Map<String, dynamic> data) {
    final supplements = <Map<String, dynamic>>[];
    final rawSupplements = data["takviyeler"] as List? ?? [];

    for (final raw in rawSupplements) {
      if (raw is! Map) continue;

      final supplement = Map<String, dynamic>.from(raw);
      final name = supplement["ad"]?.toString() ?? "";
      final amount =
          double.tryParse(supplement["miktar"]?.toString() ?? "1") ?? 1;

      if (name.isNotEmpty) {
        supplements.add({"name": name, "amount": amount});
      }
    }

    return supplements;
  }

  Widget _summaryCard(BuildContext context, Map<String, dynamic> analysis) {
    final l10n = AppLocalizations.of(context)!;
    final consumed = List<String>.from(analysis["consumedNutrients"] ?? []);
    final missing = List<String>.from(analysis["missingNutrients"] ?? []);
    final excess = List<String>.from(analysis["excessNutrients"] ?? []);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dailyTotalAnalysisResult,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          _summaryLine(
            context,
            l10n.consumedNutrients,
            consumed,
            Colors.green,
          ),
          _summaryLine(
            context,
            l10n.missingNutrients,
            missing,
            Colors.red,
          ),
          _summaryLine(
            context,
            l10n.excessNutrients,
            excess,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(
    BuildContext context,
    String title,
    List<String> values,
    Color color,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        "$title: ${values.isEmpty ? l10n.notExists : values.join(", ")}",
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _itemCard(
    BuildContext context,
    Map<String, dynamic> item,
    String unit,
  ) {
    final name = item["name"] ?? item["ad"] ?? "";
    final amount = item["amount"] ?? item["miktar"] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context, radius: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name.toString(),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            unit.isEmpty ? amount.toString() : "$amount $unit",
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(
    BuildContext context, {
    required double radius,
  }) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).shadowColor.withValues(alpha: 0.12),
          blurRadius: 6,
        ),
      ],
    );
  }
}

class _AnalysisDetailItem {
  final Map<String, dynamic> data;
  final DateTime? date;
  final List<Map<String, dynamic>> foods;
  final List<Map<String, dynamic>> supplements;
  final double calories;

  const _AnalysisDetailItem({
    required this.data,
    required this.date,
    required this.foods,
    required this.supplements,
    required this.calories,
  });
}
