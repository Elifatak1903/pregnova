import 'package:flutter/material.dart';

class EgzersizDetayPage extends StatelessWidget {
  final String ad;
  final String resim;
  final String aciklama;

  const EgzersizDetayPage({
    super.key,
    required this.ad,
    required this.resim,
    required this.aciklama,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: Text(ad),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // FOTO
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: AssetImage(resim),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // BAŞLIK
            Text(
              ad,
              style: TextStyle(
                color: Colors.pink.shade700,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // AÇIKLAMA
            Text(
              aciklama,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
