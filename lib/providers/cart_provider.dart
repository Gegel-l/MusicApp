import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item.dart';
import '../models/instrument_configurator.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  String? _uid;

  CollectionReference? get _col => _uid == null
      ? null
      : FirebaseFirestore.instance.collection('users').doc(_uid).collection('cart');

  List<CartItem> get items => _items.values.toList();
  int get totalCount => _items.values.fold(0, (acc, i) => acc + i.quantity);
  List<CartItem> get selectedItems => _items.values.where((i) => i.isSelected).toList();
  bool get allSelected => _items.isNotEmpty && _items.values.every((i) => i.isSelected);
  double get totalAmount =>
      selectedItems.fold(0.0, (acc, i) => acc + i.unitAmount * i.quantity);
  int get selectedCount => selectedItems.fold(0, (acc, i) => acc + i.quantity);

  String get totalAmountFormatted {
    final formatted = totalAmount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]} ',
    );
    return '$formatted ₽';
  }

  Future<void> loadForUser(String uid) async {
    _uid = uid;
    _items.clear();
    final snap =
        await FirebaseFirestore.instance.collection('users').doc(uid).collection('cart').get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final product = Product.fromMap(data['product'] as Map<String, dynamic>);
      final cfgMap = data['configuration'] as Map<String, dynamic>?;
      final configuration = InstrumentConfiguration.fromMap(cfgMap);
      final item = CartItem(
        product: product,
        quantity: data['quantity'] as int,
        configuration: configuration,
        lineIdOverride: doc.id.isNotEmpty ? doc.id : null,
      );
      _items[item.lineId] = item;
    }
    notifyListeners();
  }

  void clearForLogout() {
    _uid = null;
    _items.clear();
    notifyListeners();
  }

  Future<void> _save(String lineId) async {
    final col = _col;
    if (col == null) return;
    final item = _items[lineId];
    if (item == null) {
      await col.doc(lineId).delete();
    } else {
      await col.doc(lineId).set({
        'product': item.product.toMap(),
        'quantity': item.quantity,
        'configuration': item.configuration.toMap(),
      });
    }
  }

  CartItem? _findExistingLine(Product product, InstrumentConfiguration configuration) {
    final key = CartItem.computeLineKey(product.id, configuration);
    return _items[key];
  }

  void add(Product product, [InstrumentConfiguration? configuration]) {
    final cfg = configuration ?? InstrumentConfiguration.empty;
    final existing = _findExistingLine(product, cfg);
    if (existing != null) {
      final key = CartItem.computeLineKey(product.id, cfg);
      _items[key]!.quantity++;
    } else {
      final item = CartItem(product: product, configuration: cfg);
      _items[item.lineId] = item;
    }
    _save(CartItem.computeLineKey(product.id, cfg));
    notifyListeners();
  }

  void decrement(String lineId) {
    final item = _items[lineId];
    if (item == null) return;
    if (item.quantity <= 1) {
      _items.remove(lineId);
      _save(lineId);
      notifyListeners();
      return;
    }
    item.quantity--;
    _save(lineId);
    notifyListeners();
  }

  /// С карточек каталога: уменьшает любую имеющуюся строку с этим товаром (первая по стабильному ключу).
  void decrementBestEffortProduct(int productId) {
    final keys = _items.keys.where((k) => _items[k]!.product.id == productId).toList()
      ..sort();
    if (keys.isEmpty) return;
    decrement(keys.first);
  }

  void remove(String lineId) {
    _items.remove(lineId);
    _save(lineId);
    notifyListeners();
  }

  void toggleSelect(String lineId) {
    final item = _items[lineId];
    if (item == null) return;
    item.isSelected = !item.isSelected;
    notifyListeners();
  }

  void selectAll(bool value) {
    for (final item in _items.values) {
      item.isSelected = value;
    }
    notifyListeners();
  }

  void buySelected() {
    final list = selectedItems;
    final lineIds = list.map((i) => i.lineId).toList();
    for (final lid in lineIds) {
      _items.remove(lid);
      _save(lid);
    }
    _saveOrder(list);
    notifyListeners();
  }

  Future<void> _saveOrder(List<CartItem> items) async {
    if (_uid == null || items.isEmpty) return;
    final total = items.fold(0.0, (acc, i) => acc + i.unitAmount * i.quantity);
    final formatted = total.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ');
    await FirebaseFirestore.instance
        .collection('users').doc(_uid).collection('orders').add({
      'date': DateTime.now().millisecondsSinceEpoch,
      'total': total,
      'totalFormatted': '$formatted ₽',
      'itemCount': items.fold(0, (acc, i) => acc + i.quantity),
      'items': items.map((i) => {
            'productId': i.product.id,
            'name': i.product.name,
            'price': i.product.price,
            'unitAmount': i.unitAmount,
            'quantity': i.quantity,
            'image': i.product.images.first,
            if (i.configuration.hasAnySelection) 'configuration': i.configuration.toMap(),
          }).toList(),
    });
  }

  void clear() {
    final keys = _items.keys.toList();
    _items.clear();
    for (final id in keys) {
      _save(id);
    }
    notifyListeners();
  }

  bool contains(int productId) => _items.values.any((i) => i.product.id == productId);

  int totalQuantityForProduct(int productId) =>
      _items.values.where((i) => i.product.id == productId).fold(0, (a, i) => a + i.quantity);

  int quantityForLine(String lineId) => _items[lineId]?.quantity ?? 0;
}
