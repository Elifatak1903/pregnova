import 'package:cloud_firestore/cloud_firestore.dart';


class RiskResult {
  final String preeklampsi;
  final String diyabet;
  final String preterm;

  RiskResult({
    required this.preeklampsi,
    required this.diyabet,
    required this.preterm,
  });
}

class RiskEngine {
  static Future<String> calculatePreeklampsi({
    required String uid,
    required int sistolik,
    required int diastolik,
    required bool gormeBozuklugu,
    required bool basAgrisi,
    required bool sislik,
    required bool chronicHypertension,
  }) async {
    if (sistolik >=160 || diastolik >= 110 ){
      return "HIGH";
    }
    int score = 0;
    if (sistolik >=140) score += 2;
    if (diastolik >= 90) score += 2;
    if (basAgrisi) score += 1;
    if (gormeBozuklugu) score += 1;
    if (sislik) score += 1;
    if (chronicHypertension) score += 2;

    String risk;

    if (score <=2){
      risk = "LOW";
    }else if (score <= 5){
      risk = "MEDIUM";
    }else {
      risk = "HIGH";
    }

    final query = await FirebaseFirestore.instance
      .collection("risk_olcumleri")
      .where("uid", isEqualTo: uid)
      .orderBy("tarih", descending: true)
      .limit(3)
      .get();
    if (query.docs.length == 3){
      int abnormalCount = 0;

      for (var doc in query.docs){
        final data = doc.data() as Map<String, dynamic>;
        final s = data["sistolik"] ?? 0;
        final d = data["diastolik"] ?? 0;

        if (s >= 140 || d>= 90){
          abnormalCount++;
        }
      }
      if (abnormalCount == 3){
        if (risk == "LOW") risk = "MEDIUM";
        if(risk == "MEDIUM") risk = "HIGH";
      }
    }
    return risk;
  }
  static String calculateDiyabet({
    required double? aclik,
    required double? tokluk,
    required bool asiriSusama,
    required bool sikIdrar,
    required bool diabetes,
  }) {
    if ((aclik ?? 0) >= 126 || (tokluk ?? 0) >= 200){
      return "HIGH";
    }
    int score = 0;
    if ((aclik ?? 0) >= 100) score +=2;
    if ((tokluk ?? 0) >= 140) score +=2;
    if (asiriSusama) score +=1;
    if (sikIdrar) score +=1;
    if (diabetes) score +=2;

    if (score <=2) return "LOW";
    if (score >2 && score <=5) return "MEDIUM";
    return "HIGH";
  }
  static String calculatePreterm({
    required bool karinKasilma,
    required bool akinti,
    required bool belAgrisi,
    required double stresSeviyesi,
    required bool previousPreterm,
    required bool multiplePregnancy,
  }){
    int score = 0;

    if (karinKasilma) score +=2;
    if (akinti) score +=1;
    if (belAgrisi) score +=1;
    if (stresSeviyesi >= 4) score +=1;
    if (previousPreterm) score +=2;
    if (multiplePregnancy) score +=2;

    if (score <= 2) return "LOW";
    if(score >2 && score<=5) return "MEDIUM";
    return "HIGH";
  }
  static Future<void> sendRiskNotification({
    required String uid,
    required String riskType,
    required String riskLevel,
  }) async {

    if (riskLevel != "HIGH") return;

    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    final userData = userDoc.data();
    final doctorId = userData?["assignedDoctor"];
    final patientName = userData?["name"] ?? "Bir hasta";

    // Aynı risk için daha önce bildirim var mı kontrol et
    final existing = await FirebaseFirestore.instance
        .collection("notification")
        .where("uid", isEqualTo: uid)
        .where("type", isEqualTo: "risk_alert")
        .where("riskType", isEqualTo: riskType)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return;
    }

    // Hamile kullanıcıya bildirim
    await FirebaseFirestore.instance.collection("notification").add({
      "uid": uid,
      "type": "risk_alert",
      "riskType": riskType,
      "title": "Risk Uyarısı",
      "message":
      "$riskType riski yüksek tespit edildi. Lütfen doktorunuzla iletişime geçiniz.",
      "isRead": false,
      "createdAt": FieldValue.serverTimestamp(),
    });

    // Doktora bildirim
    if (doctorId != null) {
      await FirebaseFirestore.instance.collection("notification").add({
        "uid": doctorId,
        "type": "risk_alert",
        "riskType": riskType,
        "title": "Riskli Hasta",
        "message": "$patientName adlı hastada $riskType riski HIGH çıktı.",
        "isRead": false,
        "createdAt": FieldValue.serverTimestamp(),
      });
    }
  }
}