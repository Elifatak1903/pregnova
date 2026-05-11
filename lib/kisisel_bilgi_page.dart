import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'l10n/app_localizations.dart';

class KisiselBilgilerPage extends StatefulWidget {
  const KisiselBilgilerPage({super.key});

  @override
  State<KisiselBilgilerPage> createState() => _KisiselBilgilerPageState();
}

class _KisiselBilgilerPageState extends State<KisiselBilgilerPage> {
  final _formKey = GlobalKey<FormState>();

  final yasController = TextEditingController();
  final kiloController = TextEditingController();
  final haftaController = TextEditingController();
  final alerjiController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  bool chronicHypertension = false;
  bool diabetes = false;
  bool thyroidDisease = false;
  bool previousPreterm = false;
  bool multiplePregnancy = false;
  bool smoker = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  @override
  void dispose() {
    yasController.dispose();
    kiloController.dispose();
    haftaController.dispose();
    alerjiController.dispose();
    super.dispose();
  }

  Future<void> fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final data = snapshot.data();

      if (data != null) {
        yasController.text = data['yas']?.toString() ?? '';
        kiloController.text = data['kilo']?.toString() ?? '';
        haftaController.text = data['hafta']?.toString() ?? '';
        alerjiController.text = data['alerjiler'] ?? '';
        chronicHypertension = data['chronicHypertension'] ?? false;
        diabetes = data['diabetes'] ?? false;
        thyroidDisease = data['thyroidDisease'] ?? false;
        previousPreterm = data['previousPreterm'] ?? false;
        multiplePregnancy = data['multiplePregnancy'] ?? false;
        smoker = data['smoker'] ?? false;
      }
    }

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  Future<void> kaydet() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final hafta = int.tryParse(haftaController.text.trim()) ?? 0;
      final gebelikBaslangicTarihi = DateTime.now().subtract(
        Duration(days: hafta * 7),
      );

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'yas': int.tryParse(yasController.text.trim()) ?? 0,
        'kilo': double.tryParse(kiloController.text.trim()) ?? 0,
        'hafta': hafta,
        'gebelikBaslangicTarihi': Timestamp.fromDate(gebelikBaslangicTarihi),
        'alerjiler': alerjiController.text.trim(),
        'chronicHypertension': chronicHypertension,
        'diabetes': diabetes,
        'thyroidDisease': thyroidDisease,
        'previousPreterm': previousPreterm,
        'multiplePregnancy': multiplePregnancy,
        'smoker': smoker,
        'profilTamamlandi': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.infoUpdated),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorOccurredWithMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) setState(() => isSaving = false);
  }

  Widget buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        validator: (value) {
          final l10n = AppLocalizations.of(context)!;
          if (value == null || value.trim().isEmpty) {
            return l10n.requiredField;
          }
          return null;
        },
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 14,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          labelText: label,
          labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildCheckbox(
    String title,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return CheckboxListTile(
      title: Text(title),
      value: value,
      activeColor: Theme.of(context).colorScheme.primary,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.personalInfo),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      buildInputField(
                        controller: yasController,
                        label: l10n.age,
                        icon: Icons.person,
                        type: TextInputType.number,
                      ),
                      buildInputField(
                        controller: kiloController,
                        label: l10n.currentWeightKg,
                        icon: Icons.monitor_weight,
                        type: TextInputType.number,
                      ),
                      buildInputField(
                        controller: haftaController,
                        label: l10n.pregnancyWeekInput,
                        icon: Icons.calendar_today,
                        type: TextInputType.number,
                      ),
                      buildInputField(
                        controller: alerjiController,
                        label: l10n.allergies,
                        icon: Icons.warning_amber_rounded,
                      ),
                      const SizedBox(height: 10),
                      Divider(color: Theme.of(context).dividerColor),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.riskFactors,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      buildCheckbox(
                        l10n.chronicHypertension,
                        chronicHypertension,
                        (val) => setState(() => chronicHypertension = val!),
                      ),
                      buildCheckbox(
                        l10n.diabetes,
                        diabetes,
                        (val) => setState(() => diabetes = val!),
                      ),
                      buildCheckbox(
                        l10n.thyroidDisease,
                        thyroidDisease,
                        (val) => setState(() => thyroidDisease = val!),
                      ),
                      buildCheckbox(
                        l10n.previousPreterm,
                        previousPreterm,
                        (val) => setState(() => previousPreterm = val!),
                      ),
                      buildCheckbox(
                        l10n.multiplePregnancy,
                        multiplePregnancy,
                        (val) => setState(() => multiplePregnancy = val!),
                      ),
                      buildCheckbox(
                        l10n.smoking,
                        smoker,
                        (val) => setState(() => smoker = val!),
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : kaydet,
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
                          ),
                          child: isSaving
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  l10n.save,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
