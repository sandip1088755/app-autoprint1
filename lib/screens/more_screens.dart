import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_client.dart';
import '../core/config.dart';
import '../core/order_loader.dart';
import '../core/orders.dart';
import '../core/theme.dart';
import '../widgets/animations.dart';

class PaymentOptionsScreen extends StatefulWidget {
  const PaymentOptionsScreen({super.key});

  @override
  State<PaymentOptionsScreen> createState() => _PaymentOptionsScreenState();
}

class _PaymentOptionsScreenState extends State<PaymentOptionsScreen> {
  final ApiClient _api = ApiClient();
  List<OrderView> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final views = await loadOrderViews(_api);
    if (!mounted) return;
    setState(() {
      _items = views;
      _loading = false;
    });
  }

  Widget _method(IconData icon, String title, String desc, bool active) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.brand),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(desc),
        trailing: Text(active ? 'Active' : 'Shop par',
            style: TextStyle(
                color: active ? AppColors.ok : AppColors.ink2,
                fontWeight: FontWeight.w700,
                fontSize: 12)),
      ),
    );
  }

  Widget _history() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Abhi koi payment nahi hui', style: TextStyle(fontWeight: FontWeight.w700)),
      );
    }
    return Column(
      children: [
        for (final v in _items)
          Card(
            child: ListTile(
              title: Text('₹${(v.order.amount / 100).toStringAsFixed(2)} · ${v.order.shopName}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                  'UTR: ${v.order.utr ?? 'abhi nahi daala'}  ·  ${v.status?.label ?? '-'}'),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Options')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Payment ke tarike',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          _method(Icons.account_balance_wallet_outlined, 'UPI',
              'Shop ke UPI se pay karein, phir 12 digit UTR daalein.', true),
          _method(Icons.credit_card, 'Online payment (Razorpay)',
              'Sirf wahi shop jo ise enable kare, uske liye dikhega.', false),
          const SizedBox(height: 20),
          const Text('Payment history',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          _history(),
        ],
      ),
    );
  }
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    ('Payment ho gaya par print nahi hua?',
        'Order ID ke saath support par message karein. Payment verify hone ke baad print queue mein jaata hai.'),
    ('UTR kahan milega?',
        'UPI app ki payment history ya transaction details mein 12 digit ka UTR number hota hai.'),
    ('Shop ka QR kaise scan karein?',
        'Home par "Shop ka QR scan karein" tap karein aur shop ka QR frame mein rakhein.'),
    ('Kaunsi files upload ho sakti hain?',
        'PDF, JPG, JPEG aur PNG. Maximum size 8 MB.'),
    ('Order cancel kar sakte hain?',
        'Print shuru hone se pehle support se sampark karein.'),
  ];

  Future<void> _open(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      messenger.showSnackBar(const SnackBar(content: Text('Ye option abhi khul nahi raha')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final whatsapp = Uri.parse(
        'https://wa.me/${AppConfig.supportWhatsapp}?text=${Uri.encodeComponent('AutoPrint support chahiye')}');
    final call = Uri(scheme: 'tel', path: AppConfig.supportPhone);

    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
                  title: const Text('WhatsApp support',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () => _open(context, whatsapp),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.call, color: AppColors.brand),
                  title: const Text('Call support',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () => _open(context, call),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('FAQ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          ..._faqs.map(
            (f) => Card(
              child: ExpansionTile(
                title: Text(f.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(f.$2)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _alerts = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await LocalStore.getBool(LocalStore.prefAlerts);
    if (!mounted) return;
    setState(() => _alerts = v);
  }

  Future<void> _confirmClear() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sab local data mitayein?'),
        content: const Text('Orders ki list aur profile is phone se hat jayenge.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mitayein')),
        ],
      ),
    );
    if (ok != true) return;
    await LocalStore.clearAll();
    messenger.showSnackBar(const SnackBar(content: Text('Local data mita diya gaya')));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              activeColor: AppColors.brand,
              title: const Text('Order updates ki notifications',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Notifications screen par order ke updates dikhayein'),
              value: _alerts,
              onChanged: (v) async {
                setState(() => _alerts = v);
                await LocalStore.setBool(LocalStore.prefAlerts, v);
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_sweep_outlined, color: AppColors.bad),
              title: const Text('Sab local data mitayein',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Orders aur profile is phone se hat jayenge'),
              onTap: _confirmClear,
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text('AutoPrint v1.0.0', style: TextStyle(color: AppColors.ink2)),
          ),
        ],
      ),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const _sections = [
    ('Aap ka data kya hai',
        'Naam aur mobile number (aap profile mein dalein), upload ki gayi file, print settings, aur payment ka UTR number.'),
    ('File ka use',
        'Aapki file sirf chune gaye shop ko print karne ke liye bheji jaati hai. Ye kisi public link par store nahi hoti.'),
    ('Phone mein kya save hota hai',
        'Aapke orders ki list aur profile is phone mein save rehti hai. Settings se ise mita sakte hain.'),
    ('File kitne din rahegi',
        'Print ke baad file server par kitne din rakhi jayegi, ye hamari retention policy par depend karta hai. Exact muddat support se poochh sakte hain.'),
    ('Payment',
        'Payment aapke UPI app par hota hai. App aapka UPI PIN ya bank details nahi leti.'),
    ('Sawal',
        'Privacy se jude sawal ke liye Help & Support se sampark karein.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final s in _sections)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.$1,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.ink)),
                    const SizedBox(height: 6),
                    Text(s.$2, style: const TextStyle(color: AppColors.ink2, height: 1.5)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
