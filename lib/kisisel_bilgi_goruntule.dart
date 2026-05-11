import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'kisisel_bilgi_page.dart';
import 'l10n/app_localizations.dart';

class KisiselBilgilerGoruntulePage extends StatelessWidget {
  const KisiselBilgilerGoruntulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.personalInfo),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.personalInfo,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>?;

                    if (data == null) {
                      return Center(
                        child: Text(
                          l10n.dataNotFound,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            bilgiKart(
                              context,
                              l10n.chronicHypertension,
                              boolValue(context, data['chronicHypertension']),
                              Icons.monitor_heart,
                            ),
                            bilgiKart(
                              context,
                              l10n.diabetes,
                              boolValue(context, data['diabetes']),
                              Icons.bloodtype,
                            ),
                            bilgiKart(
                              context,
                              l10n.thyroidDisease,
                              boolValue(context, data['thyroidDisease']),
                              Icons.health_and_safety,
                            ),
                            bilgiKart(
                              context,
                              l10n.previousPreterm,
                              boolValue(context, data['previousPreterm']),
                              Icons.warning,
                            ),
                            bilgiKart(
                              context,
                              l10n.multiplePregnancy,
                              boolValue(context, data['multiplePregnancy']),
                              Icons.groups,
                            ),
                            bilgiKart(
                              context,
                              l10n.smoking,
                              boolValue(context, data['smoker']),
                              Icons.smoking_rooms,
                            ),
                            bilgiKart(
                              context,
                              l10n.allergies,
                              data['alerjiler'] ?? "",
                              Icons.warning_amber_rounded,
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const KisiselBilgilerPage(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                ),
                                child: Text(
                                  l10n.editInfo,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
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

  String boolValue(BuildContext context, dynamic value) {
    final l10n = AppLocalizations.of(context)!;
    return value == true ? l10n.exists : l10n.notExists;
  }

  Widget bilgiKart(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.2),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          value.isEmpty ? l10n.notSpecified : value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
