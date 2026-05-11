import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'hamile_besin_gecmisi_page.dart';
import 'hamile_olcum_gecmisi_page.dart';
import 'kisisel_bilgi_goruntule.dart';
import 'kisisel_bilgi_page.dart';
import 'language_selector.dart';
import 'l10n/app_localizations.dart';
import 'login_page.dart';
import 'sifre_degistir_page.dart';
import 'uzman_basvuru_page.dart';

class HesabimPage extends StatefulWidget {
  const HesabimPage({super.key});

  @override
  State<HesabimPage> createState() => _HesabimPageState();
}

class _HesabimPageState extends State<HesabimPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.account,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  l10n.accountSettingsSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              hesapButonu(l10n.personalInfo, kisiselBilgiKontrol),
              hesapButonu(l10n.lastMeasurementHistory, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HamileOlcumGecmisiPage(),
                  ),
                );
              }),
              hesapButonu(l10n.nutritionSupplementHistory, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HamileBesinGecmisiPage(),
                  ),
                );
              }),
              hesapButonu(l10n.changePassword, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SifreDegistirPage()),
                );
              }),
              hesapButonu(l10n.language, () => showLanguageDialog(context)),
              const SizedBox(height: 20),
              Divider(color: Theme.of(context).dividerColor),
              hesapButonu(
                l10n.expertApplication,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UzmanBasvuruPage()),
                  );
                },
                color: Theme.of(context).colorScheme.primary,
              ),
              const Spacer(),
              hesapButonu(l10n.logout, signOut, color: Colors.red.shade500),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> kisiselBilgiKontrol() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final data = snapshot.data();

    if (!mounted) return;

    if (data != null && data['profilTamamlandi'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const KisiselBilgilerGoruntulePage()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const KisiselBilgilerPage()),
      );
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Widget hesapButonu(String text, VoidCallback onTap, {Color? color}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
