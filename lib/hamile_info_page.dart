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
  final boyController = TextEditingController();
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
    super.dispose();
  }

  Future<void> kaydet() async {
    final kilo = double.tryParse(kiloController.text.trim()) ?? 0;
    final boyCm = double.tryParse(boyController.text.trim()) ?? 0;
    final boyMetre = boyCm /100;

    double bmi = 0;
    if (boyMetre >0) {
      bmi = kilo / (boyMetre * boyMetre);
    }
    
    if (!_formKey.currentState!.validate()) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .set({
        'yas': int.tryParse(yasController.text.trim()) ?? 0,
        'kilo': double.tryParse(kiloController.text.trim()) ?? 0,
        'boy': boyCm,
        'bmi': bmi,
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
      await FirebaseFirestore.instance
          .collection('risk_olcumleri')
          .add({
        'uid': widget.uid,
        'kilo': double.tryParse(kiloController.text.trim()) ?? 0,
        'hafta': int.tryParse(haftaController.text.trim()),
        'tarih': FieldValue.serverTimestamp(),
      });

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
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "Bu alan boş bırakılamaz";
          }

          if (label == "Yaş"){
            final age = int.tryParse(value);
            if (age == null || age<15 || age > 50){
              return "15-50 arası yaş giriniz";
            }
          }

          if(label == "Hamilelik Haftası") {
            final week = int.tryParse(value);
            if(week == null || week < 1 || week > 42){
              return "1-42 arası hafta giriniz";
            }
          }
          
          if (label == "Boy (cm)"){
            final height = double.tryParse(value);
            if (height == null || height < 100 || height > 250){
              return "Geçerli bir sayı giriniz";
            }
          }

          return null;
        },
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.pink),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.pink, width: 2),
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
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        title: const Text("Profil Bilgileri"),
        backgroundColor: Colors.pink,
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
            child: Form(
              key: _formKey,
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

                  buildInputField(controller: boyController,
                    label: "Boy (cm)",
                    icon: Icons.height,
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
                        backgroundColor: Colors.pink,
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
      ),
    );
  }
}
