import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SystemReportsPage extends StatefulWidget {
  const SystemReportsPage({super.key});

  @override
  State<SystemReportsPage> createState() => _SystemReportsPageState();
}

class _SystemReportsPageState extends State<SystemReportsPage> {

  int totalUsers = 0;
  int pregnant = 0;
  int doctors = 0;
  int dietitians = 0;

  int high = 0;
  int medium = 0;
  int low = 0;

  bool loading = true;

  double highPercent = 0;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {

      totalUsers = 0;
      pregnant = 0;
      doctors = 0;
      dietitians = 0;
      high = 0;
      medium = 0;
      low = 0;

      final users = await FirebaseFirestore.instance
          .collection("users")
          .get();

      totalUsers = users.docs.length;

      for (var u in users.docs) {
        final data = u.data();

        final role = data['role'] ?? '';

        if (role == "pregnant") pregnant++;
        if (role == "gynecologist") doctors++;
        if (role == "dietitian") dietitians++;
      }

      final risks = await FirebaseFirestore.instance
          .collection("risk_olcumleri")
          .get();

      for (var r in risks.docs) {
        final data = r.data();

        final risksList = [
          data['preeklampsiRisk'] ?? "LOW",
          data['diyabetRisk'] ?? "LOW",
          data['pretermRisk'] ?? "LOW"
        ];

        for (var risk in risksList) {
          if (risk == "HIGH") high++;
          if (risk == "MEDIUM") medium++;
          if (risk == "LOW") low++;
        }
      }

      int totalRisk = high + medium + low;

      if (totalRisk > 0) {
        highPercent = (high / totalRisk) * 100;
      }

    } catch (e) {
      print("SYSTEM REPORT ERROR: $e");
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Widget bigCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 6),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget infoCard(String title, String value, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  String getSystemComment() {
    if (highPercent > 30) {
      return "⚠️ Sistem yüksek risk altında!";
    } else if (highPercent > 15) {
      return "⚠️ Risk artışı gözlemleniyor.";
    } else {
      return "✅ Sistem stabil durumda.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        title: const Text("System Reports"),
        backgroundColor: Colors.purple,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// HEADER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.deepPurple],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("System Overview",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(getSystemComment(),
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// USER STATS
            const Text("Users",
                style: TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            Row(
              children: [
                bigCard("Total", totalUsers.toString(), Colors.blue),
                const SizedBox(width: 10),
                bigCard("Pregnant", pregnant.toString(), Colors.pink),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                bigCard("Doctors", doctors.toString(), Colors.green),
                const SizedBox(width: 10),
                bigCard("Dietitians", dietitians.toString(), Colors.orange),
              ],
            ),

            const SizedBox(height: 20),

            /// RISK ANALYSIS
            const Text("Risk Analysis",
                style: TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            infoCard("High Risk", high.toString(), Colors.red),
            infoCard("Medium Risk", medium.toString(), Colors.orange),
            infoCard("Low Risk", low.toString(), Colors.green),

            const SizedBox(height: 20),

            /// EXTRA INFO
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("System Insight",
                      style: TextStyle(fontWeight: FontWeight.bold)),

                  const SizedBox(height: 8),

                  Text(
                      "High risk oranı: ${highPercent.toStringAsFixed(1)}%"),

                  const SizedBox(height: 6),

                  Text(getSystemComment()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}