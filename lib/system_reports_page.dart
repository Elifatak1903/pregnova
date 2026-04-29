import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

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

  /// 🔥 CHART
  Widget riskChart() {
    final total = high + medium + low;

    if (total == 0) {
      return const Center(child: Text("Veri yok"));
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: [
                PieChartSectionData(
                  value: high.toDouble(),
                  color: Colors.red,
                  title: "${percent(high)}%",
                  radius: 50,
                  titleStyle: const TextStyle(color: Colors.white),
                ),
                PieChartSectionData(
                  value: medium.toDouble(),
                  color: Colors.orange,
                  title: "${percent(medium)}%",
                  radius: 50,
                  titleStyle: const TextStyle(color: Colors.white),
                ),
                PieChartSectionData(
                  value: low.toDouble(),
                  color: Colors.green,
                  title: "${percent(low)}%",
                  radius: 50,
                  titleStyle: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        /// 🔥 LEGEND
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            Text("🔴 High"),
            Text("🟠 Medium"),
            Text("🟢 Low"),
          ],
        )
      ],
    );
  }

  String percent(int val) {
    final total = high + medium + low;
    if (total == 0) return "0";
    return ((val / total) * 100).toStringAsFixed(0);
  }

  Widget bigCard(String title, String value, BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget infoCard(String title, String value, BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("System Reports"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.primary,
      ))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// HEADER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("System Overview",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(getSystemComment(),
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// USER STATS
            Row(
              children: [
                bigCard("Total", totalUsers.toString(), context),
                const SizedBox(width: 10),
                bigCard("Pregnant", pregnant.toString(), context),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                bigCard("Doctors", doctors.toString(), context),
                const SizedBox(width: 10),
                bigCard("Dietitians", dietitians.toString(), context),
              ],
            ),

            const SizedBox(height: 20),

            /// 🔥 CHART EKLENDİ
            const Text("Risk Distribution",
                style: TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            riskChart(),

            const SizedBox(height: 20),

            /// RISK LIST
            infoCard("High Risk", high.toString(), context),
            infoCard("Medium Risk", medium.toString(), context),
            infoCard("Low Risk", low.toString(), context),

            const SizedBox(height: 20),

            /// INSIGHT
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("System Insight",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("High risk oranı: ${highPercent.toStringAsFixed(1)}%"),
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