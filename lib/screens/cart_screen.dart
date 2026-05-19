import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/products_provider.dart';
import '../utils/routes.dart';
import 'order_success_screen.dart';
import '../widgets/product_detail_entry.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Product _resolveProduct(BuildContext context, Product fallback) {
    final products = context.read<ProductsProvider>().products;
    for (final p in products) {
      if (p.id == fallback.id) return p;
    }
    return fallback;
  }

  String _formatAmount(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ');
    return '$formatted ₽';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cart = context.watch<CartProvider>();
    final items = cart.items;

    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Row(
                      children: [
                        const Text(
                          'Корзина',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (items.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${items.length}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (items.isNotEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_sweep_outlined,
                              color: Colors.white70,
                            ),
                            onPressed: () =>
                                context.read<CartProvider>().clear(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          items.isEmpty
              ? Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🛒', style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 12),
                        Text(
                          'Корзина пуста',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              : Expanded(
                  child: Column(
                    children: [
                      Container(
                        color: Theme.of(context).cardColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: cart.allSelected,
                              activeColor: scheme.primary,
                              onChanged: (v) =>
                                  context.read<CartProvider>().selectAll(v ?? false),
                            ),
                            const Text(
                              'Выбрать все',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            Text(
                              'Выбрано: ${cart.selectedCount}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final item = items[i];
                            final configLabel = item.configurationLabel();
                            final hasConfig = configLabel.isNotEmpty;
                            return Dismissible(
                              key: ValueKey('${item.lineId}_${item.quantity}'),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) =>
                                  context.read<CartProvider>().remove(item.lineId),
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreenEntry(
                                      product: _resolveProduct(context, item.product),
                                    ),
                                  ),
                                ),
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: SizedBox(
                                    height: 170,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // Image
                                        SizedBox(
                                          width: 110,
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Image.network(
                                                item.product.images.first,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                      color: scheme.primaryContainer,
                                                      child: Icon(
                                                        Icons.image_not_supported,
                                                        color: scheme.primary,
                                                        size: 32,
                                                      ),
                                                    ),
                                              ),
                                              Positioned(
                                                bottom: 0,
                                                left: 0,
                                                right: 0,
                                                child: Container(
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.bottomCenter,
                                                      end: Alignment.topCenter,
                                                      colors: [
                                                        Colors.black.withValues(
                                                          alpha: 0.5,
                                                        ),
                                                        Colors.transparent,
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              if (item.product.tag.isNotEmpty)
                                                Positioned(
                                                  top: 8,
                                                  left: 8,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: scheme.primary,
                                                      borderRadius:
                                                          BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      item.product.tag,
                                                      style: const TextStyle(
                                                        fontSize: 9,
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              Positioned(
                                                bottom: 2,
                                                left: 0,
                                                child: SizedBox(
                                                  width: 36,
                                                  height: 36,
                                                  child: Checkbox(
                                                    value: item.isSelected,
                                                    activeColor: scheme.primary,
                                                    side: const BorderSide(
                                                      color: Colors.white,
                                                      width: 1.5,
                                                    ),
                                                    checkColor: Colors.white,
                                                    onChanged: (_) => context
                                                        .read<CartProvider>()
                                                        .toggleSelect(item.lineId),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Info
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              10,
                                              6,
                                              8,
                                              6,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: ClipRect(
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.start,
                                                      mainAxisSize: MainAxisSize.max,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          item.product.name,
                                                          maxLines: 2,
                                                          overflow:
                                                              TextOverflow.ellipsis,
                                                          style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 13,
                                                            height: 1.22,
                                                          ),
                                                        ),
                                                        if (hasConfig)
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                              top: 2,
                                                            ),
                                                            child: Tooltip(
                                                              message: configLabel,
                                                              child: Text(
                                                                configLabel,
                                                                maxLines: 1,
                                                                overflow: TextOverflow
                                                                    .ellipsis,
                                                                style: TextStyle(
                                                                  fontSize: 10.5,
                                                                  height: 1.18,
                                                                  color: scheme
                                                                      .primary
                                                                      .withValues(
                                                                        alpha: 0.82,
                                                                      ),
                                                                  fontWeight:
                                                                      FontWeight.w500,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.quantity > 1
                                                          ? _formatAmount(
                                                              item.unitAmount *
                                                                  item.quantity,
                                                            )
                                                          : (item.unitAmount !=
                                                                item
                                                                    .product
                                                                    .amount
                                                              ? '${_formatAmount(item.unitAmount)} ₽'
                                                              : item.product.price),
                                                      style: TextStyle(
                                                        color: scheme.primary,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    if (item.quantity > 1)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                          top: 2,
                                                        ),
                                                        child: Text(
                                                          '${_formatAmount(item.unitAmount)} × ${item.quantity}',
                                                          style: const TextStyle(
                                                            fontSize: 10,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      ),
                                                    const SizedBox(height: 4),
                                                    SizedBox(
                                                      height: 28,
                                                      width: 108,
                                                      child: DecoratedBox(
                                                        decoration: BoxDecoration(
                                                          color:
                                                              scheme.primaryContainer,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                            10,
                                                          ),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              child: InkWell(
                                                                onTap: () => context
                                                                    .read<
                                                                      CartProvider
                                                                      >()
                                                                    .decrement(
                                                                      item.lineId,
                                                                    ),
                                                                borderRadius:
                                                                    const BorderRadius.horizontal(
                                                                      left:
                                                                          Radius.circular(
                                                                            10,
                                                                          ),
                                                                    ),
                                                                child: Center(
                                                                  child: Icon(
                                                                    Icons
                                                                        .remove_rounded,
                                                                    size: 15,
                                                                    color: scheme
                                                                        .primary,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            Container(
                                                              width: 1,
                                                              height: 14,
                                                              color: scheme.primary
                                                                  .withValues(
                                                                    alpha: 0.2,
                                                                  ),
                                                            ),
                                                            Expanded(
                                                              child: Center(
                                                                child: Text(
                                                                  '${item.quantity}',
                                                                  style: TextStyle(
                                                                    fontSize: 12.5,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: scheme
                                                                        .primary,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            Container(
                                                              width: 1,
                                                              height: 14,
                                                              color: scheme.primary
                                                                  .withValues(
                                                                    alpha: 0.2,
                                                                  ),
                                                            ),
                                                            Expanded(
                                                              child: InkWell(
                                                                onTap: () => context
                                                                    .read<
                                                                      CartProvider
                                                                      >()
                                                                    .add(
                                                                      item.product,
                                                                      item.configuration,
                                                                    ),
                                                                borderRadius:
                                                                    const BorderRadius.horizontal(
                                                                      right:
                                                                          Radius.circular(
                                                                            10,
                                                                          ),
                                                                    ),
                                                                child: Center(
                                                                  child: Icon(
                                                                    Icons.add_rounded,
                                                                    size: 15,
                                                                    color: scheme
                                                                        .primary,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Bottom bar
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  cart.selectedCount > 0
                                      ? 'Итого (${cart.selectedCount} шт.)'
                                      : 'Ничего не выбрано',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  cart.totalAmountFormatted,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: cart.selectedCount > 0
                                        ? scheme.primary
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: cart.selectedCount == 0
                                    ? null
                                    : () {
                                        final count = cart.selectedCount;
                                        final total = cart.totalAmountFormatted;
                                        context.read<CartProvider>().buySelected();
                                        context
                                            .read<NotificationsProvider>()
                                            .addOrderNotification(
                                              itemCount: count,
                                              totalAmount: total,
                                            );
                                        Navigator.push(
                                          context,
                                          slideUpRoute(
                                            OrderSuccessScreen(
                                              itemCount: count,
                                              totalAmount: total,
                                            ),
                                          ),
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: scheme.primary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey[300],
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Купить выбранное',
                                  style: TextStyle(fontSize: 15),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
