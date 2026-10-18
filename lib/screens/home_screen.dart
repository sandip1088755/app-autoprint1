import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../widgets/animations.dart';
import 'print_screen.dart';
import 'scan_screen.dart';
import 'shop_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiClient _api = ApiClient();

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _openPrint(String id, String? name) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PrintScreen(shopId: id, shopName: name)),
    );
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ShopSearchScreen()),
    );
  }

  Future<void> _scan() async {
    final res = await Navigator.push<({String type, String value})>(
      context,
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (res == null || !mounted) return;

    if (res.type == 'id') {
      _openPrint(res.value, null);
      return;
    }

    try {
      final shops = await _api.searchShops(slug: res.value);
      if (!mounted) return;
      if (shops.isEmpty) {
        _snack('Ye QR kisi active shop se match nahi karta');
        return;
      }
      _openPrint(shops.first.id, shops.first.name);
    } catch (e) {
      if (mounted) _snack(e.toString());
    }
  }

  static const _steps = [
    (Color(0xFF6366F1), Icons.qr_code_2, 'Shop chunein (QR ya naam se)'),
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
          const SizedBox(height: 20),
          FadeSlideIn(
            index: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _actionButton(
                colors: const [Color(0xFF4F46E5), Color(0xFFDB2777)],
                icon: Icons.qr_code_scanner,
                label: 'Shop ka QR scan karein',
                onTap: _scan,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            index: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _actionButton(
                colors: const [Color(0xFF0EA5E9), Color(0xFF4F46E5)],
                icon: Icons.search,
                label: 'Shop ka naam se dhundhein',
                onTap: _openSearch,
              ),
            ),
          ),
          FadeSlideIn(
            index: 3,
            child: const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 6),
              child: Text('Kaise kaam karta hai',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.ink)),
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

  Widget _actionButton({
    required List<Color> colors,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          height: 58,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
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
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
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
