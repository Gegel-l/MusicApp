import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/instrument_configurator.dart';
import '../utils/recently_viewed_service.dart';
import '../providers/cart_provider.dart';
import '../providers/instrument_configurator_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/compare_provider.dart';
import '../widgets/product_image_gallery.dart';
import '../widgets/product_info_section.dart';
import '../widgets/product_configurator_section.dart';
import '../widgets/product_video_section.dart';
import '../widgets/product_audio_section.dart';
import '../widgets/product_reviews_section.dart';
import '../widgets/similar_products_section.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    RecentlyViewedService.add(widget.product.id);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final scheme = Theme.of(context).colorScheme;
    final cart = context.watch<CartProvider>();
    final cfgState = context.watch<InstrumentConfiguratorProvider>();
    final configuration = cfgState.configuration();
    final lineId = CartItem.computeLineKey(product.id, configuration);
    final quantity = cart.quantityForLine(lineId);
    final inCart = quantity > 0;
    final favs = context.watch<FavoritesProvider>();
    final isFav = favs.contains(product.id);
    final compare = context.watch<CompareProvider>();
    final inCompare = compare.isInCompare(product.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Image Gallery
          ProductImageGallery(
            product: product,
            isFavorite: isFav,
            onFavoriteToggle: () => favs.toggle(product),
          ),

          // Product Info
          ProductInfoSection(
            product: product,
            configuratorSection: product.hasConfigurator
                ? ProductConfiguratorSection(product: product)
                : null,
            videoSection: product.videoUrl != null
                ? ProductVideoSection(videoUrl: product.videoUrl!)
                : null,
            audioSection: product.audioUrl != null
                ? ProductAudioSection(audioUrl: product.audioUrl!)
                : null,
            reviewsSection: ProductReviewsSection(productId: product.id),
            similarProductsSection: SimilarProductsSection(product: product),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (inCompare) {
                    compare.remove(product.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Удалено из сравнения'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  } else {
                    compare.add(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Добавлено к сравнению'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: inCompare ? scheme.primary : scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.compare_arrows,
                    color: inCompare ? Colors.white : scheme.primary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: inCart
                      ? CartCounter(
                          key: const ValueKey('counter'),
                          quantity: quantity,
                          scheme: scheme,
                          lineId: lineId,
                          product: product,
                          configuration: configuration,
                        )
                      : SizedBox(
                          key: const ValueKey('add'),
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              if (product.hasConfigurator &&
                                  product.effectiveConfiguratorColors.isNotEmpty &&
                                  cfgState.selectedColorId == null) {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Выберите цвет/отделку'),
                                    content: const Text(
                                      'Пожалуйста, выберите цвет или отделку в конфигураторе перед добавлением в корзину.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Понятно'),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }
                              context
                                  .read<CartProvider>()
                                  .add(product, configuration);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: scheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'В корзину',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CartCounter extends StatelessWidget {
  final int quantity;
  final ColorScheme scheme;
  final String lineId;
  final Product product;
  final InstrumentConfiguration configuration;

  const CartCounter({
    super.key,
    required this.quantity,
    required this.scheme,
    required this.lineId,
    required this.product,
    required this.configuration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => context.read<CartProvider>().decrement(lineId),
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(12)),
              child: Center(
                child: Icon(
                  Icons.remove_rounded,
                  color: scheme.primary,
                  size: 26,
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: scheme.primary.withValues(alpha: 0.2),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Text(
                '$quantity',
                key: ValueKey(quantity),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: scheme.primary.withValues(alpha: 0.2),
          ),
          Expanded(
            child: InkWell(
              onTap: () =>
                  context.read<CartProvider>().add(product, configuration),
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(12)),
              child: Center(
                child: Icon(
                  Icons.add_rounded,
                  color: scheme.primary,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
