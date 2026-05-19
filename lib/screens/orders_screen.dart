import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/products_provider.dart';
import '../widgets/product_detail_entry.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('История заказов')),
      body: uid == null
          ? const Center(child: Text('Необходима авторизация'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('orders')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🛍️', style: TextStyle(fontSize: 64)),
                        SizedBox(height: 12),
                        Text('Заказов пока нет',
                            style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final totalSpent = docs.fold<double>(0, (acc, d) {
                  final data = d.data() as Map<String, dynamic>;
                  return acc + (data['total'] as num).toDouble();
                });
                final totalFormatted = totalSpent
                    .toStringAsFixed(0)
                    .replaceAllMapped(
                        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ');
                final scheme = Theme.of(context).colorScheme;

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [scheme.primary, scheme.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Потрачено всего',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text('$totalFormatted ₽',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Заказов',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text('${docs.length}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      );
                    }
                    final data = docs[i - 1].data() as Map<String, dynamic>;
                    return _OrderCard(data: data, index: docs.length - (i - 1));
                  },
                );
              },
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int index;
  const _OrderCard({required this.data, required this.index});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final date = DateTime.fromMillisecondsSinceEpoch(data['date'] as int);
    final total = data['totalFormatted'] as String;
    final itemCount = data['itemCount'] as int;
    final items = (data['items'] as List<dynamic>).cast<Map<String, dynamic>>();
    final products = context.read<ProductsProvider>().products;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text('#$index',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: scheme.primary)),
          ),
        ),
        title: Text(
          total,
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: scheme.primary),
        ),
        subtitle: Text(
          '${_formatDate(date)}  ·  $itemCount ${_itemWord(itemCount)}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...items.map((item) {
            final productId = item['productId'] as int?;
            Product? product;
            if (productId != null) {
              for (final p in products) {
                if (p.id == productId) {
                  product = p;
                  break;
                }
              }
            }

            return InkWell(
              onTap: product == null
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreenEntry(product: product!),
                        ),
                      ),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item['image'] as String,
                        width: 48, height: 48, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 48, height: 48,
                          color: scheme.primaryContainer,
                          child: Icon(Icons.image_not_supported,
                              size: 20, color: scheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(
                            '${item['price']}  ×  ${item['quantity']}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    if (product != null)
                      Icon(Icons.chevron_right, color: scheme.primary, size: 18),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  String _itemWord(int n) {
    if (n % 100 >= 11 && n % 100 <= 19) return 'товаров';
    switch (n % 10) {
      case 1: return 'товар';
      case 2: case 3: case 4: return 'товара';
      default: return 'товаров';
    }
  }
}
