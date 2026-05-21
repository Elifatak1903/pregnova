import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'l10n/app_localizations.dart';
import 'risk_engine.dart';

class RiskTakipFormuPage extends StatefulWidget {
  const RiskTakipFormuPage({super.key});

  @override
  State<RiskTakipFormuPage> createState() => _RiskTakipFormuPageState();
}

class _RiskTakipFormuPageState extends State<RiskTakipFormuPage> {
  final _formKey = GlobalKey<FormState>();

  final sistolikController = TextEditingController();
  final diastolikController = TextEditingController();
  final aclikSekerController = TextEditingController();
  final toklukSekerController = TextEditingController();
  final kiloController = TextEditingController();

  bool basAgrisi = false;
  bool gormeBozuklugu = false;
  bool sislik = false;
  bool asiriSusama = false;
  bool sikIdrar = false;
  bool karinKasilma = false;
  bool akinti = false;
  bool belAgrisi = false;
  double stresSeviyesi = 1;
  bool _loading = false;

  @override
  void dispose() {
    sistolikController.dispose();
    diastolikController.dispose();
    aclikSekerController.dispose();
    toklukSekerController.dispose();
    kiloController.dispose();
    super.dispose();
  }

  Future<void> kaydet() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      if (!_formKey.currentState!.validate()) return;

      setState(() => _loading = true);

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      final userData = userDoc.data() ?? {};
      final sistolik = int.tryParse(sistolikController.text) ?? 0;
      final diastolik = int.tryParse(diastolikController.text) ?? 0;

      if (diastolik >= sistolik) {
        if (mounted) setState(() => _loading = false);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.diastolicMustBeLower),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        return;
      }

      final aclik = double.tryParse(aclikSekerController.text);
      final tokluk = double.tryParse(toklukSekerController.text);

      final preeklampsiRisk = await RiskEngine.calculatePreeklampsi(
        uid: uid,
        sistolik: sistolik,
        diastolik: diastolik,
        gormeBozuklugu: gormeBozuklugu,
        basAgrisi: basAgrisi,
        sislik: sislik,
        chronicHypertension: userData["chronicHypertension"] ?? false,
      );

      final diyabetRisk = RiskEngine.calculateDiyabet(
        aclik: aclik,
        tokluk: tokluk,
        asiriSusama: asiriSusama,
        sikIdrar: sikIdrar,
        diabetes: userData["diabetes"] ?? false,
      );

      final pretermRisk = RiskEngine.calculatePreterm(
        karinKasilma: karinKasilma,
        akinti: akinti,
        belAgrisi: belAgrisi,
        stresSeviyesi: stresSeviyesi,
        previousPreterm: userData["previousPreterm"] ?? false,
        multiplePregnancy: userData["multiplePregnancy"] ?? false,
      );

      var overallRisk = "low";
      if (preeklampsiRisk == "HIGH" ||
          diyabetRisk == "HIGH" ||
          pretermRisk == "HIGH") {
        overallRisk = "high";
      } else if (preeklampsiRisk == "MEDIUM" ||
          diyabetRisk == "MEDIUM" ||
          pretermRisk == "MEDIUM") {
        overallRisk = "medium";
      }

      final enteredWeight = double.tryParse(kiloController.text);
      final userUpdate = <String, dynamic>{
        "riskLevel": overallRisk,
      };

      if (enteredWeight != null && enteredWeight > 0) {
        userUpdate["kilo"] = enteredWeight;
      }

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .set(userUpdate, SetOptions(merge: true));

      await RiskEngine.sendRiskNotification(
        uid: uid,
        riskType: "Preeklampsi",
        riskLevel: preeklampsiRisk,
      );

      await RiskEngine.sendRiskNotification(
        uid: uid,
        riskType: "Gestasyonel Diyabet",
        riskLevel: diyabetRisk,
      );

      await RiskEngine.sendRiskNotification(
        uid: uid,
        riskType: "Preterm Doğum",
        riskLevel: pretermRisk,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          Color color(String risk) {
            if (risk == "HIGH") return Colors.red;
            if (risk == "MEDIUM") return Colors.orange;
            return Colors.green;
          }

          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(l10n.riskResult),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _riskRow("Preeklampsi", preeklampsiRisk, color),
                _riskRow(l10n.diabetes, diyabetRisk, color),
                _riskRow(l10n.preterm, pretermRisk, color),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.ok),
              ),
            ],
          );
        },
      );

      await FirebaseFirestore.instance.collection('risk_olcumleri').add({
        'uid': uid,
        'tarih': Timestamp.now(),
        'kilo': enteredWeight,
        'sistolik': int.tryParse(sistolikController.text),
        'diastolik': int.tryParse(diastolikController.text),
        'basAgrisi': basAgrisi,
        'gormeBozuklugu': gormeBozuklugu,
        'sislik': sislik,
        'aclikSeker': aclik,
        'toklukSeker': tokluk,
        'asiriSusama': asiriSusama,
        'sikIdrar': sikIdrar,
        'karinKasilma': karinKasilma,
        'akinti': akinti,
        'belAgrisi': belAgrisi,
        'stresSeviyesi': stresSeviyesi,
        'preeklampsiRisk': preeklampsiRisk,
        'diyabetRisk': diyabetRisk,
        'pretermRisk': pretermRisk,
      });

      if (mounted) setState(() => _loading = false);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.riskDataSaved),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorWithMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _riskRow(String title, String risk, Color Function(String) color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            risk,
            style: TextStyle(color: color(risk), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.riskTrackingForm),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              // KİLO
              _modernCard(
                child: _textInput(
                  l10n.currentWeightKg,
                  kiloController,
                ),
              ),

              const SizedBox(height: 20),

              // PREEKLAMPSI
              _modernCard(
                child: Column(
                  children: [
                    _sectionTitle(l10n.preeklampsiTracking),
                    _sectionHint(l10n.preeclampsiaMeasurementHint),

                    _textInput(
                      l10n.systolicExample,
                      sistolikController,
                      min: 80,
                      max: 250,
                      example: 120,
                    ),

                    _textInput(
                      l10n.diastolicExample,
                      diastolikController,
                      min: 50,
                      max: 150,
                      example: 80,
                    ),

                    _switchTile(
                      l10n.severeHeadache,
                      basAgrisi,
                          (v) => setState(() => basAgrisi = v),
                    ),

                    _switchTile(
                      l10n.visionProblem,
                      gormeBozuklugu,
                          (v) => setState(() => gormeBozuklugu = v),
                    ),

                    _switchTile(
                      l10n.handFaceSwelling,
                      sislik,
                          (v) => setState(() => sislik = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // DIYABET
              _modernCard(
                child: Column(
                  children: [
                    _sectionTitle(l10n.gestationalDiabetes),
                    _sectionHint(l10n.diabetesMeasurementHint),

                    _textInput(
                      l10n.fastingBloodSugar,
                      aclikSekerController,
                      required: false,
                    ),

                    _textInput(
                      l10n.postMealBloodSugar,
                      toklukSekerController,
                      required: false,
                    ),

                    _switchTile(
                      l10n.excessiveThirst,
                      asiriSusama,
                          (v) => setState(() => asiriSusama = v),
                    ),

                    _switchTile(
                      l10n.frequentUrination,
                      sikIdrar,
                          (v) => setState(() => sikIdrar = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // PRETERM
              _modernCard(
                child: Column(
                  children: [
                    _sectionTitle(l10n.pretermRisk),
                    _sectionHint(l10n.pretermMeasurementHint),

                    _switchTile(
                      l10n.contraction,
                      karinKasilma,
                          (v) => setState(() => karinKasilma = v),
                    ),

                    _switchTile(
                      l10n.increasedDischarge,
                      akinti,
                          (v) => setState(() => akinti = v),
                    ),

                    _switchTile(
                      l10n.backPain,
                      belAgrisi,
                          (v) => setState(() => belAgrisi = v),
                    ),

                    const SizedBox(height: 10),

                    Text(l10n.stressLevel),

                    Slider(
                      value: stresSeviyesi,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: stresSeviyesi.round().toString(),
                      onChanged: (value) {
                        setState(() => stresSeviyesi = value);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // BUTTON
              Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _loading ? null : kaydet,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _loading
                      ? CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.onPrimary,
                  )
                      : Text(l10n.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modernCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .primary
              .withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _sectionHint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            height: 1.35,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.62),
          ),
        ),
      ),
    );
  }

  Widget _textInput(
      String label,
      TextEditingController controller, {
        int? min,
        int? max,
        int? example,
        bool required = true,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        validator: (value) {
          final l10n = AppLocalizations.of(context)!;

          if (value == null || value.trim().isEmpty) {
            return required ? l10n.requiredField : null;
          }

          final parsed = int.tryParse(value);

          if (parsed == null) {
            return l10n.enterValidNumber;
          }

          if (min != null &&
              max != null &&
              (parsed < min || parsed > max)) {
            return l10n.enterValidValueExample(example ?? min);
          }

          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _switchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      title: Text(title),
      activeColor: Theme.of(context).colorScheme.primary,
      onChanged: onChanged,
    );
  }
}
