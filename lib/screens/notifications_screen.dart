import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/order_loader.dart';
import '../core/orders.dart';
import '../core/theme.dart';
import '../widgets/animations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiClient _api = ApiClient();
  List<({String title, String at, String shop})> _items = [];
  bool _loading = true;
  bool _alertsOn = true;

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
    setState(() => _loading = true);
    final alertsOn = await LocalStore.getBool(LocalStore.prefAlerts);
    final views = await loadOrderViews(_api);

    final items = <({String title, String at, String shop})>[];
    for (final v in views) {
      final s = v.status;
      if (s == null) continue;
      for (final e in s.events) {
        items.add((title: e.title, at: e.at, shop: v.order.shopName));
      }
    }
    items.sort((a, b) => b.at.compareTo(a.at));

    if (!mounted) return;
    setState(() {
      _alertsOn = alertsOn;
      _items = items;
      _loading = false;
    });
  }

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
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && _items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : !_alertsOn
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: const [
                      SizedBox(height: 80),
                      Icon(Icons.notifications_off_outlined,
                          size: 60, color: AppColors.brand),
                      SizedBox(height: 12),
                      Text('Order updates band hain. Settings mein on karein.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  )
                : _items.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 140),
                          Center(
                            child: Text('Abhi koi notification nahi hai',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final n = _items[i];
                          return FadeSlideIn(
                            index: i,
                            child: Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.brandSoft,
                                  child: Icon(_iconFor(n.title), color: AppColors.brand),
                                ),
                                title: Text(n.title,
                                    style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text('${n.shop} · ${shortTime(n.at)}',
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.ink2)),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
