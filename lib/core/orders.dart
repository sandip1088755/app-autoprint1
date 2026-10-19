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

/// Phone storage. Agar plugin fail ho to memory mein chalta hai, app crash nahi hoti.
class LocalStore {
  static const _ordersKey = 'orders_json';
  static const _nameKey = 'profile_name';
  static const _phoneKey = 'profile_phone';
  static const prefAlerts = 'pref_order_alerts';

  static final Map<String, String> _memStr = {};
  static final Map<String, bool> _memBool = {};
  static SharedPreferences? _sp;
  static bool _spFailed = false;

  static Future<SharedPreferences?> _prefs() async {
    if (_spFailed) return null;
    if (_sp != null) return _sp;
    try {
      _sp = await SharedPreferences.getInstance();
      return _sp;
    } catch (_) {
      _spFailed = true;
      return null;
    }
  }

  static Future<String?> _getStr(String k) async {
    final p = await _prefs();
    if (p != null) {
      try {
        return p.getString(k);
      } catch (_) {
        _spFailed = true;
      }
    }
    return _memStr[k];
  }

  static Future<void> _setStr(String k, String v) async {
    _memStr[k] = v;
    final p = await _prefs();
    if (p != null) {
      try {
        await p.setString(k, v);
      } catch (_) {
        _spFailed = true;
      }
    }
  }

  static Future<bool?> _getBool(String k) async {
    final p = await _prefs();
    if (p != null) {
      try {
        return p.getBool(k);
      } catch (_) {
        _spFailed = true;
      }
    }
    return _memBool[k];
  }

  static Future<void> _setBool(String k, bool v) async {
    _memBool[k] = v;
    final p = await _prefs();
    if (p != null) {
      try {
        await p.setBool(k, v);
      } catch (_) {
        _spFailed = true;
      }
    }
  }

  static Future<List<LocalOrder>> orders() async {
    final raw = await _getStr(_ordersKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => LocalOrder.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _save(List<LocalOrder> list) =>
      _setStr(_ordersKey, jsonEncode(list.map((o) => o.toJson()).toList()));

  static Future<void> addOrder(LocalOrder order) async {
    final list = await orders();
    list.removeWhere((o) => o.jobId == order.jobId);
    list.insert(0, order);
    await _save(list);
  }

  static Future<void> setUtr(String jobId, String utr) async {
    final list = await orders();
    for (final o in list) {
      if (o.jobId == jobId) o.utr = utr;
    }
    await _save(list);
  }

  static Future<void> removeOrder(String jobId) async {
    final list = await orders();
    list.removeWhere((o) => o.jobId == jobId);
    await _save(list);
  }

  static Future<String> getName() async => (await _getStr(_nameKey)) ?? '';

  static Future<String> getPhone() async => (await _getStr(_phoneKey)) ?? '';

  static Future<void> saveProfile(String name, String phone) async {
    await _setStr(_nameKey, name);
    await _setStr(_phoneKey, phone);
  }

  static Future<bool> getBool(String key, {bool fallback = true}) async =>
      (await _getBool(key)) ?? fallback;

  static Future<void> setBool(String key, bool value) => _setBool(key, value);

  static Future<void> clearAll() async {
    _memStr.clear();
    _memBool.clear();
    final p = await _prefs();
    if (p != null) {
      try {
        await p.clear();
      } catch (_) {
        _spFailed = true;
      }
    }
  }
}
