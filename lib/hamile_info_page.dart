import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'hamile_page.dart';

class HamileBilgiFormuPage extends StatefulWidget {
  final String uid;
  const HamileBilgiFormuPage({Key? key, required this.uid}) : super(key: key);

  @override
  State<HamileBilgiFormuPage> createState() => _HamileBilgiFormuPageState();
}

class _HamileBilgiFormuPageState extends State<HamileBilgiFormuPage> {

  final yasController = TextEditingController();
  final kiloController = TextEditingController();
  final haftaController = TextEditingController();

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
    super.dispose();
  }

  Future<void> kaydet() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .set({
        'yas': int.tryParse(yasController.text.trim()) ?? 0,
        'kilo': double.tryParse(kiloController.text.trim()) ?? 0,
        'hafta': int.tryParse(haftaController.text.trim()) ?? 0,

        // STATIC RISK FACTORS
        'chronicHypertension': chronicHypertension,
        'diabetes': diabetes,
        'thyroidDisease': thyroidDisease,
        'previousPreterm': previousPreterm,
        'multiplePregnancy': multiplePregnancy,
        'smoker': smoker,

        'profilTamamlandi': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HamileAnaSayfa()),
      );

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  Widget buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.pink),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget buildCheckbox(String title, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(title),
      value: value,
      activeColor: Colors.pink,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,   // ✅ pembe arka plan
      appBar: AppBar(
        title: const Text("Profil Bilgileri"),
        backgroundColor: Colors.pink,         // ✅ pembe appbar
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                buildInputField(
                  controller: yasController,
                  label: "Yaş",
                  icon: Icons.person,
                  type: TextInputType.number,
                ),

                buildInputField(
                  controller: kiloController,
                  label: "Güncel Kilo (kg)",
                  icon: Icons.monitor_weight,
                  type: TextInputType.number,
                ),

                buildInputField(
                  controller: haftaController,
                  label: "Hamilelik Haftası",
                  icon: Icons.calendar_today,
                  type: TextInputType.number,
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),

                const Text(
                  "Kronik / Risk Faktörleri",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),

                const SizedBox(height: 10),

                buildCheckbox("Kronik Hipertansiyon", chronicHypertension,
                        (val) => setState(() => chronicHypertension = val!)),

                buildCheckbox("Diyabet", diabetes,
                        (val) => setState(() => diabetes = val!)),

                buildCheckbox("Tiroid Hastalığı", thyroidDisease,
                        (val) => setState(() => thyroidDisease = val!)),

                buildCheckbox("Önceki Preterm Doğum", previousPreterm,
                        (val) => setState(() => previousPreterm = val!)),

                buildCheckbox("Çoğul Gebelik (İkiz vb.)", multiplePregnancy,
                        (val) => setState(() => multiplePregnancy = val!)),

                buildCheckbox("Sigara Kullanımı", smoker,
                        (val) => setState(() => smoker = val!)),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: kaydet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,   // ✅ pembe buton
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Kaydet ve Devam Et",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
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
