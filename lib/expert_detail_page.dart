import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

class ExpertDetailPage extends StatelessWidget {
  final QueryDocumentSnapshot doc;

  const ExpertDetailPage({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = doc.data() as Map<String, dynamic>;
    final status = (data['status'] ?? 'pending').toString();
    final diplomaUrl = (data['documentUrl'] ?? data['diplomaUrl'] ?? '')
        .toString()
        .trim();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.applicationDetail),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withValues(alpha: 0.2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['email'] ?? '-',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          getRoleText(l10n, data['role']),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            _infoCard(
              context,
              Icons.badge,
              l10n.licenseNumber,
              data['licenseNumber'],
            ),
            _infoCard(context, Icons.work, l10n.experience, data['experience']),
            _infoCard(context, Icons.phone, l10n.phone, data['phone']),
            _infoCard(
              context,
              Icons.local_hospital,
              l10n.institution,
              data['hospital'],
            ),
            _infoCard(context, Icons.location_city, l10n.city, data['city']),
            const SizedBox(height: 25),
            if (diplomaUrl.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.description),
                  label: Text(l10n.viewDiploma),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(
                            title: Text(l10n.diploma),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                          ),
                          body: Center(
                            child: InteractiveViewer(
                              child: Image.network(
                                diplomaUrl,
                                errorBuilder: (_, __, ___) {
                                  return Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Text(
                                      l10n.documentPreviewUnavailable,
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(l10n.noDiplomaDocument),
              ),
            _statusCard(context, status, l10n),
            if (status == 'pending') ...[
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.close),
                      label: Text(l10n.reject),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => rejectExpert(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: Text(l10n.approve),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => approveExpert(context, data, diplomaUrl),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> rejectExpert(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    await doc.reference.update({'status': 'rejected'});

    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.applicationRejected)));

    Navigator.pop(context);
  }

  Future<void> approveExpert(
    BuildContext context,
    Map<String, dynamic> data,
    String diplomaUrl,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final uid = (data['uid'] ?? '').toString();
    if (uid.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();

    batch.update(FirebaseFirestore.instance.collection('users').doc(uid), {
      'role': data['role'],
      'diplomaUrl': diplomaUrl,
      'isApproved': true,
    });

    batch.update(doc.reference, {
      'status': 'approved',
      'diplomaUrl': diplomaUrl,
    });

    batch.set(FirebaseFirestore.instance.collection('notification').doc(), {
      'uid': uid,
      'type': 'expert_application',
      'title': l10n.applicationApprovedNotificationTitle,
      'message': l10n.applicationApprovedNotificationMessage,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.expertApproved)));

    Navigator.pop(context);
  }

  Widget _statusCard(
    BuildContext context,
    String status,
    AppLocalizations l10n,
  ) {
    final isApproved = status == 'approved';
    final isRejected = status == 'rejected';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isApproved
            ? Colors.green.withValues(alpha: 0.12)
            : isRejected
            ? Colors.red.withValues(alpha: 0.12)
            : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isApproved
                ? Icons.check_circle
                : isRejected
                ? Icons.cancel
                : Icons.hourglass_top,
            color: isApproved
                ? Colors.green
                : isRejected
                ? Colors.red
                : Colors.orange,
          ),
          const SizedBox(width: 8),
          Text(getStatusText(l10n, status)),
        ],
      ),
    );
  }

  Widget _infoCard(
    BuildContext context,
    IconData icon,
    String title,
    dynamic value,
  ) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(value?.toString() ?? '-'),
      ),
    );
  }

  String getRoleText(AppLocalizations l10n, dynamic role) {
    if (role == 'gynecologist') return l10n.gynecologist;
    if (role == 'dietitian') return l10n.dietitian;
    return role?.toString() ?? '-';
  }

  String getStatusText(AppLocalizations l10n, String status) {
    if (status == 'approved') return l10n.applicationApproved;
    if (status == 'rejected') return l10n.applicationRejectedShort;
    return l10n.applicationPending;
  }
}
