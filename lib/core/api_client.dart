import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart';
import 'config.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

String? _nz(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

String shortTime(String? t) {
  if (t == null || t.isEmpty) return '';
  final clean = t.replaceFirst('T', ' ');
  return clean.length >= 16 ? clean.substring(0, 16) : clean;
}

class Shop {
  final String id;
  final String name;
  final String slug;
  final String city;
  final String address;
  final String openTime;
  final String closeTime;

  Shop({
    required this.id,
    required this.name,
    required this.slug,
    required this.city,
    required this.address,
    required this.openTime,
    required this.closeTime,
  });

  factory Shop.fromJson(Map<String, dynamic> j) => Shop(
        id: j['id'].toString(),
        name: j['shop_name']?.toString() ?? '',
        slug: j['slug']?.toString() ?? '',
        city: j['city']?.toString() ?? '',
        address: j['address']?.toString() ?? '',
        openTime: j['open_time']?.toString() ?? '',
        closeTime: j['close_time']?.toString() ?? '',
      );
}

class UploadResult {
  final String jobId;
  final int pageCount;
  final int effectivePages;
  final int copies;
  final int amount;
  final String shopName;
  final String upiId;

  UploadResult({
    required this.jobId,
    required this.pageCount,
    required this.effectivePages,
    required this.copies,
    required this.amount,
    required this.shopName,
    required this.upiId,
  });

  factory UploadResult.fromJson(Map<String, dynamic> j) => UploadResult(
        jobId: j['job_id'].toString(),
        pageCount: (j['page_count'] as num?)?.toInt() ?? 0,
        effectivePages: (j['effective_pages'] as num?)?.toInt() ?? 0,
        copies: (j['copies'] as num?)?.toInt() ?? 1,
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        shopName: j['shop_name']?.toString() ?? '',
        upiId: j['upi_id']?.toString() ?? '',
      );
}

class JobStatus {
  final String id;
  final String paymentStatus;
  final String? printStatus;
  final int amount;
  final int pageCount;
  final String? paidAt;
  final String? queuedAt;
  final String? printingAt;
  final String? completedAt;
  final String? failedAt;
  final String? errorMessage;

  JobStatus({
    required this.id,
    required this.paymentStatus,
    required this.printStatus,
    required this.amount,
    required this.pageCount,
    required this.paidAt,
    required this.queuedAt,
    required this.printingAt,
    required this.completedAt,
    required this.failedAt,
    required this.errorMessage,
  });

  factory JobStatus.fromJson(Map<String, dynamic> j) => JobStatus(
        id: j['id'].toString(),
        paymentStatus: _nz(j['payment_status']) ?? '',
        printStatus: _nz(j['print_status']),
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        pageCount: (j['page_count'] as num?)?.toInt() ?? 0,
        paidAt: _nz(j['paid_at']),
        queuedAt: _nz(j['queued_at']),
        printingAt: _nz(j['printing_at']),
        completedAt: _nz(j['completed_at']),
        failedAt: _nz(j['failed_at']),
        errorMessage: _nz(j['error_message']),
      );

  bool get isCompleted => completedAt != null;
  bool get isFailed => failedAt != null;
  bool get isPaid => paidAt != null || paymentStatus == 'PAID';

  String get label {
    if (isFailed) return 'Print fail hua';
    if (isCompleted) return 'Print complete';
    if (printingAt != null) return 'Print ho raha hai';
    if (queuedAt != null) return 'Shop ki queue mein';
    if (isPaid) return 'Payment mil gaya';
    return 'Payment pending';
  }

  List<({String title, String at})> get events {
    final list = <({String title, String at})>[];
    void add(String? at, String title) {
      if (at != null) list.add((title: title, at: at));
    }

    add(paidAt, 'Payment mil gaya');
    add(queuedAt, 'Order shop ki queue mein gaya');
    add(printingAt, 'Print shuru hua');
    add(completedAt, 'Print complete, pickup ke liye tayyar');
    add(failedAt, 'Print fail hua');
    return list;
  }
}

class ApiClient {
  final http.Client _http = http.Client();
  final Map<String, String> _cookies = {};

  Map<String, String> _headers() {
    final h = <String, String>{
      'Accept': 'application/json',
      'User-Agent': 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36',
    };
    if (_cookies.isNotEmpty) {
      h['Cookie'] = _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
    }
    return h;
  }

  // ---- Hosting anti-bot challenge (JS AES cookie) ----

  bool _isChallenge(String body) =>
      body.contains('toNumbers(') && body.contains('toHex(');

  Uint8List _hexToBytes(String hex) {
    final out = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  String _bytesToHex(Uint8List b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

  Uint8List _aesDecryptCbc(Uint8List data, Uint8List key, Uint8List iv) {
    final cipher = CBCBlockCipher(AESEngine())
      ..init(false, ParametersWithIV(KeyParameter(key), iv));
    final out = Uint8List(data.length);
    for (var off = 0; off + 16 <= data.length; off += 16) {
      cipher.processBlock(data, off, out, off);
    }
    return out;
  }

  MapEntry<String, String>? _solveChallenge(String body) {
    final parts = <String, Uint8List>{};
    final re = RegExp(r'([abc])\s*=\s*toNumbers\("([0-9a-fA-F]+)"\)');
    for (final m in re.allMatches(body)) {
      parts[m.group(1)!] = _hexToBytes(m.group(2)!);
    }
    final key = parts['a'];
    final iv = parts['b'];
    final data = parts['c'];
    if (key == null || iv == null || data == null) return null;
    final name = RegExp(r'document\.cookie\s*=\s*"([^=;"]+)=')
            .firstMatch(body)
            ?.group(1) ??
        '__test';
    return MapEntry(name, _bytesToHex(_aesDecryptCbc(data, key, iv)));
  }

  Future<http.Response> _withChallenge(
      Future<http.Response> Function(Map<String, String> headers) send) async {
    var res = await send(_headers());
    if (_isChallenge(res.body)) {
      final c = _solveChallenge(res.body);
      if (c == null) {
        throw ApiException('Hosting verification fail hua. Server ko dusre host par move karna hoga.');
      }
      _cookies[c.key] = c.value;
      res = await send(_headers());
      if (_isChallenge(res.body)) {
        throw ApiException('Hosting ne app ko block kiya hai. Server ko dusre host par move karna hoga.');
      }
    }
    return res;
  }

  Future<http.Response> _postJson(String path, Map<String, dynamic> body) {
    return _withChallenge((h) => _http
        .post(
          Uri.parse('${AppConfig.baseUrl}$path'),
          headers: {...h, 'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(AppConfig.requestTimeout));
  }

  Map<String, dynamic> _decode(http.Response res) {
    final body = res.body;
    try {
      final v = jsonDecode(body);
      if (v is Map<String, dynamic>) return v;
      throw const FormatException('not an object');
    } catch (_) {
      final text = body
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final snippet = text.length > 160 ? text.substring(0, 160) : text;
      throw ApiException(
          'Server ka jawab (HTTP ${res.statusCode}): ${snippet.isEmpty ? 'khali' : snippet}');
    }
  }

  String _errMsg(Map<String, dynamic> data, String fallback) =>
      data['error']?.toString() ?? fallback;

  // ---- Public API ----

  Future<List<Shop>> searchShops({String? query, String? slug}) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/api/shops-search.php').replace(
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (slug != null && slug.isNotEmpty) 'slug': slug,
      },
    );
    final res = await _withChallenge(
        (h) => _http.get(uri, headers: h).timeout(AppConfig.requestTimeout));
    final data = _decode(res);
    if (res.statusCode != 200) {
      throw ApiException(_errMsg(data, 'Shop search fail hua'));
    }
    final list = (data['shops'] as List?) ?? const [];
    return list.map((e) => Shop.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> calculatePrice({
    required String shopId,
    required int pageCount,
    required int copies,
    required String paperSize,
    required String printMode,
    required bool duplex,
  }) async {
    final res = await _postJson('/api/calculate-price.php', {
      'shop_id': shopId,
      'page_count': pageCount,
      'copies': copies,
      'paper_size': paperSize,
      'print_mode': printMode,
      'duplex': duplex,
    });
    final data = _decode(res);
    if (res.statusCode != 200) {
      throw ApiException(_errMsg(data, 'Price calculate nahi hua'));
    }
    return (data['amount'] as num).toInt();
  }

  Future<UploadResult> uploadDocument({
    required File file,
    required String shopId,
    required String paperSize,
    required String printMode,
    required int copies,
    required bool duplex,
  }) async {
    final res = await _withChallenge((h) async {
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}/api/upload.php'),
      )
        ..headers.addAll(h)
        ..fields.addAll({
          'shop_id': shopId,
          'paper_size': paperSize,
          'print_mode': printMode,
          'copies': copies.toString(),
          'duplex': duplex ? '1' : '0',
          'payment_method': 'upi_direct',
        })
        ..files.add(await http.MultipartFile.fromPath('document', file.path));
      final streamed = await req.send().timeout(const Duration(seconds: 90));
      return http.Response.fromStream(streamed);
    });

    final data = _decode(res);
    if (res.statusCode != 200) {
      throw ApiException(_errMsg(data, 'Upload fail hua'));
    }
    return UploadResult.fromJson(data);
  }

  Future<void> submitUtr({required String jobId, required String utr}) async {
    final res = await _postJson('/api/submit-utr.php', {'job_id': jobId, 'utr': utr});
    final data = _decode(res);
    if (res.statusCode != 200) {
      throw ApiException(_errMsg(data, 'Payment confirm nahi hua'));
    }
  }

  Future<JobStatus> getJobStatus(String jobId) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/api/job-status.php')
        .replace(queryParameters: {'id': jobId});
    final res = await _withChallenge(
        (h) => _http.get(uri, headers: h).timeout(AppConfig.requestTimeout));
    final data = _decode(res);
    if (res.statusCode != 200) {
      throw ApiException(_errMsg(data, 'Order status nahi mila'));
    }
    return JobStatus.fromJson(data);
  }

  Future<void> submitReview({
    required String jobId,
    required int rating,
    required String title,
    required String comment,
  }) async {
    final res = await _postJson('/api/submit-review.php', {
      'job_id': jobId,
      'rating': rating,
      'title': title,
      'comment': comment,
      'tags': <String>[],
    });
    final data = _decode(res);
    if (res.statusCode != 200 || data['error'] != null) {
      throw ApiException(_errMsg(data, 'Review submit nahi hua'));
    }
  }

  void dispose() => _http.close();
}
