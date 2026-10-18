import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/order_loader.dart';
import '../core/theme.dart';
import '../widgets/animations.dart';

Future<void> showReviewSheet(
    BuildContext context, ApiClient api, String jobId, String shopName) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ReviewSheet(api: api, jobId: jobId, shopName: shopName),
  );
}

class _ReviewSheet extends StatefulWidget {
  final ApiClient api;
  final String jobId;
  final String shopName;
  const _ReviewSheet({required this.api, required this.jobId, required this.shopName});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _rating = 5;
  final _title = TextEditingController();
  final _comment = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => _sending = true);
    try {
      await widget.api.submitReview(
        jobId: widget.jobId,
        rating: _rating,
        title: _title.text.trim(),
        comment: _comment.text.trim(),
      );
      nav.pop();
      messenger.showSnackBar(
          const SnackBar(content: Text('Review submit ho gaya. Shukriya!')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.shopName} ko rate karein',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => IconButton(
                onPressed: () => setState(() => _rating = i + 1),
                icon: Icon(
                  i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 36,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title (optional)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _comment,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Aapka feedback'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _sending ? null : _submit,
            child: _sending
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
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
    setState(() => _loading = true);
    final views = await loadOrderViews(_api);
    if (!mounted) return;
    setState(() {
      _items = views.where((v) => v.status?.isCompleted ?? false).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rating & Review')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Review tabhi de sakte hain jab order complete ho jaye.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final o = _items[i].order;
                    return FadeSlideIn(
                      index: i,
                      child: Card(
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          leading: const Icon(Icons.star_rounded, color: Colors.amber, size: 32),
                          title: Text(o.shopName,
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text(o.fileName,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: FilledButton(
                            onPressed: () =>
                                showReviewSheet(context, _api, o.jobId, o.shopName),
                            child: const Text('Review'),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
