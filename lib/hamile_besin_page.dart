import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'food_units.dart';
import 'l10n/app_localizations.dart';
import 'nutrition_engine.dart';

class HamileBesinPage extends StatefulWidget {
  const HamileBesinPage({super.key});

  @override
  State<HamileBesinPage> createState() => _HamileBesinPageState();
}

class _HamileBesinPageState extends State<HamileBesinPage> {
  final List<Map<String, dynamic>> besinListesi = [];
  final List<Map<String, dynamic>> takviyeListesi = [];

  final _besinAdiController = TextEditingController();
  final _besinMiktarController = TextEditingController();
  String _besinFormat = 'tane';

  final _takviyeAdiController = TextEditingController();
  final _takviyeMiktarController = TextEditingController();
  String _takviyeFormat = 'ölçek';

  final List<String> formatlar = [
    'tane',
    'tabak',
    'bardak',
    'fincan',
    'kaşık',
    'gram',
    'ml',
    'ölçek',
  ];

  bool _loading = false;

  @override
  void dispose() {
    _besinAdiController.dispose();
    _besinMiktarController.dispose();
    _takviyeAdiController.dispose();
    _takviyeMiktarController.dispose();
    super.dispose();
  }

  void besinEkle() {
    if (_besinAdiController.text.isEmpty ||
        _besinMiktarController.text.isEmpty) {
      return;
    }

    setState(() {
      besinListesi.add({
        'ad': _besinAdiController.text,
        'format': _besinFormat,
        'miktar': _besinMiktarController.text,
      });
      _besinAdiController.clear();
      _besinMiktarController.clear();
    });
  }

  void takviyeEkle() {
    if (_takviyeAdiController.text.isEmpty ||
        _takviyeMiktarController.text.isEmpty) {
      return;
    }

    setState(() {
      takviyeListesi.add({
        'ad': _takviyeAdiController.text,
        'format': _takviyeFormat,
        'miktar': _takviyeMiktarController.text,
      });
      _takviyeAdiController.clear();
      _takviyeMiktarController.clear();
    });
  }

  Future<void> kaydetAnaliz() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;
      if (besinListesi.isEmpty && takviyeListesi.isEmpty) return;

      setState(() => _loading = true);

      final foodsForAnalysis = <Map<String, dynamic>>[];

      for (final item in besinListesi) {
        final unitGram = FoodUnits.units[item["format"]] ?? 0;
        final miktar = double.tryParse(item["miktar"].toString()) ?? 0;
        final totalGram = unitGram * miktar;

        foodsForAnalysis.add({"name": item["ad"], "amount": totalGram});
      }

      final supplementsForAnalysis = <Map<String, dynamic>>[];

      for (final item in takviyeListesi) {
        supplementsForAnalysis.add({
          "name": item["ad"],
          "amount": item["miktar"],
        });
      }

      final analiz = NutritionEngine.analyzeFoods(
        foodsForAnalysis,
        supplementsForAnalysis,
      );

      final dailyInputs = await getTodayNutritionInputs(user.uid);
      final dailyAnaliz = NutritionEngine.analyzeFoods(
        [...dailyInputs["foods"]!, ...foodsForAnalysis],
        [...dailyInputs["supplements"]!, ...supplementsForAnalysis],
      );

      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final dietitianId = userDoc["assignedDietitian"];
      if (dietitianId == null) {
        if (mounted) setState(() => _loading = false);
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.noDietitianAssigned)));
        return;
      }

      await FirebaseFirestore.instance.collection('besin_analizleri').add({
        'uid': user.uid,
        'dietitianId': dietitianId,
        'createdAt': FieldValue.serverTimestamp(),
        'besinler': besinListesi,
        'takviyeler': takviyeListesi,
        'kalori': analiz["totalCalories"] ?? 0,
        'foodDetails': analiz["foodDetails"],
        'consumedNutrients': dailyAnaliz["consumedNutrients"],
        'missingNutrients': dailyAnaliz["missingNutrients"],
        'excessNutrients': dailyAnaliz["excessNutrients"],
        'totalNutrients': dailyAnaliz["totalNutrients"],
      });

      if (!mounted) return;

      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(l10n.nutritionAnalysis),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.consumedNutrients),
              const SizedBox(height: 8),
              ...dailyAnaliz["consumedNutrients"]
                  .map<Widget>(
                    (n) => Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(n),
                      ],
                    ),
                  )
                  .toList(),
              const SizedBox(height: 20),
              Text(l10n.missingNutrients),
              const SizedBox(height: 10),
              ...dailyAnaliz["missingNutrients"]
                  .map<Widget>(
                    (n) => Row(
                      children: [
                        const Icon(
                          Icons.warning,
                          color: Colors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(n),
                      ],
                    ),
                  )
                  .toList(),
              const SizedBox(height: 20),
              Text(l10n.excessNutrients),
              const SizedBox(height: 10),
              ...dailyAnaliz["excessNutrients"]
                  .map<Widget>(
                    (n) => Row(
                      children: [
                        const Icon(
                          Icons.arrow_upward,
                          color: Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(n),
                      ],
                    ),
                  )
                  .toList(),
            ],
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.saved),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      setState(() {
        besinListesi.clear();
        takviyeListesi.clear();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorWithMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(l10n.nutritionSupplementAnalysis),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(l10n.foodEntry),
            _buildTextField(l10n.foodName, _besinAdiController),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    _besinFormat,
                    (v) => setState(() => _besinFormat = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(l10n.amount, _besinMiktarController),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _primaryButton(l10n.addFood, besinEkle),
            const SizedBox(height: 25),
            _buildSectionTitle(l10n.supplementEntry),
            _buildTextField(l10n.supplementName, _takviyeAdiController),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    _takviyeFormat,
                    (v) => setState(() => _takviyeFormat = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(l10n.amount, _takviyeMiktarController),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _primaryButton(l10n.addSupplement, takviyeEkle),
            const SizedBox(height: 30),
            _buildList(l10n.enteredFoods, besinListesi),
            const SizedBox(height: 20),
            _buildList(l10n.enteredSupplements, takviyeListesi),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _loading ? null : kaydetAnaliz,
              child: _loading
                  ? CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onPrimary,
                    )
                  : Text(l10n.saveDay, style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdown(String value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: formatlar
          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _primaryButton(String text, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        minimumSize: const Size(double.infinity, 45),
      ),
      onPressed: onTap,
      child: Text(text),
    );
  }

  Widget _buildList(String title, List<Map<String, dynamic>> liste) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (liste.isEmpty)
            Text(
              l10n.noItemsYet,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ...liste.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "- ${item['ad']} (${item['miktar']} ${item['format']})",
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        liste.remove(item);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, List<Map<String, dynamic>>>> getTodayNutritionInputs(
    String uid,
  ) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);

    final snap = await FirebaseFirestore.instance
        .collection('besin_analizleri')
        .where('uid', isEqualTo: uid)
        .get();

    final foods = <Map<String, dynamic>>[];
    final supplements = <Map<String, dynamic>>[];

    for (final doc in snap.docs) {
      final data = doc.data();
      final rawDate = data['createdAt'] ?? data['tarih'];
      DateTime? date;

      if (rawDate is Timestamp) {
        date = rawDate.toDate();
      } else if (rawDate != null) {
        date = DateTime.tryParse(rawDate.toString());
      }

      if (date == null || date.isBefore(start)) continue;

      for (final item in (data['besinler'] ?? [])) {
        final map = Map<String, dynamic>.from(item);
        final unitGram = FoodUnits.units[map['format']] ?? 1;
        final amount = double.tryParse(map['miktar'].toString()) ?? 0;

        foods.add({'name': map['ad'], 'amount': unitGram * amount});
      }

      for (final item in (data['takviyeler'] ?? [])) {
        final map = Map<String, dynamic>.from(item);

        supplements.add({'name': map['ad'], 'amount': map['miktar']});
      }
    }

    return {'foods': foods, 'supplements': supplements};
  }
}
