import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../widgets/app_widgets.dart';
import 'payment_screen.dart';

class PrintScreen extends StatefulWidget {
  final String shopId;
  final String? shopName;
  const PrintScreen({super.key, required this.shopId, this.shopName});

  @override
  State<PrintScreen> createState() => _PrintScreenState();
}

class _PrintScreenState extends State<PrintScreen> {
  final ApiClient _api = ApiClient();

  PlatformFile? _file;
  int _pages = 1;
  int _copies = 1;
  String _paper = 'A4';
  String _mode = 'BW';
  bool _duplex = false;

  int? _amountPaise;
  bool _priceLoading = false;
  bool _uploading = false;
  String? _priceError;

  @override
  void initState() {
    super.initState();
    _refreshPrice();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (res == null || res.files.isEmpty) return;
    setState(() => _file = res.files.first);
  }

  Future<void> _refreshPrice() async {
    setState(() {
      _priceLoading = true;
      _priceError = null;
    });
    try {
      final amount = await _api.calculatePrice(
        shopId: widget.shopId,
        pageCount: _pages,
        copies: _copies,
        paperSize: _paper,
        printMode: _mode,
        duplex: _duplex,
      );
      if (!mounted) return;
      setState(() => _amountPaise = amount);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _amountPaise = null;
        _priceError = e.toString();
      });
    } finally {
      if (mounted) setState(() => _priceLoading = false);
    }
  }

  void _update(VoidCallback change) {
    setState(change);
    _refreshPrice();
  }

  Future<void> _uploadAndPay() async {
    final path = _file?.path;
    if (path == null) return;

    setState(() => _uploading = true);
    try {
      final result = await _api.uploadDocument(
        file: File(path),
        shopId: widget.shopId,
        paperSize: _paper,
        printMode: _mode,
        copies: _copies,
        duplex: _duplex,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PaymentScreen(order: result, fileName: _file?.name ?? 'document', shopId: widget.shopId)),
      );
    } catch (e) {
      if (mounted) _snack(e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatAmount(int paise) => '₹${(paise / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.shopName ?? 'Print karein')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SizedBox(height: 8),
          SectionCard(title: '1. File chunein', child: _filePicker()),
          SectionCard(
            title: '2. Pages',
            child: Row(
              children: [
                const Expanded(
                  child: Text('Total pages', style: TextStyle(color: AppColors.ink2)),
                ),
                CounterField(
                  value: _pages,
                  max: 5000,
                  onChanged: (v) => _update(() => _pages = v),
                ),
              ],
            ),
          ),
          SectionCard(
            title: '3. Paper size',
            child: OptionChips<String>(
              options: const ['A4', 'A5', 'Letter', 'Legal'],
              selected: _paper,
              labelOf: (s) => s,
              onChanged: (v) => _update(() => _paper = v),
            ),
          ),
          SectionCard(
            title: '4. Print type',
            child: Column(
              children: [
                OptionChips<String>(
                  options: const ['BW', 'COLOR'],
                  selected: _mode,
                  labelOf: (s) => s == 'BW' ? 'Black & White' : 'Color',
                  onChanged: (v) => _update(() => _mode = v),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Double side (duplex)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  value: _duplex,
                  activeColor: AppColors.brand,
                  onChanged: (v) => _update(() => _duplex = v),
                ),
              ],
            ),
          ),
          SectionCard(
            title: '5. Copies',
            child: Row(
              children: [
                const Expanded(
                  child: Text('Kitni copies', style: TextStyle(color: AppColors.ink2)),
                ),
                CounterField(
                  value: _copies,
                  max: 500,
                  onChanged: (v) => _update(() => _copies = v),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _summaryBar(),
    );
  }

  Widget _filePicker() {
    final file = _file;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: file == null ? AppColors.brandSoft : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: file == null ? AppColors.brand.withValues(alpha: 0.3) : AppColors.ok,
          ),
        ),
        child: Row(
          children: [
            Icon(
              file == null ? Icons.upload_file : Icons.check_circle,
              color: file == null ? AppColors.brand : AppColors.ok,
              size: 30,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                file == null ? 'PDF, JPG ya PNG chunein (max 8 MB)' : file.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.ink2),
          ],
        ),
      ),
    );
  }

  Widget _summaryBar() {
    final busy = _priceLoading || _uploading;
    final canContinue = _file != null && _amountPaise != null && !busy;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total', style: TextStyle(color: AppColors.ink2, fontSize: 12)),
                  if (_priceLoading)
                    const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (_priceError != null)
                    Text(_priceError!,
                        style: const TextStyle(color: AppColors.bad, fontSize: 12))
                  else
                    Text(
                      _amountPaise == null ? '--' : _formatAmount(_amountPaise!),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.brand),
                    ),
                ],
              ),
            ),
            SizedBox(
              width: 160,
              child: ElevatedButton(
                onPressed: canContinue ? _uploadAndPay : null,
                child: _uploading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Aage badhein'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
