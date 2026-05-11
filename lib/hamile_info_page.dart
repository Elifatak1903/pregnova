import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'hamile_page.dart';
import 'l10n/app_localizations.dart';

class HamileBilgiFormuPage extends StatefulWidget {
  final String uid;

  const HamileBilgiFormuPage({super.key, required this.uid});

  @override
  State<HamileBilgiFormuPage> createState() => _HamileBilgiFormuPageState();
}

class _HamileBilgiFormuPageState extends State<HamileBilgiFormuPage> {
  final yasController = TextEditingController();
  final kiloController = TextEditingController();
  final haftaController = TextEditingController();
  final boyController = TextEditingController();
  final alerjiController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool chronicHypertension = false;
  bool diabetes = false;
  bool thyroidDisease = false;
  bool previousPreterm = false;
  bool multiplePregnancy = false;
  bool smoker = false;

  @override
  void dispose() {
    yasController.dispose();
    kiloController.dispose();
    haftaController.dispose();
    boyController.dispose();
    alerjiController.dispose();
    super.dispose();
  }

  Future<void> kaydet() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final kilo = double.tryParse(kiloController.text.trim()) ?? 0;
    final boyCm = double.tryParse(boyController.text.trim()) ?? 0;
    final boyMetre = boyCm / 100;
    final hafta = int.tryParse(haftaController.text.trim()) ?? 0;
    final gebelikBaslangicTarihi = DateTime.now().subtract(
      Duration(days: hafta * 7),
    );

    var bmi = 0.0;
    if (boyMetre > 0) {
      bmi = kilo / (boyMetre * boyMetre);
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'yas': int.tryParse(yasController.text.trim()) ?? 0,
        'kilo': kilo,
        'boy': boyCm,
        'bmi': bmi,
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

      await FirebaseFirestore.instance.collection('risk_olcumleri').add({
        'uid': widget.uid,
        'kilo': kilo,
        'hafta': hafta,
        'tarih': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HamileAnaSayfa()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorWithMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
    String? validationKey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        validator: (value) => validateField(value, validationKey),
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          labelText: label,
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  String? validateField(String? value, String? validationKey) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) return l10n.requiredField;

    if (validationKey == 'age') {
      final age = int.tryParse(value);
      if (age == null || age < 15 || age > 50) {
        return l10n.ageRangeValidation;
      }
    }

    if (validationKey == 'week') {
      final week = int.tryParse(value);
      if (week == null || week < 1 || week > 42) {
        return l10n.pregnancyWeekRangeValidation;
      }
    }

    if (validationKey == 'height') {
      final height = double.tryParse(value);
      if (height == null || height < 100 || height > 250) {
        return l10n.enterValidNumber;
      }
    }

    return null;
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
        title: Text(l10n.profileInfo),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  buildInputField(
                    controller: yasController,
                    label: l10n.age,
                    icon: Icons.person,
                    type: TextInputType.number,
                    validationKey: 'age',
                  ),
                  buildInputField(
                    controller: kiloController,
                    label: l10n.currentWeightKg,
                    icon: Icons.monitor_weight,
                    type: TextInputType.number,
                  ),
                  buildInputField(
                    controller: boyController,
                    label: l10n.heightCm,
                    icon: Icons.height,
                    type: TextInputType.number,
                    validationKey: 'height',
                  ),
                  buildInputField(
                    controller: haftaController,
                    label: l10n.pregnancyWeekInput,
                    icon: Icons.calendar_today,
                    type: TextInputType.number,
                    validationKey: 'week',
                  ),
                  buildInputField(
                    controller: alerjiController,
                    label: l10n.allergiesExample,
                    icon: Icons.warning_amber_rounded,
                  ),
                  const SizedBox(height: 20),
                  Divider(color: Theme.of(context).dividerColor),
                  const SizedBox(height: 10),
                  Text(
                    l10n.chronicRiskFactors,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
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
                    l10n.previousPretermBirth,
                    previousPreterm,
                    (val) => setState(() => previousPreterm = val!),
                  ),
                  buildCheckbox(
                    l10n.multiplePregnancyDetail,
                    multiplePregnancy,
                    (val) => setState(() => multiplePregnancy = val!),
                  ),
                  buildCheckbox(
                    l10n.smokingUse,
                    smoker,
                    (val) => setState(() => smoker = val!),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: kaydet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        l10n.saveAndContinue,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
