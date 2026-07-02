import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _signingOut = false;

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    await AuthService.signOut();
    // StreamBuilder in main.dart switches to AuthScreen automatically
    if (mounted) setState(() => _signingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor, elevation: 0,
        title: const Text('Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 12),
          // Avatar
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: kAccent.withValues(alpha: 0.12), shape: BoxShape.circle,
              border: Border.all(color: kAccent.withValues(alpha: 0.4), width: 2),
            ),
            child: const Icon(Icons.person_rounded, size: 40, color: kAccent),
          ),
          const SizedBox(height: 14),
          Text(user?.email ?? '—',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: kGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20), border: Border.all(color: kGreen.withValues(alpha: 0.4))),
            child: Text(user?.emailVerified == true ? '✓ Verified' : 'Signed in',
              style: const TextStyle(fontSize: 11, color: kGreen, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 28),
          // Info tile
          _InfoTile(icon: Icons.fingerprint_rounded, label: 'User ID', value: user?.uid ?? '—'),
          const SizedBox(height: 10),
          _InfoTile(icon: Icons.email_outlined, label: 'Email', value: user?.email ?? '—'),
          const SizedBox(height: 28),
          // Sign Out
          SizedBox(width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _signingOut ? null : _signOut,
              icon: _signingOut
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: kRed))
                  : const Icon(Icons.logout_rounded, size: 18, color: kRed),
              label: Text(_signingOut ? 'Signing out…' : 'Sign Out',
                style: const TextStyle(color: kRed, fontWeight: FontWeight.w800)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kRed),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon; final String label, value;
  const _InfoTile({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kBorderColor)),
    child: Row(children: [
      Container(width: 36, height: 36,
        decoration: BoxDecoration(color: kAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: kAccent)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: kTextSecond)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
          overflow: TextOverflow.ellipsis),
      ])),
    ]),
  );
}
