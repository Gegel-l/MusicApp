import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class FavoritesProvider extends ChangeNotifier {
  final Set<int> _ids = {};
  String? _uid;

  DocumentReference? get _doc => _uid == null
      ? null
      : FirebaseFirestore.instance.collection('users').doc(_uid);

  bool contains(int id) => _ids.contains(id);
  int get count => _ids.length;

  List<Product> favorites(List<Product> all) =>
      all.where((p) => _ids.contains(p.id)).toList();

  Future<void> loadForUser(String uid) async {
    _uid = uid;
    _ids.clear();
    final snap = await _doc!.get();
    final data = snap.data() as Map<String, dynamic>?;
    if (data != null && data['favorites'] is List) {
      for (final id in data['favorites']) {
        _ids.add(id as int);
      }
    }
    notifyListeners();
  }

  void clearForLogout() {
    _uid = null;
    _ids.clear();
    notifyListeners();
  }

  Future<void> _save() async {
    await _doc?.set({'favorites': _ids.toList()}, SetOptions(merge: true));
  }

  void toggle(Product product) {
    if (_ids.contains(product.id)) {
      _ids.remove(product.id);
    } else {
      _ids.add(product.id);
    }
    _save();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _ids.clear();
    await _save();
    notifyListeners();
  }
}
