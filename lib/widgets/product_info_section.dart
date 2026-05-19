import 'package:flutter/material.dart';
import '../models/product.dart';
import '../screens/catalog_screen.dart';

const _categoryMeta = {
  'Клавишные': {'icon': Icons.piano, 'color': Color(0xFF7C4DFF)},
  'Струнные': {'icon': Icons.queue_music, 'color': Color(0xFF00BCD4)},
  'Духовые': {'icon': Icons.music_note, 'color': Color(0xFFFF7043)},
  'Ударные': {'icon': Icons.speaker, 'color': Color(0xFF43A047)},
  'Электронные': {'icon': Icons.electrical_services, 'color': Color(0xFFE91E63)},
  'Аксессуары': {'icon': Icons.build_outlined, 'color': Color(0xFF795548)},
};

/// Основная информация о товаре
class ProductInfoSection extends StatelessWidget {
  final Product product;
  final Widget? configuratorSection;
  final Widget? videoSection;
  final Widget? audioSection;
  final Widget? reviewsSection;
  final Widget? similarProductsSection;

  const ProductInfoSection({
    super.key,
    required this.product,
    this.configuratorSection,
    this.videoSection,
    this.audioSection,
    this.reviewsSection,
    this.similarProductsSection,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and rating
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          product.rating.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    CategoryChip(category: product.category),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Price
            Text(
              product.price,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),

            const SizedBox(height: 16),

            // Description
            const Text(
              'Описание',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              product.description,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),

            // Configurator
            if (configuratorSection != null) ...[
              const SizedBox(height: 20),
              configuratorSection!,
            ],

            // Video
            if (videoSection != null) ...[
              const SizedBox(height: 20),
              videoSection!,
            ],

            // Audio
            if (audioSection != null) ...[
              const SizedBox(height: 20),
              audioSection!,
            ],

            const SizedBox(height: 20),

            // Specifications
            const Text(
              'Характеристики',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: product.specs.entries
                    .toList()
                    .asMap()
                    .entries
                    .map((entry) {
                  final isLast = entry.key == product.specs.length - 1;
                  final spec = entry.value;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                spec.key,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: Text(
                                spec.value,
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast) const Divider(height: 1, indent: 16),
                    ],
                  );
                }).toList(),
              ),
            ),

            // Reviews
            if (reviewsSection != null) ...[
              const SizedBox(height: 20),
              reviewsSection!,
            ],

            // Similar products
            if (similarProductsSection != null) ...[
              const SizedBox(height: 20),
              similarProductsSection!,
            ],

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

/// Category chip widget
class CategoryChip extends StatelessWidget {
  final String category;
  const CategoryChip({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final meta = _categoryMeta[category];
    final color = (meta?['color'] as Color?) ??
        Theme.of(context).colorScheme.primary;
    final icon = (meta?['icon'] as IconData?) ?? Icons.category_outlined;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CatalogScreen(initialCategory: category),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              category,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
