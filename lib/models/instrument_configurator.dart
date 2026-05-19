import 'dart:ui' show Color;

/// Стандартизация текста до id варианта (цвет без явного id в Firebase).
String configuratorLabelSlug(String s) {
  final trimmed = s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  return trimmed.replaceAll(RegExp(r'[^a-z0-9_-]'), '');
}

/// Вариант отделки (цвет) для конфигуратора товара.
class ProductColorOption {
  final String id;
  final String label;
  final String? hex;

  const ProductColorOption({
    required this.id,
    required this.label,
    this.hex,
  });

  Color? resolveColor() {
    final raw = hex;
    if (raw == null || raw.isEmpty) return null;
    var s = raw.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) {
      final v = int.tryParse(s, radix: 16);
      if (v == null) return null;
      return Color(0xFF000000 | v);
    }
    if (s.length == 8) {
      final v = int.tryParse(s, radix: 16);
      if (v == null) return null;
      return Color(v);
    }
    return null;
  }

  factory ProductColorOption.fromFirestore(dynamic raw) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final id = (map['id'] ?? map['label'] ?? 'opt').toString();
      final label = (map['label'] ?? id).toString();
      final hexVal = map['hex']?.toString();
      return ProductColorOption(id: id, label: label, hex: hexVal);
    }
    if (raw is String && raw.trim().isNotEmpty) {
      final label = raw.trim();
      final id = configuratorLabelSlug(label);
      final safeId =
          id.isEmpty ? label.hashCode.abs().toString() : id;
      return ProductColorOption(id: safeId, label: label);
    }
    return ProductColorOption(id: 'x_${raw.hashCode}', label: raw.toString());
  }

  Map<String, dynamic> toFirestoreMap() =>
      {'id': id, 'label': label, if (hex != null) 'hex': hex};
}

/// Аксессуар конфигуратора с добавкой к цене за единицу.
class ProductAccessoryOption {
  final String id;
  final String label;
  final double priceAddon;

  const ProductAccessoryOption({
    required this.id,
    required this.label,
    this.priceAddon = 0,
  });

  factory ProductAccessoryOption.fromFirestore(dynamic raw) {
    final map = Map<String, dynamic>.from(raw as Map);
    final id = (map['id'] ?? map['label'] ?? 'acc').toString();
    final label = (map['label'] ?? id).toString();
    final add = (map['priceAddon'] as num?)?.toDouble() ?? 0;
    return ProductAccessoryOption(id: id, label: label, priceAddon: add);
  }

  Map<String, dynamic> toFirestoreMap() => {
        'id': id,
        'label': label,
        'priceAddon': priceAddon,
      };
}

/// Снимок конфигурации пользователя для корзины / заказа.
class InstrumentConfiguration {
  final String? colorId;
  final List<String> accessoryIds;

  const InstrumentConfiguration({
    this.colorId,
    this.accessoryIds = const [],
  });

  static const InstrumentConfiguration empty = InstrumentConfiguration();

  List<String> get _sortedAccessoryIds => [...accessoryIds]..sort();

  factory InstrumentConfiguration.fromMap(Map<String, dynamic>? map) {
    if (map == null) return InstrumentConfiguration.empty;
    final ids = map['accessoryIds'];
    return InstrumentConfiguration(
      colorId: map['colorId'] as String?,
      accessoryIds:
          ids == null ? const [] : List<String>.from(ids as Iterable<dynamic>),
    );
  }

  Map<String, dynamic> toMap() => {
        if (colorId != null && colorId!.isNotEmpty) 'colorId': colorId,
        if (_sortedAccessoryIds.isNotEmpty)
          'accessoryIds': _sortedAccessoryIds,
      };

  /// Для ключей строки корзины (без символов, запрещённых в Firebase doc ids).
  int get fingerprint {
    final acc = Object.hashAll(_sortedAccessoryIds);
    return Object.hash(colorId ?? '', acc).abs();
  }

  bool get hasAnySelection =>
      (colorId != null && colorId!.isNotEmpty) || accessoryIds.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstrumentConfiguration &&
          colorId == other.colorId &&
          _listEq(_sortedAccessoryIds, other._sortedAccessoryIds);

  @override
  int get hashCode => Object.hash(colorId, Object.hashAll(_sortedAccessoryIds));
}

/// Сумма надбавок за выбранные аксессуары по актуальной карточке товара в каталоге.
double configurationAccessoryTotal(
    InstrumentConfiguration configuration,
    Iterable<ProductAccessoryOption> options,) {
  if (configuration.accessoryIds.isEmpty) return 0;
  var sum = 0.0;
  for (final o in options) {
    if (configuration.accessoryIds.contains(o.id)) sum += o.priceAddon;
  }
  return sum;
}

bool _listEq(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
