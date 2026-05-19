import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductsProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  List<Product> _products = [];
  bool _loading = true;
  String? _error;

  List<Product> get products => _products;
  bool get loading => _loading;
  String? get error => _error;

  ProductsProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final snapshot = await _db.collection('products').orderBy('id').get();
      _products = snapshot.docs.map((d) => Product.fromMap(d.data())).toList();
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    await _load();
  }
}
