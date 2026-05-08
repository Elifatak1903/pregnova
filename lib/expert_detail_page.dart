import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ExpertDetailPage extends StatelessWidget {
  final QueryDocumentSnapshot doc;

  const ExpertDetailPage({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final status = (data['status'] ?? 'pending').toString();
    final diplomaUrl = (data['documentUrl'] ?? data['diplomaUrl'] ?? '')
        .toString()
        .trim();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Başvuru Detayı'),
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
                          getRoleText(data['role']),
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
            _infoCard(context, Icons.badge, 'Lisans No', data['licenseNumber']),
            _infoCard(context, Icons.work, 'Deneyim', data['experience']),
            _infoCard(context, Icons.phone, 'Telefon', data['phone']),
            _infoCard(context, Icons.local_hospital, 'Kurum', data['hospital']),
            _infoCard(context, Icons.location_city, 'Şehir', data['city']),
            const SizedBox(height: 25),
            if (diplomaUrl.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.description),
                  label: const Text('Diplomayı Gör'),
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
                            title: const Text('Diploma'),
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                          body: Center(
                            child: InteractiveViewer(
                              child: Image.network(
                                diplomaUrl,
                                errorBuilder: (_, __, ___) {
                                  return const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Text(
                                      'Belge önizlenemedi. Dosya PDF ise web panelinden bağlantı olarak açılabilir.',
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
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text('Diploma/belge bulunamadı'),
              ),
            _statusCard(context, status),
            if (status == 'pending') ...[
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Reddet'),
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
                      label: const Text('Onayla'),
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
    await doc.reference.update({'status': 'rejected'});

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Başvuru reddedildi')),
    );

    Navigator.pop(context);
  }

  Future<void> approveExpert(
    BuildContext context,
    Map<String, dynamic> data,
    String diplomaUrl,
  ) async {
    final uid = (data['uid'] ?? '').toString();
    if (uid.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();

    batch.update(
      FirebaseFirestore.instance.collection('users').doc(uid),
      {
        'role': data['role'],
        'diplomaUrl': diplomaUrl,
        'isApproved': true,
      },
    );

    batch.update(
      doc.reference,
      {
        'status': 'approved',
        'diplomaUrl': diplomaUrl,
      },
    );

    batch.set(
      FirebaseFirestore.instance.collection('notification').doc(),
      {
        'uid': uid,
        'type': 'expert_application',
        'title': 'Başvurun Onaylandı',
        'message': 'Artık uzman olarak giriş yapabilirsin.',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uzman onaylandı')),
    );

    Navigator.pop(context);
  }

  Widget _statusCard(BuildContext context, String status) {
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
          Text(getStatusText(status)),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(value?.toString() ?? '-'),
      ),
    );
  }

  String getRoleText(dynamic role) {
    if (role == 'gynecologist') return 'Jinekolog';
    if (role == 'dietitian') return 'Diyetisyen';
    return role?.toString() ?? '-';
  }

  String getStatusText(String status) {
    if (status == 'approved') return 'Başvuru onaylandı';
    if (status == 'rejected') return 'Başvuru reddedildi';
    return 'Başvuru beklemede';
  }
}
