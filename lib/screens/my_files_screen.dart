import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/orders.dart';
import '../core/theme.dart';
import '../widgets/animations.dart';
import '../widgets/async_view.dart';

class MyFilesScreen extends StatelessWidget {
  const MyFilesScreen({super.key});

  IconData _iconFor(String name) =>
      name.toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf : Icons.image;

  Future<void> _remove(
      BuildContext context, LocalOrder o, Future<void> Function() reload) async {
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
    await reload();
  }

  Widget _tile(BuildContext context, LocalOrder o, Future<void> Function() reload) {
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
          onPressed: () => _remove(context, o, reload),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Files')),
      body: AsyncView<List<LocalOrder>>(
        loader: LocalStore.orders,
        isEmpty: (l) => l.isEmpty,
        emptyIcon: Icons.folder_open,
        emptyTitle: 'Abhi koi file nahi hai',
        emptySubtitle: 'Shop chunein aur PDF ya photo upload karein',
        builder: (context, files, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: files.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) =>
                FadeSlideIn(index: i, child: _tile(context, files[i], reload)),
          ),
        ),
      ),
    );
  }
}
