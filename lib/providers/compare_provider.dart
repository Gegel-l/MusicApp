import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/product.dart';

class CompareProvider extends ChangeNotifier {
  static const String _storageKey = 'compare_products';
  final List<Product> _compareList = [];

  List<Product> get products => List.unmodifiable(_compareList);
  int get count => _compareList.length;
  bool get canCompare => _compareList.length >= 2;

  bool isInCompare(int productId) =>
      _compareList.any((p) => p.id == productId);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null) {
      final List decoded = jsonDecode(data);
      _compareList.clear();
      for (final item in decoded) {
        _compareList.add(Product.fromMap(Map<String, dynamic>.from(item)));
      }
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_compareList.map((p) => p.toMap()).toList());
    await prefs.setString(_storageKey, data);
  }

  Future<void> add(Product product) async {
    if (_compareList.length >= 4) return;
    if (isInCompare(product.id)) return;
    _compareList.add(product);
    await _save();
    notifyListeners();
  }

  Future<void> remove(int productId) async {
    _compareList.removeWhere((p) => p.id == productId);
    await _save();
    notifyListeners();
  }

  Future<void> clear() async {
    _compareList.clear();
    await _save();
    notifyListeners();
  }

  Future<void> clearForLogout() async {
    _compareList.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }
}
