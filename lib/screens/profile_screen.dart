import 'package:flutter/material.dart';
import '../core/orders.dart';
import '../core/theme.dart';
import '../widgets/animations.dart';
import 'more_screens.dart';
import 'rating_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _phone = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final n = await LocalStore.getName();
    final p = await LocalStore.getPhone();
    if (!mounted) return;
    setState(() {
      _name = n;
      _phone = p;
    });
  }

  Future<void> _edit() async {
    final nameCtrl = TextEditingController(text: _name);
    final phoneCtrl = TextEditingController(text: _phone);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Profile edit karein'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Naam'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile number'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) {
      await LocalStore.saveProfile(nameCtrl.text.trim(), phoneCtrl.text.trim());
      _load();
    }
    nameCtrl.dispose();
    phoneCtrl.dispose();
  }

  Widget _menu(IconData icon, String title, Widget page) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.brand),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.ink2),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = _name.isEmpty ? '?' : _name[0].toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FadeSlideIn(
            index: 0,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.navy, AppColors.brand, Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Text(initial,
                        style: const TextStyle(
                            color: AppColors.brand,
                            fontSize: 24,
                            fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_name.isEmpty ? 'Naam set karein' : _name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(_phone.isEmpty ? 'Mobile number add karein' : _phone,
                            style: const TextStyle(color: Color(0xFFC7D2FE))),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _edit,
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FadeSlideIn(index: 1, child: _menu(Icons.payments_outlined, 'Payment Options', const PaymentOptionsScreen())),
          FadeSlideIn(index: 2, child: _menu(Icons.star_outline_rounded, 'Rating & Review', const RatingScreen())),
          FadeSlideIn(index: 3, child: _menu(Icons.support_agent, 'Help & Support', const HelpScreen())),
          FadeSlideIn(index: 4, child: _menu(Icons.settings_outlined, 'Settings', const SettingsScreen())),
          FadeSlideIn(index: 5, child: _menu(Icons.privacy_tip_outlined, 'Privacy Policy', const PrivacyScreen())),
        ],
      ),
    );
  }
}
