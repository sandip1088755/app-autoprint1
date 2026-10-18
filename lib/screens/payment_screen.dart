import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_client.dart';
import '../core/orders.dart';
import '../core/theme.dart';
import '../widgets/app_widgets.dart';

class PaymentScreen extends StatefulWidget {
  final UploadResult order;
  final String fileName;
  const PaymentScreen({super.key, required this.order, required this.fileName});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final ApiClient _api = ApiClient();
  final _utrCtrl = TextEditingController();
  bool _submitting = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    final o = widget.order;
    LocalStore.addOrder(LocalOrder(
      jobId: o.jobId,
      shopName: o.shopName,
      fileName: widget.fileName,
      amount: o.amount,
      pages: o.effectivePages,
      copies: o.copies,
      createdAt: DateTime.now().toIso8601String(),
    ));
  }

  @override
  void dispose() {
    _api.dispose();
    _utrCtrl.dispose();
    super.dispose();
  }

  String get _amountText => '₹${(widget.order.amount / 100).toStringAsFixed(2)}';

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openUpi() async {
    final o = widget.order;
    final uri = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': o.upiId,
        'pn': o.shopName,
        'am': (o.amount / 100).toStringAsFixed(2),
        'cu': 'INR',
        'tn': 'AutoPrint Order',
        'tr': o.jobId,
      },
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      _snack('Koi UPI app nahi mili. Apna UPI app kholkar pay karein.');
    }
  }

  Future<void> _confirm() async {
    final utr = _utrCtrl.text.trim();
    if (!RegExp(r'^[0-9]{12}$').hasMatch(utr)) {
      _snack('UTR 12 digit ka hona chahiye');
      return;
    }
    setState(() => _submitting = true);
    try {
      await _api.submitUtr(jobId: widget.order.jobId, utr: utr);
      await LocalStore.setUtr(widget.order.jobId, utr);
      if (!mounted) return;
      setState(() => _done = true);
    } catch (e) {
      if (mounted) _snack(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;

    if (_done) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: AppColors.ok, size: 88),
                const SizedBox(height: 20),
                const Text('UTR bhej diya gaya',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Order ID: ${o.jobId}',
                    style: const TextStyle(color: AppColors.ink2)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                  child: const Text('Home par jayein'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          GradientHeader(
            title: _amountText,
            subtitle: '${o.shopName} | ${o.effectivePages} pages x ${o.copies} copies',
          ),
          SectionCard(
            title: '1. UPI app se pay karein',
            child: ElevatedButton.icon(
              onPressed: o.upiId.isEmpty ? null : _openUpi,
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: Text(o.upiId.isEmpty ? 'UPI abhi available nahi' : 'UPI app kholein'),
            ),
          ),
          SectionCard(
            title: '2. Payment ke baad UTR daalein',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'UPI app ki payment history mein 12 digit ka UTR number milega.',
                  style: TextStyle(color: AppColors.ink2, fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _utrCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  decoration: const InputDecoration(
                    labelText: 'UTR number',
                    prefixIcon: Icon(Icons.receipt_long_outlined),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _submitting ? null : _confirm,
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Payment confirm karein'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
