import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/order_loader.dart';
import '../core/theme.dart';
import '../widgets/animations.dart';
import '../widgets/async_view.dart';
import 'rating_screen.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  Widget _card(BuildContext context, OrderView v) {
    final s = v.status;
    final label = s?.label ?? 'Status load nahi hua';
    final done = s?.isCompleted ?? false;
    final failed = s?.isFailed ?? false;
    final color = failed ? AppColors.bad : (done ? AppColors.ok : AppColors.brand);
    final amount = (v.order.amount / 100).toStringAsFixed(2);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(v.order.shopName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(label,
                      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(v.order.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.ink2)),
            const SizedBox(height: 4),
            Text('${v.order.pages} pages x ${v.order.copies} copies  ·  ₹$amount',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 2),
            Text('Order ID: ${v.order.jobId}',
                style: const TextStyle(fontSize: 11, color: AppColors.ink2)),
            if (done)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () =>
                      showReviewSheet(context, v.order.jobId, v.order.shopName),
                  icon: const Icon(Icons.star_rounded, color: Colors.amber),
                  label: const Text('Rate karein'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: AsyncView<List<OrderView>>(
        loader: fetchOrderViews,
        isEmpty: (l) => l.isEmpty,
        emptyIcon: Icons.receipt_long_outlined,
        emptyTitle: 'Abhi koi order nahi hai',
        emptySubtitle: 'Shop chunein, file upload karein aur pay karein',
        builder: (context, items, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) =>
                FadeSlideIn(index: i, child: _card(context, items[i])),
          ),
        ),
      ),
    );
  }
}
