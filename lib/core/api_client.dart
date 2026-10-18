import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'config.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class UploadResult {
  final String jobId;
  final int pageCount;
  final int effectivePages;
  final int copies;
  final int amount; // paise mein
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
}

class ApiClient {
  final http.Client _http = http.Client();

  Map<String, dynamic> _decode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Server se galat response aaya');
    }
  }

  Future<int> calculatePrice({
    required String shopId,
    required int pageCount,
    required int copies,
    required String paperSize,
    required String printMode,
    required bool duplex,
  }) async {
    final res = await _http
        .post(
          Uri.parse('${AppConfig.baseUrl}/api/calculate-price.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'shop_id': shopId,
            'page_count': pageCount,
            'copies': copies,
            'paper_size': paperSize,
            'print_mode': printMode,
            'duplex': duplex,
          }),
        )
        .timeout(AppConfig.requestTimeout);

    final data = _decode(res.body);
    if (res.statusCode != 200) {
      throw ApiException(data['error']?.toString() ?? 'Price calculate nahi hua');
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
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.baseUrl}/api/upload.php'),
    )
      ..fields['shop_id'] = shopId
      ..fields['paper_size'] = paperSize
      ..fields['print_mode'] = printMode
      ..fields['copies'] = copies.toString()
      ..fields['duplex'] = duplex ? '1' : '0'
      ..fields['payment_method'] = 'upi_direct'
      ..files.add(await http.MultipartFile.fromPath('document', file.path));

    final streamed = await req.send().timeout(const Duration(seconds: 90));
    final res = await http.Response.fromStream(streamed);
    final data = _decode(res.body);

    if (res.statusCode != 200) {
      throw ApiException(data['error']?.toString() ?? 'Upload fail hua');
    }

    return UploadResult(
      jobId: data['job_id'].toString(),
      pageCount: (data['page_count'] as num).toInt(),
      effectivePages: (data['effective_pages'] as num).toInt(),
      copies: (data['copies'] as num).toInt(),
      amount: (data['amount'] as num).toInt(),
      shopName: data['shop_name']?.toString() ?? '',
      upiId: data['upi_id']?.toString() ?? '',
    );
  }

  Future<void> submitUtr({required String jobId, required String utr}) async {
    final res = await _http
        .post(
          Uri.parse('${AppConfig.baseUrl}/api/submit-utr.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'job_id': jobId, 'utr': utr}),
        )
        .timeout(AppConfig.requestTimeout);

    final data = _decode(res.body);
    if (res.statusCode != 200) {
      throw ApiException(data['error']?.toString() ?? 'Payment confirm nahi hua');
    }
  }

  void dispose() => _http.close();
}
