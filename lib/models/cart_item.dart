import 'instrument_configurator.dart';
import 'product.dart';

class CartItem {
  final Product product;
  final InstrumentConfiguration configuration;
  int quantity;
  bool isSelected;

  /// Ключ строки корзины: совместим со старыми документами `productId`,
  /// а при наличии опций — `productId_fingerprint`.
  late final String lineId;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.isSelected = true,
    InstrumentConfiguration? configuration,
    /// Ид документа в Firestore; если передан при загрузке, совпадает с ключом карты корзины.
    String? lineIdOverride,
  }) : configuration = configuration ?? InstrumentConfiguration.empty {
    lineId = lineIdOverride ?? computeLineKey(product.id, this.configuration);
  }

  double get unitAmount =>
      product.amount +
      configurationAccessoryTotal(configuration, product.effectiveConfiguratorAccessories);

  /// Краткая подпись к строке корзины (по сохранённому снимку товара в корзине).
  String configurationLabel() {
    if (!configuration.hasAnySelection) return '';
    final parts = <String>[];
    final cid = configuration.colorId;
    if (cid != null && cid.isNotEmpty) {
      for (final c in product.effectiveConfiguratorColors) {
        if (c.id == cid) {
          parts.add(c.label);
          break;
        }
      }
      if (!product.effectiveConfiguratorColors.any((c) => c.id == cid)) {
        parts.add(cid);
      }
    }
    for (final aid in [...configuration.accessoryIds]..sort()) {
      var found = false;
      for (final a in product.effectiveConfiguratorAccessories) {
        if (a.id == aid) {
          parts.add(a.label);
          found = true;
          break;
        }
      }
      if (!found) parts.add(aid);
    }
    return parts.join(' · ');
  }

  static String computeLineKey(int productId, InstrumentConfiguration configuration) {
    if (!configuration.hasAnySelection) {
      return '$productId';
    }
    return '${productId}_${configuration.fingerprint}';
  }

  CartItem copyWith({
    Product? product,
    int? quantity,
    bool? isSelected,
    InstrumentConfiguration? configuration,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      isSelected: isSelected ?? this.isSelected,
      configuration: configuration ?? this.configuration,
    );
  }
}
