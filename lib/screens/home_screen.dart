import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/app_widgets.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const GradientHeader(
            title: 'AutoPrint',
            subtitle: 'QR scan karo, file upload karo, print lo',
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _scan,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Shop ka QR scan karein'),
            ),
          ),
          SectionCard(
            title: 'Ya shop ID daalein',
            child: Column(
              children: [
                TextField(
                  controller: _shopCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Shop ID',
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _openShop(_shopCtrl.text),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Shop kholein',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('Kaise kaam karta hai',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          _step(1, 'Shop ka QR scan karein', Icons.qr_code_2),
          _step(2, 'PDF ya photo upload karein', Icons.upload_file),
          _step(3, 'Pages aur copies chunein', Icons.tune),
          _step(4, 'UPI se pay karein', Icons.payments_outlined),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _step(int n, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.brandSoft,
            child: Icon(icon, color: AppColors.brand),
          ),
          title: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: Text('$n',
              style: const TextStyle(color: AppColors.ink2, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}
