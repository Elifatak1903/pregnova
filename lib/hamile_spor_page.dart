import 'package:flutter/material.dart';
import 'egzersiz_detay_page.dart'; // 🔥 BUNU EKLE

class HamileSporPage extends StatelessWidget {
  final List<Map<String, String>> egzersizler = [
    {
      "ad": "5 dakika nefes egzersizi",
      "ikon": "🧘‍♀️",
      "resim": "assets/nefes.png",
      "aciklama": "Derin nefes alıp vererek stres azaltan 5 dakikalık nefes çalışması."
    },
    {
      "ad": "20 dakika hafif yürüyüş",
      "ikon": "🚶‍♀️",
      "resim": "assets/yuruyus.png",
      "aciklama": "Günde 20 dakika tempolu yürüyüş, dolaşımı artırır ve enerji verir."
    },
    {
      "ad": "Kalça esnetme hareketleri",
      "ikon": "🧎‍♀️",
      "resim": "assets/kalca.png",
      "aciklama": "Bel ağrılarını azaltan esnetme hareketleri."
    },
    {
      "ad": "Bel destek egzersizleri",
      "ikon": "🤰",
      "resim": "assets/bel.png",
      "aciklama": "Hamilelikte bel kaslarını güçlendiren destek hareketleri."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: Text("Spor Egzersizleri"),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: egzersizler.length,
        itemBuilder: (context, index) {
          final e = egzersizler[index];

          return InkWell(               // 🔥 TAM BURASI ADIM 2
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EgzersizDetayPage(
                    ad: e["ad"]!,
                    resim: e["resim"]!,
                    aciklama: e["aciklama"]!,
                  ),
                ),
              );
            },

            child: Card(
              color: Colors.white,
              elevation: 3,
              shadowColor: Colors.pink.shade200,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Text(
                  e["ikon"]!,
                  style: TextStyle(fontSize: 28),
                ),
                title: Text(
                  e["ad"]!,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.pink.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Icon(Icons.arrow_forward_ios,
                    size: 18, color: Colors.pink.shade400),
              ),
            ),
          );
        },
      ),
    );
  }
}

