import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RiskTakipFormuPage extends StatefulWidget {
  const RiskTakipFormuPage({super.key});

  @override
  State<RiskTakipFormuPage> createState() => _RiskTakipFormuPageState();
}

class _RiskTakipFormuPageState extends State<RiskTakipFormuPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final sistolikController = TextEditingController();
  final diastolikController = TextEditingController();
  final aclikSekerController = TextEditingController();
  final toklukSekerController = TextEditingController();
  final kiloController = TextEditingController();

  // Boolean risk soruları
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

  Future<void> kaydet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('risk_olcumleri').add({
      'uid': uid,
      'tarih': Timestamp.now(),
      'kilo': double.tryParse(kiloController.text),

      // Preeklampsi
      'sistolik': int.tryParse(sistolikController.text),
      'diastolik': int.tryParse(diastolikController.text),
      'basAgrisi': basAgrisi,
      'gormeBozuklugu': gormeBozuklugu,
      'sislik': sislik,

      // Gestasyonel Diyabet
      'aclikSeker': double.tryParse(aclikSekerController.text),
      'toklukSeker': double.tryParse(toklukSekerController.text),
      'asiriSusama': asiriSusama,
      'sikIdrar': sikIdrar,

      // Preterm Birth
      'karinKasilma': karinKasilma,
      'akinti': akinti,
      'belAgrisi': belAgrisi,
      'stresSeviyesi': stresSeviyesi,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Risk verileri kaydedildi 💗")),
    );

    Navigator.pop(context);
    setState(() => _loading = false);
    print("Risk hesaplama tetiklenecek");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Risk Takip Formu",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                  ),

                  const SizedBox(height: 20),

                  _sectionTitle("Genel Ölçüm"),
                  _textInput("Güncel Kilo (kg)", kiloController),

                  // ---------------- PRE-EKLAMPSİ ----------------
                  _sectionTitle("Preeklampsi Takibi"),
                  _textInput("Sistolik (Büyük Tansiyon)", sistolikController),
                  _textInput("Diastolik (Küçük Tansiyon)", diastolikController),
                  _switchTile("Şiddetli baş ağrısı", basAgrisi,
                      (v) => setState(() => basAgrisi = v)),
                  _switchTile("Görme bozukluğu", gormeBozuklugu,
                      (v) => setState(() => gormeBozuklugu = v)),
                  _switchTile("El/Yüz şişmesi", sislik,
                      (v) => setState(() => sislik = v)),

                  const SizedBox(height: 20),

                  // ---------------- DİYABET ----------------
                  _sectionTitle("Gestasyonel Diyabet"),
                  _textInput("Açlık kan şekeri", aclikSekerController),
                  _textInput("Tokluk kan şekeri", toklukSekerController),
                  _switchTile("Aşırı susama", asiriSusama,
                      (v) => setState(() => asiriSusama = v)),
                  _switchTile("Sık idrara çıkma", sikIdrar,
                      (v) => setState(() => sikIdrar = v)),

                  const SizedBox(height: 20),

                  // ---------------- PRETERM ----------------
                  _sectionTitle("Preterm Birth Riski"),
                  _switchTile("Karın kasılması", karinKasilma,
                      (v) => setState(() => karinKasilma = v)),
                  _switchTile("Vajinal akıntı artışı", akinti,
                      (v) => setState(() => akinti = v)),
                  _switchTile("Bel ağrısı", belAgrisi,
                      (v) => setState(() => belAgrisi = v)),

                  const SizedBox(height: 10),
                  const Text("Stres Seviyesi"),
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

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _loading ? null : kaydet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text("Kaydet"),
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

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.pink,
        ),
      ),
    );
  }

  Widget _textInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.trim().isEmpty){
            return "Bu alan boş bırakılamaz";
          }
          final number = double.tryParse(value);

          if (number == null){
            return "Geçerli bir sayı giriniz";
          }

          if (label.contains("Kilo")){
            if (number < 30 || number > 200) {
              return "Geçerli bir sayı giriniz";
            }
          }

          if (label.contains("Açlık")) {
            if (number <50 || number > 300) {
              return "Geçerli bir kan şekeri değeri giriniz";
            }
          }

          if (label.contains("Tokluk")){
            if (number < 50 || number > 400) {
              return "Geçerli bir kan şekeri değeri giriniz";
            }
          }

          if (label.contains("Sistolik")) {
            if (number < 70 || number > 250) {
              return "Geçerli bir tansiyon değeri giriniz.";
            }
          }

          if (label.contains("Diastolik")) {
            if (number < 40 || number > 150){
              return "Geçerli bir tansiyon değeri giriniz";
            }
          }

          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _switchTile(
      String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      value: value,
      title: Text(title),
      activeColor: Colors.pink,
      onChanged: onChanged,
    );
  }
}