import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/compare_provider.dart';
import '../utils/routes.dart';
import 'product_detail_entry.dart';
import 'cached_image.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  int _imageIndex = 0;
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final scheme = Theme.of(context).colorScheme;
    final cart = context.watch<CartProvider>();
    final favs = context.watch<FavoritesProvider>();
    final compare = context.watch<CompareProvider>();
    final qtyTotal = cart.totalQuantityForProduct(product.id);
    final inCart = qtyTotal > 0;
    final isFav = favs.contains(product.id);
    final inCompare = compare.isInCompare(product.id);
    final quantity = qtyTotal;

    return GestureDetector(
      onTap: () => Navigator.push(
          context, heroRoute(ProductDetailScreenEntry(product: product))),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with swipe
            SizedBox(
              height: 130,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: product.images.length,
                    onPageChanged: (i) => setState(() => _imageIndex = i),
                    itemBuilder: (_, i) {
                      final img = CachedImage(
                        imageUrl: product.images[i],
                        fit: BoxFit.cover,
                        borderRadius: 0,
                      );
                      return i == 0
                          ? Hero(tag: 'product-img-${product.id}', child: img)
                          : img;
                    },
                  ),
                  if (product.tag.isNotEmpty)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(6)),
                        child: Text(product.tag, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  Positioned(
                    top: 4, right: 4,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => context.read<FavoritesProvider>().toggle(product),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.black54 : Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : Colors.grey, size: 15),
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            if (inCompare) {
                              context.read<CompareProvider>().remove(product.id);
                            } else {
                              context.read<CompareProvider>().add(product);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.black54 : Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.compare_arrows,
                                color: inCompare ? scheme.primary : Colors.grey, size: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Dots indicator
                  if (product.images.length > 1)
                    Positioned(
                      bottom: 6, left: 0, right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(product.images.length, (i) =>
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: _imageIndex == i ? 14 : 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: _imageIndex == i ? Colors.white : Colors.white54,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text('${product.rating}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, height: 1.25),
                    ),
                    const Spacer(),
                    Text(product.price,
                        style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 5),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: inCart
                          ? Container(
                              key: const ValueKey('counter'),
                              height: 28,
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () =>
                                          context.read<CartProvider>().decrementBestEffortProduct(product.id),
                                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                      child: Center(child: Icon(Icons.remove_rounded, color: scheme.primary, size: 16)),
                                    ),
                                  ),
                                  Container(width: 1, height: 16, color: scheme.primary.withValues(alpha: 0.2)),
                                  Expanded(
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 200),
                                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                      child: Text('$quantity',
                                          key: ValueKey(quantity),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: scheme.primary)),
                                    ),
                                  ),
                                  Container(width: 1, height: 16, color: scheme.primary.withValues(alpha: 0.2)),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => context.read<CartProvider>().add(product),
                                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                      child: Center(child: Icon(Icons.add_rounded, color: scheme.primary, size: 16)),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SizedBox(
                              key: const ValueKey('add'),
                              width: double.infinity,
                              height: 28,
                              child: ElevatedButton(
                                onPressed: () => context.read<CartProvider>().add(product),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: scheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('В корзину', style: TextStyle(fontSize: 11)),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
