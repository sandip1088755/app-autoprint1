import 'dart:async';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../widgets/animations.dart';
import 'print_screen.dart';

class ShopSearchScreen extends StatefulWidget {
  const ShopSearchScreen({super.key});

  @override
  State<ShopSearchScreen> createState() => _ShopSearchScreenState();
}

class _ShopSearchScreenState extends State<ShopSearchScreen> {
  final ApiClient _api = ApiClient();
  final TextEditingController _ctrl = TextEditingController();
  Timer? _debounce;
  List<Shop> _shops = [];
  bool _loading = false;
  String? _error;
  String _lastQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _api.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _search(String value) async {
    final q = value.trim();
    if (q.length < 2) {
      setState(() {
        _shops = [];
        _error = null;
        _loading = false;
        _lastQuery = '';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _lastQuery = q;
    });
    try {
      final list = await _api.searchShops(query: q);
      if (!mounted || q != _lastQuery) return;
      setState(() => _shops = list);
    } catch (e) {
      if (!mounted || q != _lastQuery) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted && q == _lastQuery) setState(() => _loading = false);
    }
  }

  void _clear() {
    _ctrl.clear();
    _search('');
  }

  void _openShop(Shop s) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PrintScreen(shopId: s.id, shopName: s.name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop dhundhein')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Shop ka naam ya city likhein',
                prefixIcon: const Icon(Icons.search, color: AppColors.brand),
                suffixIcon: _ctrl.text.isEmpty
                    ? null
                    : IconButton(icon: const Icon(Icons.clear), onPressed: _clear),
              ),
            ),
          ),
          if (_loading)
            const LinearProgressIndicator(minHeight: 3, color: AppColors.brand),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_error != null) {
      return _message(Icons.wifi_off, 'Server se connect nahi hua', _error!);
    }
    if (_lastQuery.isEmpty) {
      return _message(Icons.storefront_outlined, 'Shop ka naam likhein',
          'Kam se kam 2 letters likhein');
    }
    if (!_loading && _shops.isEmpty) {
      return _message(Icons.search_off, 'Koi shop nahi mili',
          'Spelling check karein ya city likhkar dekhein');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _shops.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => FadeSlideIn(index: i, child: _shopCard(_shops[i])),
    );
  }

  Widget _message(IconData icon, String title, String sub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.brand.withValues(alpha: 0.5)),
            const SizedBox(height: 14),
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 6),
            Text(sub,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.ink2)),
          ],
        ),
      ),
    );
  }

  Widget _shopCard(Shop s) {
    final initial = s.name.isEmpty ? '?' : s.name[0].toUpperCase();
    final hasHours = s.openTime.length >= 5 && s.closeTime.length >= 5;
    final hours = hasHours
        ? '${s.openTime.substring(0, 5)} - ${s.closeTime.substring(0, 5)}'
        : '';
    final place = [s.city, s.address].where((e) => e.isNotEmpty).join(' · ');

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openShop(s),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brand, Color(0xFFDB2777)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(initial,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.ink)),
                    if (place.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(place,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.ink2, fontSize: 12.5)),
                    ],
                    if (hours.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 14, color: AppColors.ok),
                          const SizedBox(width: 4),
                          Text(hours,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ok)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.ink2),
            ],
          ),
        ),
      ),
    );
  }
}
