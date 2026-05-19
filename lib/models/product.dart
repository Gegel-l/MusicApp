import 'instrument_configurator.dart';
import '../utils/instrument_configurator_presets.dart';

class Product {
  final int id;
  final String name;
  final String price;
  final double amount;
  final List<String> images;
  final String tag;
  final String category;
  final String description;
  final double rating;
  final Map<String, String> specs;
  final String? audioUrl;
  final String? videoUrl;
  final List<ProductColorOption> configuratorColors;
  final List<ProductAccessoryOption> configuratorAccessories;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.amount,
    required this.images,
    required this.tag,
    required this.category,
    required this.description,
    required this.rating,
    required this.specs,
    this.audioUrl,
    this.videoUrl,
    this.configuratorColors = const [],
    this.configuratorAccessories = const [],
  });

  /// Категории, где на карточке показываем конфигуратор даже без данных в Firebase.
  static const Set<String> kInstrumentCategoriesWithDefaultConfigurator = {
    'Клавишные',
    'Струнные',
    'Духовые',
    'Ударные',
    'Электронные',
  };

  List<ProductColorOption> get effectiveConfiguratorColors =>
      InstrumentConfiguratorPresets.colorsFor(this);

  List<ProductAccessoryOption> get effectiveConfiguratorAccessories =>
      InstrumentConfiguratorPresets.accessoriesFor(this);

  /// Показать блок «Конфигуратор»: свои значения из Firestore или умолчания по категории.
  bool get hasConfigurator =>
      effectiveConfiguratorColors.isNotEmpty ||
      effectiveConfiguratorAccessories.isNotEmpty;

  static List<ProductColorOption> _colorsFromMap(dynamic v) {
    if (v == null) return const [];
    if (v is! List) return const [];
    return v.map(ProductColorOption.fromFirestore).toList();
  }

  static List<ProductAccessoryOption> _accessoriesFromMap(dynamic v) {
    if (v == null) return const [];
    if (v is! List) return const [];
    return v
        .map((e) {
          try {
            return ProductAccessoryOption.fromFirestore(e);
          } catch (_) {
            return null;
          }
        })
        .whereType<ProductAccessoryOption>()
        .toList();
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int,
      name: map['name'] as String,
      price: map['price'] as String,
      amount: (map['amount'] as num).toDouble(),
      images: List<String>.from(map['images']),
      tag: map['tag'] as String,
      category: map['category'] as String,
      description: map['description'] as String,
      rating: (map['rating'] as num).toDouble(),
      specs: Map<String, String>.from(map['specs']),
      audioUrl: map['audioUrl'] as String?,
      videoUrl: map['videoUrl'] as String?,
      configuratorColors: _colorsFromMap(map['configuratorColors']),
      configuratorAccessories: _accessoriesFromMap(map['configuratorAccessories']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'price': price,
        'amount': amount,
        'images': images,
        'tag': tag,
        'category': category,
        'description': description,
        'rating': rating,
        'specs': specs,
        if (audioUrl != null) 'audioUrl': audioUrl,
        if (videoUrl != null) 'videoUrl': videoUrl,
        if (configuratorColors.isNotEmpty)
          'configuratorColors':
              configuratorColors.map((c) => c.toFirestoreMap()).toList(),
        if (configuratorAccessories.isNotEmpty)
          'configuratorAccessories':
              configuratorAccessories.map((a) => a.toFirestoreMap()).toList(),
      };
}
