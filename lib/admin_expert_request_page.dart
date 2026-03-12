import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminExpertRequestsPage extends StatelessWidget {
  const AdminExpertRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Uzman Başvuruları"),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('expert_applications')
            .where('status', isEqualTo: 'pending')
            //.orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Bekleyen uzman başvurusu yok 👌"),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(doc['email']),
                  subtitle: Text(
                    "${doc['role']} • Lisans: ${doc['licenseNumber']}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          doc.reference.update({'status': 'rejected'});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () async {
                          await approveExpert(context, doc);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> approveExpert(
      BuildContext context,
      QueryDocumentSnapshot doc,
      ) async {
    try {
      final uid = doc['uid'];
      final role = doc['role'];

      final batch = FirebaseFirestore.instance.batch();

      batch.update(
        FirebaseFirestore.instance.collection('users').doc(uid),
        {'role': role},
      );

      batch.update(
        doc.reference,
        {'status': 'approved'},
      );

      batch.set(
        FirebaseFirestore.instance.collection('notification').doc(),
        {
          'uid': uid,
          'title': 'Uzman Başvurun Onaylandı 🎉',
          'message': 'Artık PregNova’da uzman olarak giriş yapabilirsin.',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Uzman onaylandı ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Onay hatası: $e")),
      );
    }
  }

}
