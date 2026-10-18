import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalOrder {
  final String jobId;
  final String shopName;
  final String fileName;
  final int amount;
  final int pages;
  final int copies;
  final String createdAt;
  String? utr;

  LocalOrder({
    required this.jobId,
    required this.shopName,
    required this.fileName,
    required this.amount,
    required this.pages,
    required this.copies,
    required this.createdAt,
    this.utr,
  });

  Map<String, dynamic> toJson() => {
        'jobId': jobId,
        'shopName': shopName,
        'fileName': fileName,
        'amount': amount,
        'pages': pages,
        'copies': copies,
        'createdAt': createdAt,
        'utr': utr,
      };

  factory LocalOrder.fromJson(Map<String, dynamic> j) => LocalOrder(
        jobId: j['jobId'].toString(),
        shopName: j['shopName']?.toString() ?? '',
        fileName: j['fileName']?.toString() ?? 'document',
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        pages: (j['pages'] as num?)?.toInt() ?? 0,
        copies: (j['copies'] as num?)?.toInt() ?? 1,
        createdAt: j['createdAt']?.toString() ?? '',
        utr: j['utr']?.toString(),
      );
}

class LocalStore {
  static const _ordersKey = 'orders_v1';
  static const _nameKey = 'profile_name';
  static const _phoneKey = 'profile_phone';
  static const prefAlerts = 'pref_order_alerts';

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static Future<List<LocalOrder>> orders() async {
    final p = await _prefs;
    final raw = p.getStringList(_ordersKey) ?? <String>[];
    return raw
        .map((s) => LocalOrder.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> _saveOrders(List<LocalOrder> list) async {
    final p = await _prefs;
    await p.setStringList(
        _ordersKey, list.map((o) => jsonEncode(o.toJson())).toList());
  }

  static Future<void> addOrder(LocalOrder order) async {
    final list = await orders();
    list.removeWhere((o) => o.jobId == order.jobId);
    list.insert(0, order);
    await _saveOrders(list);
  }

  static Future<void> setUtr(String jobId, String utr) async {
    final list = await orders();
    for (final o in list) {
      if (o.jobId == jobId) o.utr = utr;
    }
    await _saveOrders(list);
  }

  static Future<void> removeOrder(String jobId) async {
    final list = await orders();
    list.removeWhere((o) => o.jobId == jobId);
    await _saveOrders(list);
  }

  static Future<String> getName() async =>
      (await _prefs).getString(_nameKey) ?? '';

  static Future<String> getPhone() async =>
      (await _prefs).getString(_phoneKey) ?? '';

  static Future<void> saveProfile(String name, String phone) async {
    final p = await _prefs;
    await p.setString(_nameKey, name);
    await p.setString(_phoneKey, phone);
  }

  static Future<bool> getBool(String key, {bool fallback = true}) async =>
      (await _prefs).getBool(key) ?? fallback;

  static Future<void> setBool(String key, bool value) async =>
      (await _prefs).setBool(key, value);

  static Future<void> clearAll() async {
    final p = await _prefs;
    await p.clear();
  }
}
