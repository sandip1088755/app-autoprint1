import 'package:flutter/material.dart';
import '../core/order_loader.dart';
import '../core/orders.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../widgets/animations.dart';
import '../widgets/async_view.dart';

typedef NotifItem = ({String title, String at, String shop});

class NotifData {
  final bool alertsOn;
  final List<NotifItem> items;
  const NotifData(this.alertsOn, this.items);
}

Future<NotifData> _loadNotifs() async {
  final on = await LocalStore.getBool(LocalStore.prefAlerts);
  final views = await fetchOrderViews();
  final items = <NotifItem>[];
  for (final v in views) {
    final s = v.status;
    if (s == null) continue;
    for (final e in s.events) {
      items.add((title: e.title, at: e.at, shop: v.order.shopName));
    }
  }
  items.sort((a, b) => b.at.compareTo(a.at));
  return NotifData(on, items);
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(String title) {
    if (title.contains('fail')) return Icons.error_outline;
    if (title.contains('complete')) return Icons.check_circle_outline;
    if (title.contains('Payment')) return Icons.payments_outlined;
    if (title.contains('queue')) return Icons.schedule;
    return Icons.print_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: AsyncView<NotifData>(
        loader: _loadNotifs,
        isEmpty: (d) => d.alertsOn && d.items.isEmpty,
        emptyIcon: Icons.notifications_none,
        emptyTitle: 'Abhi koi notification nahi hai',
        emptySubtitle: 'Order karne ke baad updates yahan dikhenge',
        builder: (context, data, reload) {
          if (!data.alertsOn) {
            return RefreshIndicator(
              onRefresh: reload,
              child: ListView(
                padding: const EdgeInsets.all(28),
                children: const [
                  SizedBox(height: 80),
                  Icon(Icons.notifications_off_outlined, size: 60, color: AppColors.brand),
                  SizedBox(height: 12),
                  Text('Order updates band hain. Settings mein on karein.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: data.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final n = data.items[i];
                return FadeSlideIn(
                  index: i,
                  child: Card(
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.brandSoft,
                        child: Icon(_iconFor(n.title), color: AppColors.brand),
                      ),
                      title: Text(n.title,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${n.shop} · ${shortTime(n.at)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.ink2)),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
