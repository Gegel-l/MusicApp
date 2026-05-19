import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification.dart';
import '../models/product.dart';
import '../utils/local_notifications_service.dart';

class NotificationsProvider extends ChangeNotifier {
  static const _storagePrefix = 'app_notifications_';

  String? _uid;
  List<AppNotification> _items = [];

  List<AppNotification> get items => _items;
  int get unreadCount => _items.where((n) => !n.read).length;

  String get _storageKey => '$_storagePrefix${_uid ?? 'guest'}';

  Future<void> loadForUser(String uid) async {
    _uid = uid;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _items = [];
      notifyListeners();
      return;
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    _items = decoded
        .map((e) => AppNotification.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    _dedupeAndSort();
    notifyListeners();
  }

  void clearForLogout() {
    _uid = null;
    _items = [];
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(_items.map((e) => e.toMap()).toList());
    await prefs.setString(_storageKey, payload);
  }

  Future<void> addOrderNotification({
    required int itemCount,
    required String totalAmount,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    _items.insert(
      0,
      AppNotification(
        id: 'order_$now',
        type: 'order',
        title: 'Заказ оформлен',
        message: 'Оформлен заказ на $itemCount шт. на сумму $totalAmount',
        createdAt: now,
      ),
    );
    await LocalNotificationsService.show(
      id: now.remainder(1 << 31),
      title: 'Заказ оформлен',
      body: 'Оформлен заказ на $itemCount шт. на сумму $totalAmount',
    );
    await _save();
    notifyListeners();
  }

  Future<void> syncFromProducts(List<Product> products) async {
    var changed = false;
    final byId = <String>{for (final n in _items) n.id};

    for (final product in products) {
      if (_isDiscount(product)) {
        final id = 'discount_${product.id}';
        if (!byId.contains(id)) {
          final title = 'Скидка на товар';
          final body = '${product.name}: сейчас ${product.price}';
          _items.insert(
            0,
            AppNotification(
              id: id,
              type: 'discount',
              title: title,
              message: body,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              productId: product.id,
            ),
          );
          await LocalNotificationsService.show(
            id: _stableId(id),
            title: title,
            body: body,
          );
          byId.add(id);
          changed = true;
        }
      }

      final stock = _extractStock(product);
      if (stock != null && stock <= 3) {
        final id = 'stock_${product.id}';
        if (!byId.contains(id)) {
          final title = 'Заканчивается товар';
          final body = '${product.name}: осталось $stock шт.';
          _items.insert(
            0,
            AppNotification(
              id: id,
              type: 'stock',
              title: title,
              message: body,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              productId: product.id,
            ),
          );
          await LocalNotificationsService.show(
            id: _stableId(id),
            title: title,
            body: body,
          );
          byId.add(id);
          changed = true;
        }
      }
    }

    if (changed) {
      _dedupeAndSort();
      await _save();
      notifyListeners();
    }
  }

  bool _isDiscount(Product product) {
    final tag = product.tag.toLowerCase();
    return tag.contains('скид');
  }

  int? _extractStock(Product product) {
    for (final entry in product.specs.entries) {
      final key = entry.key.toLowerCase();
      if (!key.contains('налич') && !key.contains('остат')) continue;
      final numMatch = RegExp(r'\d+').firstMatch(entry.value);
      if (numMatch == null) continue;
      return int.tryParse(numMatch.group(0)!);
    }
    return null;
  }

  void notify() => notifyListeners();

  Future<void> markAllRead({bool silent = false}) async {
    _items = _items.map((n) => n.copyWith(read: true)).toList();
    if (!silent) notifyListeners();
    await _save();
  }

  Future<void> markRead(String id, {bool silent = false}) async {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx == -1 || _items[idx].read) return;
    _items[idx] = _items[idx].copyWith(read: true);
    if (!silent) notifyListeners();
    await _save();
  }

  Future<void> remove(String id, {bool silent = false}) async {
    final before = _items.length;
    _items.removeWhere((n) => n.id == id);
    if (_items.length == before) return;
    if (!silent) notifyListeners();
    await _save();
  }

  Future<void> clearAll({bool silent = false}) async {
    _items = [];
    if (!silent) notifyListeners();
    await LocalNotificationsService.cancelAll();
    await _save();
  }

  int _stableId(String value) => value.hashCode & 0x7fffffff;

  void _dedupeAndSort() {
    final unique = <String, AppNotification>{};
    for (final n in _items) {
      final existing = unique[n.id];
      if (existing == null || n.createdAt > existing.createdAt) {
        unique[n.id] = n;
      }
    }
    _items = unique.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
