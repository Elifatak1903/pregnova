import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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

  int riskMeasurements = 0;
  int nutritionAnalyses = 0;
  int pendingApplications = 0;
  int approvedApplications = 0;
  int rejectedApplications = 0;

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
    setState(() => loading = true);

    try {
      totalUsers = 0;
      pregnant = 0;
      doctors = 0;
      dietitians = 0;
      riskMeasurements = 0;
      nutritionAnalyses = 0;
      pendingApplications = 0;
      approvedApplications = 0;
      rejectedApplications = 0;
      high = 0;
      medium = 0;
      low = 0;
      highPercent = 0;

      final firestore = FirebaseFirestore.instance;
      final users = await firestore.collection('users').get();
      final risks = await firestore.collection('risk_olcumleri').get();
      final nutrition = await firestore.collection('besin_analizleri').get();
      final applications =
          await firestore.collection('expert_applications').get();

      totalUsers = users.docs.length;
      nutritionAnalyses = nutrition.docs.length;
      riskMeasurements = risks.docs.length;

      for (final user in users.docs) {
        final role = user.data()['role'];

        if (role == 'pregnant') pregnant++;
        if (role == 'gynecologist') doctors++;
        if (role == 'dietitian') dietitians++;
      }

      for (final doc in applications.docs) {
        switch ((doc.data()['status'] ?? 'pending').toString()) {
          case 'approved':
            approvedApplications++;
            break;
          case 'rejected':
            rejectedApplications++;
            break;
          default:
            pendingApplications++;
        }
      }

      for (final riskDoc in risks.docs) {
        final data = riskDoc.data();

        for (final risk in [
          data['preeklampsiRisk'],
          data['diyabetRisk'],
          data['pretermRisk'],
        ]) {
          registerRisk(risk);
        }
      }

      final totalRisk = high + medium + low;
      if (totalRisk > 0) {
        highPercent = (high / totalRisk) * 100;
      }
    } catch (e) {
      debugPrint('SYSTEM REPORT ERROR: $e');
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  void registerRisk(dynamic risk) {
    final normalized = (risk ?? 'LOW').toString().trim().toUpperCase();

    if (normalized == 'HIGH') {
      high++;
    } else if (normalized == 'MEDIUM') {
      medium++;
    } else {
      low++;
    }
  }

  Widget riskChart() {
    final total = high + medium + low;

    if (total == 0) {
      return const Center(child: Text('Risk verisi yok'));
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
                  title: '${percent(high)}%',
                  radius: 50,
                  titleStyle: const TextStyle(color: Colors.white),
                ),
                PieChartSectionData(
                  value: medium.toDouble(),
                  color: Colors.orange,
                  title: '${percent(medium)}%',
                  radius: 50,
                  titleStyle: const TextStyle(color: Colors.white),
                ),
                PieChartSectionData(
                  value: low.toDouble(),
                  color: Colors.green,
                  title: '${percent(low)}%',
                  radius: 50,
                  titleStyle: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text('Yüksek'),
            Text('Orta'),
            Text('Düşük'),
          ],
        ),
      ],
    );
  }

  String percent(int value) {
    final total = high + medium + low;
    if (total == 0) return '0';
    return ((value / total) * 100).toStringAsFixed(0);
  }

  Widget bigCard(String title, String value, BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
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
            Text(title, textAlign: TextAlign.center),
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
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(title)),
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
      return 'Yüksek risk oranı dikkat gerektiriyor.';
    } else if (highPercent > 15) {
      return 'Risk oranında artış gözlemleniyor.';
    } else {
      return 'Sistem stabil durumda.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Sistem Raporları'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: fetchData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sistem Özeti',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          getSystemComment(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      bigCard('Toplam Kullanıcı', totalUsers.toString(), context),
                      const SizedBox(width: 10),
                      bigCard('Hamile', pregnant.toString(), context),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      bigCard('Jinekolog', doctors.toString(), context),
                      const SizedBox(width: 10),
                      bigCard('Diyetisyen', dietitians.toString(), context),
                    ],
                  ),
                  const SizedBox(height: 20),
                  infoCard(
                    'Toplam risk ölçümü',
                    riskMeasurements.toString(),
                    context,
                  ),
                  infoCard(
                    'Toplam besin analizi',
                    nutritionAnalyses.toString(),
                    context,
                  ),
                  infoCard(
                    'Bekleyen uzman başvurusu',
                    pendingApplications.toString(),
                    context,
                  ),
                  infoCard(
                    'Onaylanan uzman başvurusu',
                    approvedApplications.toString(),
                    context,
                  ),
                  infoCard(
                    'Reddedilen uzman başvurusu',
                    rejectedApplications.toString(),
                    context,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Risk Dağılımı',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  riskChart(),
                  const SizedBox(height: 20),
                  infoCard('Yüksek risk', high.toString(), context),
                  infoCard('Orta risk', medium.toString(), context),
                  infoCard('Düşük risk', low.toString(), context),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sistem İçgörüsü',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Yüksek risk oranı: ${highPercent.toStringAsFixed(1)}%',
                        ),
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
