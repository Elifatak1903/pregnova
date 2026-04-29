import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DiyetPage extends StatelessWidget {
  const DiyetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text("Giriş yapmalısın"));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Diyet Planım"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("diet_plans")
            .where("clientId", isEqualTo: uid)
            .orderBy("createdAt", descending: true)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Henüz diyet planın yok 🥲"),
            );
          }

          final data =
          snapshot.data!.docs.first.data() as Map<String, dynamic>;

          final createdAt = data["createdAt"];
          DateTime? date;

          if (createdAt is Timestamp) {
            date = createdAt.toDate();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                /// 🔥 SADECE TARİH BUTONU KALDI
                GestureDetector(
                  onTap: () => showDietDetail(context, data, date),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "📅 ${formatDate(date)} - Diyeti Gör",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              ],
            ),
          );
        },
      ),
    );
  }

  Widget mealCard(BuildContext context, String title, dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 6,
          )
        ],
      ),
      child: Row(
        children: [

          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.restaurant, color: Colors.white),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  value.toString(),
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget noteCard(BuildContext context, String note) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(note)),
        ],
      ),
    );
  }

  String formatDate(DateTime? d) {
    if (d == null) return "-";
    return "${d.day}/${d.month}/${d.year}";
  }

  void showDietDetail(
      BuildContext context,
      Map<String, dynamic> data,
      DateTime? date) {

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              Text(
                "Diyet Detayı - ${formatDate(date)}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),

              const SizedBox(height: 15),

              Expanded(
                child: ListView(
                  children: [
                    textItem("Kahvaltı", data["kahvalti"]),
                    textItem("Ara 1", data["ara1"]),
                    textItem("Öğle", data["ogle"]),
                    textItem("Ara 2", data["ara2"]),
                    textItem("Akşam", data["aksam"]),
                    textItem("Gece", data["gece"]),
                    textItem("Not", data["notlar"]),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget textItem(String title, dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text("• $title: $value"),
    );
  }
}