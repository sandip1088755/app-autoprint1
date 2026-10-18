import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/orders.dart';
import '../core/theme.dart';
import '../widgets/animations.dart';

class MyFilesScreen extends StatefulWidget {
  const MyFilesScreen({super.key});

  @override
  State<MyFilesScreen> createState() => _MyFilesScreenState();
}

class _MyFilesScreenState extends State<MyFilesScreen> {
  List<LocalOrder> _files = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await LocalStore.orders();
    if (!mounted) return;
    setState(() {
      _files = list;
      _loaded = true;
    });
  }

  Future<void> _remove(LocalOrder o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ye file hatayein?'),
        content: const Text(
            'Ye sirf is phone ki list se hatega. Shop ka order is se nahi badlega.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hatayein')),
        ],
      ),
    );
    if (ok != true) return;
    await LocalStore.removeOrder(o.jobId);
    _load();
  }

  IconData _iconFor(String name) =>
      name.toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf : Icons.image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Files')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? const Center(
                  child: Text('Abhi koi file upload nahi hui',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _files.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => FadeSlideIn(index: i, child: _tile(_files[i])),
                ),
    );
  }

  Widget _tile(LocalOrder o) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.brand, Color(0xFF0EA5E9)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(_iconFor(o.fileName), color: Colors.white),
        ),
        title: Text(o.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${o.shopName} · ${o.pages} pages · ${shortTime(o.createdAt)}',
          style: const TextStyle(fontSize: 12, color: AppColors.ink2),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.bad),
          onPressed: () => _remove(o),
        ),
      ),
    );
  }
}
