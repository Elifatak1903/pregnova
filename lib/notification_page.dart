import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_expert_request_page.dart';
import 'diyetisyen_page.dart';
import 'expert_chat_list_page.dart';
import 'hamile_olcum_gecmisi_page.dart';
import 'jinekolog_page.dart';
import 'l10n/app_localizations.dart';
import 'message_page.dart';
import 'son_analizler_page.dart';
import 'son_olcumler_page.dart';
import 'uzman_ara_page.dart';
import 'uzman_basvuru_page.dart';

String timeAgo(Timestamp? timestamp, AppLocalizations l10n) {
  if (timestamp == null) return "";

  final now = DateTime.now();
  final date = timestamp.toDate();
  final diff = now.difference(date);

  if (diff.inSeconds < 60) return l10n.justNow;
  if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);

  return "${date.day}.${date.month}.${date.year}";
}

class NotificationPanel extends StatelessWidget {
  const NotificationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        body: Center(
          child: Text(
            l10n.notLoggedIn,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection("users").doc(uid).get(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
        final role = userData["role"]?.toString() ?? "";
        final primaryColor = Theme.of(context).colorScheme.primary;
        final backgroundColor = Theme.of(context).colorScheme.surface;

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: primaryColor,
            title: Text(
              l10n.notifications,
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            centerTitle: true,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notification')
                .where('uid', isEqualTo: uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    l10n.noNotificationsYet,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  final isRead = data['isRead'] ?? false;
                  final type = data['type'] ?? "general";
                  final title = data['title'] ?? "";
                  final message = data['message'] ?? "";
                  final createdAt = data['createdAt'] as Timestamp?;
                  final timeText = timeAgo(createdAt, l10n);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isRead
                          ? Theme.of(context).colorScheme.surface
                          : primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isRead
                            ? Theme.of(context).dividerColor
                            : primaryColor,
                      ),
                    ),
                    child: ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: primaryColor,
                            child: Icon(
                              type == "risk_alert"
                                  ? Icons.warning
                                  : Icons.notifications,
                              color: Colors.white,
                            ),
                          ),
                          if (!isRead)
                            const Positioned(
                              right: 0,
                              top: 0,
                              child: CircleAvatar(
                                radius: 5,
                                backgroundColor: Colors.black,
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        title,
                        style: TextStyle(
                          fontWeight: isRead
                              ? FontWeight.w500
                              : FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      onTap: () async {
                        if (!isRead) {
                          await doc.reference.update({'isRead': true});
                        }

                        if (context.mounted) {
                          _openNotificationTarget(context, data, role);
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _openNotificationTarget(
    BuildContext context,
    Map<String, dynamic> data,
    String role,
  ) {
    final target = _notificationTarget(data, role);
    if (target == null) return;

    Navigator.push(context, MaterialPageRoute(builder: (_) => target));
  }

  Widget? _notificationTarget(Map<String, dynamic> data, String role) {
    final type = data["type"]?.toString() ?? "general";

    if (type == "weekly_info") {
      return const HamileOlcumGecmisiPage();
    }

    if (type == "risk_alert") {
      if (role == "gynecologist") {
        final patientId = _firstText(data, ["patientId", "clientId"]);
        return SonOlcumlerPage(selectedUid: patientId);
      }

      if (role == "dietitian") {
        return const SonAnalizlerPage();
      }

      return const HamileOlcumGecmisiPage();
    }

    if (type == "expert_application") {
      return role == "admin"
          ? const AdminExpertRequestsPage()
          : const UzmanBasvuruPage();
    }

    if (type == "expert_request") {
      if (role == "gynecologist") return const GynecologistHomePage();
      if (role == "dietitian") return const DietitianHomePage();
      return const UzmanAraPage();
    }

    if (type == "message") {
      if (role == "gynecologist" || role == "dietitian") {
        return const ExpertChatListPage();
      }

      return const MessagePage();
    }

    return null;
  }

  String? _firstText(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }

    return null;
  }
}
