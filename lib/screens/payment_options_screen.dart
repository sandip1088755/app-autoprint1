import 'package:flutter/material.dart';
import '../core/order_loader.dart';
import '../core/theme.dart';
import '../widgets/async_view.dart';

class PaymentOptionsScreen extends StatelessWidget {
  const PaymentOptionsScreen({super.key});

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

  List<Widget> _history(List<OrderView> items) {
    if (items.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.all(8),
          child: Text('Abhi koi payment nahi hui', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ];
    }
    return items
        .map((v) => Card(
              child: ListTile(
                title: Text(
                    '₹${(v.order.amount / 100).toStringAsFixed(2)} · ${v.order.shopName}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                    'UTR: ${v.order.utr ?? 'abhi nahi daala'}  ·  ${v.status?.label ?? '-'}'),
              ),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Options')),
      body: AsyncView<List<OrderView>>(
        loader: fetchOrderViews,
        builder: (context, items, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(
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
              ..._history(items),
            ],
          ),
        ),
      ),
    );
  }
}
