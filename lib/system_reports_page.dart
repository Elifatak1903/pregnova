import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'language_selector.dart';
import 'l10n/app_localizations.dart';

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
      final applications = await firestore
          .collection('expert_applications')
          .get();

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

  Widget riskChart(AppLocalizations l10n) {
    final total = high + medium + low;

    if (total == 0) {
      return Center(child: Text(l10n.noRiskData));
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(l10n.highRisk),
            Text(l10n.mediumRisk),
            Text(l10n.lowRisk),
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
            style: TextStyle(fontWeight: FontWeight.bold, color: primary),
          ),
        ],
      ),
    );
  }

  String getSystemComment(AppLocalizations l10n) {
    if (highPercent > 30) {
      return l10n.riskRateNeedsAttention;
    } else if (highPercent > 15) {
      return l10n.riskRateIncreasing;
    } else {
      return l10n.systemStable;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.systemReports.replaceAll('\n', ' ')),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          const LanguageActionButton(),
          IconButton(
            tooltip: l10n.refresh,
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
                          Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.systemSummary,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          getSystemComment(l10n),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      bigCard(
                        l10n.totalUsers.replaceAll('\n', ' '),
                        totalUsers.toString(),
                        context,
                      ),
                      const SizedBox(width: 10),
                      bigCard(l10n.pregnantRole, pregnant.toString(), context),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      bigCard(l10n.gynecologist, doctors.toString(), context),
                      const SizedBox(width: 10),
                      bigCard(l10n.dietitian, dietitians.toString(), context),
                    ],
                  ),
                  const SizedBox(height: 20),
                  infoCard(
                    l10n.totalRiskMeasurements,
                    riskMeasurements.toString(),
                    context,
                  ),
                  infoCard(
                    l10n.totalNutritionAnalyses,
                    nutritionAnalyses.toString(),
                    context,
                  ),
                  infoCard(
                    l10n.pendingExpertApplications,
                    pendingApplications.toString(),
                    context,
                  ),
                  infoCard(
                    l10n.approvedExpertApplications,
                    approvedApplications.toString(),
                    context,
                  ),
                  infoCard(
                    l10n.rejectedExpertApplications,
                    rejectedApplications.toString(),
                    context,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.riskDistribution,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  riskChart(l10n),
                  const SizedBox(height: 20),
                  infoCard(l10n.highRisk, high.toString(), context),
                  infoCard(l10n.mediumRisk, medium.toString(), context),
                  infoCard(l10n.lowRisk, low.toString(), context),
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
                        Text(
                          l10n.systemInsight,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.highRiskPercent(highPercent.toStringAsFixed(1)),
                        ),
                        const SizedBox(height: 6),
                        Text(getSystemComment(l10n)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
