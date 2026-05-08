import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'expert_detail_page.dart';

class AdminExpertRequestsPage extends StatefulWidget {
  const AdminExpertRequestsPage({super.key});

  @override
  State<AdminExpertRequestsPage> createState() =>
      _AdminExpertRequestsPageState();
}

class _AdminExpertRequestsPageState extends State<AdminExpertRequestsPage> {
  String statusFilter = 'pending';
  String roleFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Uzman Başvuruları"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: [
          _FilterBar(
            statusFilter: statusFilter,
            roleFilter: roleFilter,
            onStatusChanged: (value) => setState(() => statusFilter = value),
            onRoleChanged: (value) => setState(() => roleFilter = value),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('expert_applications')
                  .where('status', isEqualTo: statusFilter)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData) {
                  return const Center(child: Text("Başvuru bulunamadı"));
                }

                final docs = snapshot.data!.docs.where((doc) {
                  if (roleFilter == 'all') return true;
                  final data = doc.data() as Map<String, dynamic>;
                  return data['role'] == roleFilter;
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Text("${_statusLabel(statusFilter)} başvuru yok"),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    return _ApplicationCard(
                      doc: docs[index],
                      showActions: statusFilter == 'pending',
                      onApprove: () => approveExpert(context, docs[index]),
                      onReject: () => rejectExpert(context, docs[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> rejectExpert(
    BuildContext context,
    QueryDocumentSnapshot doc,
  ) async {
    await doc.reference.update({'status': 'rejected'});

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Başvuru reddedildi")),
    );
  }

  Future<void> approveExpert(
    BuildContext context,
    QueryDocumentSnapshot doc,
  ) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final uid = data['uid'];
      final role = data['role'];
      final diplomaUrl = data['documentUrl'] ?? data['diplomaUrl'];

      final batch = FirebaseFirestore.instance.batch();

      batch.update(
        FirebaseFirestore.instance.collection('users').doc(uid),
        {
          'role': role,
          'diplomaUrl': diplomaUrl,
        },
      );

      batch.update(
        doc.reference,
        {'status': 'approved'},
      );

      batch.set(
        FirebaseFirestore.instance.collection('notification').doc(),
        {
          'uid': uid,
          'title': 'Uzman Başvurun Onaylandı',
          'message': 'Artık PregNova’da uzman olarak giriş yapabilirsin.',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Uzman onaylandı")),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Onay hatası: $e")),
      );
    }
  }
}

class _FilterBar extends StatelessWidget {
  final String statusFilter;
  final String roleFilter;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onRoleChanged;

  const _FilterBar({
    required this.statusFilter,
    required this.roleFilter,
    required this.onStatusChanged,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              _filterChip("Bekleyen", "pending", statusFilter, onStatusChanged),
              _filterChip("Onaylanan", "approved", statusFilter, onStatusChanged),
              _filterChip("Reddedilen", "rejected", statusFilter, onStatusChanged),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _filterChip("Tümü", "all", roleFilter, onRoleChanged),
              _filterChip("Jinekolog", "gynecologist", roleFilter, onRoleChanged),
              _filterChip("Diyetisyen", "dietitian", roleFilter, onRoleChanged),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    String label,
    String value,
    String selected,
    ValueChanged<String> onChanged,
  ) {
    return FilterChip(
      label: Text(label),
      selected: selected == value,
      onSelected: (_) => onChanged(value),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final bool showActions;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ApplicationCard({
    required this.doc,
    required this.showActions,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 3,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          data['email'] ?? "-",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text("Rol: ${_roleLabel(data['role'])}"),
            Text("Durum: ${_statusLabel(data['status'])}"),
            Text("Lisans No: ${data['licenseNumber'] ?? '-'}"),
            if (data['experience'] != null)
              Text("Deneyim: ${data['experience']}"),
            if (data['hospital'] != null)
              Text("Kurum: ${data['hospital']}"),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showActions) ...[
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: onReject,
              ),
              IconButton(
                icon: Icon(
                  Icons.check,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: onApprove,
              ),
            ],
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExpertDetailPage(doc: doc),
            ),
          );
        },
      ),
    );
  }
}

String _statusLabel(String? status) {
  switch (status) {
    case 'approved':
      return 'Onaylanan';
    case 'rejected':
      return 'Reddedilen';
    case 'pending':
    default:
      return 'Bekleyen';
  }
}

String _roleLabel(String? role) {
  switch (role) {
    case 'gynecologist':
      return 'Jinekolog';
    case 'dietitian':
      return 'Diyetisyen';
    default:
      return role ?? '-';
  }
}
