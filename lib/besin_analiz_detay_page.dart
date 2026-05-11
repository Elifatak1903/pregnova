import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

class BesinAnalizDetayPage extends StatelessWidget {
  final String docId;

  const BesinAnalizDetayPage({super.key, required this.docId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.nutritionAnalysisDetail),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("besin_analizleri")
            .doc(docId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text(l10n.analysisNotFound));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final date = _readDate(data);
          final calories = (data["kalori"] as num?)?.toDouble() ?? 0;
          final foods = (data["foodDetails"] as List?) ?? [];

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
                      date != null
                          ? "${date.day}/${date.month}/${date.year}"
                          : l10n.noDate,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.totalCalories(calories.toStringAsFixed(0)),
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
              Text(
                l10n.consumedFoods,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              if (foods.isEmpty)
                Center(child: Text(l10n.noItemsYet))
              else
                ...foods.map((food) {
                  final foodData = food is Map ? food : <String, dynamic>{};
                  final name = foodData["name"] ?? "";
                  final amount = foodData["amount"] ?? 0;

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
                          "$amount gr",
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  DateTime? _readDate(Map<String, dynamic> data) {
    final raw = data["createdAt"] ?? data["tarih"];
    if (raw is Timestamp) return raw.toDate();
    if (raw != null) return DateTime.tryParse(raw.toString());
    return null;
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
