import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UzmanAraPage extends StatefulWidget {
  const UzmanAraPage({super.key});

  @override
  State<UzmanAraPage> createState() => _UzmanAraPageState();
}

class _UzmanAraPageState extends State<UzmanAraPage> {

  String selectedRole = 'all';
  String searchText = "";

  late Stream<QuerySnapshot> expertsStream;

  @override
  void initState() {
    super.initState();
    expertsStream = _createStream();
  }

  Stream<QuerySnapshot> _createStream() {
    final ref = FirebaseFirestore.instance.collection('users');

    if (selectedRole == 'dietitian') {
      return ref.where('role', isEqualTo: 'dietitian').snapshots();
    }

    if (selectedRole == 'gynecologist') {
      return ref.where('role', isEqualTo: 'gynecologist').snapshots();
    }

    return ref
        .where('role', whereIn: ['dietitian', 'gynecologist'])
        .snapshots();
  }

  void _updateFilter(String value) {
    setState(() {
      selectedRole = value;
      expertsStream = _createStream();
    });
  }

  void showSnack(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {

    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,

      body: SafeArea(
        child: Column(
          children: [

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🔥 BAŞLIK
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Uzman Ara",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  /// 🔥 ALT YAZI
                  Text(
                    "Size uygun uzmanı seçin",
                    textAlign: TextAlign.center, // 🔥 BU DA ÖNEMLİ
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (val) {
                  setState(() {
                    searchText = val.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: "İsim ara...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _filterChip("Tümü", "all"),
                  _filterChip("Diyetisyen", "dietitian"),
                  _filterChip("Jinekolog", "gynecologist"),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .doc(currentUserId)
                    .snapshots(),

                builder: (context, userSnap) {

                  if (!userSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final userData =
                  userSnap.data!.data() as Map<String, dynamic>;

                  final assignedDoctor = userData['assignedDoctor'];
                  final assignedDietitian = userData['assignedDietitian'];

                  return StreamBuilder<QuerySnapshot>(
                    stream: expertsStream,
                    builder: (context, snapshot) {

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final experts = snapshot.data!.docs;

                      final filteredExperts = experts.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['name'] ?? "").toString().toLowerCase();

                        if (searchText.isNotEmpty && !name.contains(searchText)) {
                          return false;
                        }

                        return true;
                      }).toList();

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredExperts.length,
                        itemBuilder: (context, index) {

                          final doc = filteredExperts[index];
                          final data = doc.data() as Map<String, dynamic>;

                          final role = data['role'] ?? '';
                          final name = data['name'] ?? "Uzman";
                          final hospital = data['hospital'] ?? "Kurum bilgisi yok";

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),

                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: const Icon(Icons.medical_services, color: Colors.white),
                              ),

                              title: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),

                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(role == 'dietitian' ? "Diyetisyen" : "Jinekolog"),
                                  const SizedBox(height: 3),
                                  Text(
                                    hospital,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),

                              trailing: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection("expert_requests")
                                    .where("clientId", isEqualTo: currentUserId)
                                    .where("expertId", isEqualTo: doc.id)
                                    .snapshots(),

                                builder: (context, snap) {

                                  bool isAssigned =
                                      assignedDoctor == doc.id ||
                                          assignedDietitian == doc.id;

                                  if (isAssigned) {
                                    return ElevatedButton(
                                      onPressed: null,
                                      child: const Text("Danışan"),
                                    );
                                  }

                                  String status = "none";

                                  if (snap.hasData && snap.data!.docs.isNotEmpty) {
                                    final reqData = snap.data!.docs.first.data() as Map<String, dynamic>;
                                    status = reqData['status'].toString().toLowerCase();
                                  }

                                  if (status == "pending") {
                                    return ElevatedButton(
                                      onPressed: null,
                                      child: const Text("Beklemede"),
                                    );
                                  }

                                  return ElevatedButton(
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection("expert_requests")
                                          .add({
                                        "clientId": currentUserId,
                                        "expertId": doc.id,
                                        "status": "pending",
                                        "createdAt": FieldValue.serverTimestamp(),
                                      });

                                      showSnack("İstek gönderildi ✅");
                                    },
                                    child: const Text("İstek"),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = selectedRole == value;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
      onSelected: (_) => _updateFilter(value),
    );
  }
}