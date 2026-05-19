import 'package:flutter/material.dart';

import '../models/instrument_configurator.dart';
import '../models/product.dart';

/// Состояние конфигуратора на экране товара: выбранный цвет и аксессуары.
///
/// Связано с экраном через [ChangeNotifierProvider] во [widgets/product_detail_entry.dart].
class InstrumentConfiguratorProvider extends ChangeNotifier {
  InstrumentConfiguratorProvider(this._product);

  final Product _product;

  Product get product => _product;

  String? _selectedColorId;
  final Set<String> _selectedAccessoryIds = {};

  String? get selectedColorId => _selectedColorId;

  Set<String> get selectedAccessoryIds =>
      Set<String>.unmodifiable(_selectedAccessoryIds);

  void selectColor(String? colorId) {
    if (_selectedColorId == colorId) return;
    _selectedColorId = colorId;
    notifyListeners();
  }

  void toggleAccessory(String id) {
    if (_selectedAccessoryIds.contains(id)) {
      _selectedAccessoryIds.remove(id);
    } else {
      _selectedAccessoryIds.add(id);
    }
    notifyListeners();
  }

  InstrumentConfiguration configuration() {
    return InstrumentConfiguration(
      colorId: _selectedColorId,
      accessoryIds: _selectedAccessoryIds.toList(),
    );
  }

  double get accessoriesDelta {
    double sum = 0;
    for (final opt in product.effectiveConfiguratorAccessories) {
      if (_selectedAccessoryIds.contains(opt.id)) sum += opt.priceAddon;
    }
    return sum;
  }

  double get previewUnitTotal => product.amount + accessoriesDelta;
}
