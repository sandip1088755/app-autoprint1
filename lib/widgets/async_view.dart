import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme.dart';

typedef AsyncBuilder<T> = Widget Function(
    BuildContext context, T data, Future<void> Function() reload);

class AsyncView<T> extends StatefulWidget {
  final Future<T> Function() loader;
  final AsyncBuilder<T> builder;
  final bool Function(T data)? isEmpty;
  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptySubtitle;

  const AsyncView({
    super.key,
    required this.loader,
    required this.builder,
    this.isEmpty,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyTitle = 'Kuch nahi mila',
    this.emptySubtitle,
  });

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  T? _data;
  Object? _error;
  bool _loading = true;
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final gen = ++_gen;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await widget.loader().timeout(const Duration(seconds: 15));
      if (!mounted || gen != _gen) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || gen != _gen) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  String _errorText() {
    if (_error is TimeoutException) {
      return 'Server ne time par jawab nahi diya. Internet check karke dobara try karein.';
    }
    return _error.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return RefreshIndicator(
        onRefresh: reload,
        child: ListView(
          padding: const EdgeInsets.all(28),
          children: [
            const SizedBox(height: 60),
            Icon(Icons.error_outline,
                size: 56, color: AppColors.bad.withValues(alpha: 0.85)),
            const SizedBox(height: 14),
            const Text('Data load nahi hua',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            Text(_errorText(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.ink2, fontSize: 13)),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => reload(),
              icon: const Icon(Icons.refresh),
              label: const Text('Dobara try karein'),
            ),
          ],
        ),
      );
    }

    final data = _data as T;
    if (widget.isEmpty != null && widget.isEmpty!(data)) {
      return RefreshIndicator(
        onRefresh: reload,
        child: ListView(
          padding: const EdgeInsets.all(28),
          children: [
            const SizedBox(height: 80),
            Icon(widget.emptyIcon,
                size: 60, color: AppColors.brand.withValues(alpha: 0.6)),
            const SizedBox(height: 14),
            Text(widget.emptyTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            if (widget.emptySubtitle != null) ...[
              const SizedBox(height: 6),
              Text(widget.emptySubtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.ink2)),
            ],
          ],
        ),
      );
    }

    return widget.builder(context, data, reload);
  }
}
