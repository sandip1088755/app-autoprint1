import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/theme.dart';

typedef ScanResult = ({String type, String value});

enum _CamState { checking, granted, denied, blocked }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  _CamState _state = _CamState.checking;
  MobileScannerController? _controller;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _checkCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _checkCamera() async {
    final s = await Permission.camera.status;
    _apply(s);
  }

  Future<void> _askCamera() async {
    final s = await Permission.camera.request();
    _apply(s);
  }

  void _apply(PermissionStatus s) {
    if (!mounted) return;
    setState(() {
      if (s.isGranted) {
        _state = _CamState.granted;
        _controller ??= MobileScannerController();
      } else if (s.isPermanentlyDenied) {
        _state = _CamState.blocked;
      } else {
        _state = _CamState.denied;
      }
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done || capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;
    final result = _extract(raw);
    if (result == null) return;
    _done = true;
    Navigator.pop(context, result);
  }

  ScanResult? _extract(String raw) {
    var value = raw.trim();
    if (!value.contains('://') && value.contains('.')) {
      value = 'https://$value';
    }
    final uri = Uri.tryParse(value);
    if (uri == null) return null;

    final shopId = uri.queryParameters['shop_id'];
    if (shopId != null && shopId.isNotEmpty) {
      return (type: 'id', value: shopId);
    }

    final qSlug = uri.queryParameters['slug'];
    if (qSlug != null && qSlug.isNotEmpty) {
      return (type: 'slug', value: qSlug);
    }

    final segs = uri.pathSegments;
    final i = segs.indexOf('s');
    if (i >= 0 && i + 1 < segs.length && segs[i + 1].isNotEmpty) {
      return (type: 'slug', value: segs[i + 1]);
    }

    if (RegExp(r'^\d+$').hasMatch(value)) {
      return (type: 'id', value: value);
    }
    return null;
  }

  Widget _permissionView() {
    final blocked = _state == _CamState.blocked;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, color: Colors.white, size: 64),
            const SizedBox(height: 16),
            Text(
              blocked
                  ? 'Camera permission band hai. Settings mein jaake camera allow karein.'
                  : 'QR scan ke liye camera permission chahiye.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => blocked ? openAppSettings() : _askCamera(),
              child: Text(blocked ? 'Settings kholein' : 'Permission do'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller!,
          onDetect: _onDetect,
        ),
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.brand, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Text(
            'Shop ka QR frame mein rakhein',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final granted = _state == _CamState.granted && _controller != null;
    Widget body;
    if (_state == _CamState.checking) {
      body = const Center(child: CircularProgressIndicator());
    } else if (granted) {
      body = _scanner();
    } else {
      body = _permissionView();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('QR scan karein'),
        actions: [
          if (granted)
            IconButton(
              icon: const Icon(Icons.flash_on),
              onPressed: () => _controller?.toggleTorch(),
            ),
        ],
      ),
      body: body,
    );
  }
}
