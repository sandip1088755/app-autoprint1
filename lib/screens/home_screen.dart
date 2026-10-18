import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/animations.dart';
import 'print_screen.dart';
import 'scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _shopCtrl = TextEditingController();

  @override
  void dispose() {
    _shopCtrl.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final id = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (id != null && mounted) _openShop(id);
  }

  void _openShop(String shopId) {
    final id = shopId.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop ID daalein')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PrintScreen(shopId: id)),
    );
  }

  static const _steps = [
    (Color(0xFF6366F1), Icons.qr_code_2, 'Shop ka QR scan karein'),
    (Color(0xFF0EA5E9), Icons.upload_file, 'PDF ya photo upload karein'),
    (Color(0xFF10B981), Icons.tune, 'Pages aur copies chunein'),
    (Color(0xFFF59E0B), Icons.payments_outlined, 'UPI se pay karein'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          FadeSlideIn(index: 0, child: _hero()),
          const SizedBox(height: 18),
          FadeSlideIn(
            index: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _scanButton(),
            ),
          ),
          FadeSlideIn(
            index: 2,
            child: SectionCard(
              title: 'Ya shop ID daalein',
              child: Column(
                children: [
                  TextField(
                    controller: _shopCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Shop ID',
                      prefixIcon: Icon(Icons.storefront_outlined,
                          color: AppColors.brand),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _openShop(_shopCtrl.text),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        foregroundColor: AppColors.brand,
                        side: const BorderSide(color: AppColors.brand, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Shop kholein',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          FadeSlideIn(
            index: 3,
            child: const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Text('Kaise kaam karta hai',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AppColors.ink)),
            ),
          ),
          for (var i = 0; i < _steps.length; i++)
            FadeSlideIn(
              index: 4 + i,
              child: _step(i + 1, _steps[i].$1, _steps[i].$2, _steps[i].$3),
            ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _hero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, AppColors.brand, Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.print_rounded, color: AppColors.brand, size: 32),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AutoPrint',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5)),
                SizedBox(height: 2),
                Text('QR scan karo, file upload karo, print lo',
                    style: TextStyle(
                        color: Color(0xFFC7D2FE),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scanButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _scan,
        child: Ink(
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFFDB2777)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner, color: Colors.white),
              SizedBox(width: 10),
              Text('Shop ka QR scan karein',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(int n, Color color, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.65)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          title: Text(text,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.ink)),
          trailing: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text('$n',
                style: TextStyle(color: color, fontWeight: FontWeight.w900)),
          ),
        ),
      ),
    );
  }
}
