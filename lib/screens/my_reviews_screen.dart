import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/products_provider.dart';
import '../models/product.dart';
import '../widgets/product_detail_entry.dart';

class MyReviewsScreen extends StatelessWidget {
  const MyReviewsScreen({super.key});

  Product? _resolveProduct(BuildContext context, Product? product) {
    if (product == null) return null;
    final all = context.read<ProductsProvider>().products;
    for (final p in all) {
      if (p.id == product.id) return p;
    }
    return product;
  }

  Future<void> _delete(BuildContext context, DocumentSnapshot doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Удалить отзыв?', style: TextStyle(color: Color(0xFFFF8C00))),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF8C00),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final data = doc.data() as Map<String, dynamic>?;
    final hasUid = data?['uid'] != null;
    await doc.reference.delete();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && hasUid) {
      await FirebaseFirestore.instance.collection('users').doc(uid)
          .set({'reviewsCount': FieldValue.increment(-1)}, SetOptions(merge: true));
    }
  }

  Future<void> _edit(BuildContext context, DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final textController = TextEditingController(text: data['text'] as String? ?? '');
    int rating = ((data['rating'] as num?)?.toInt()) ?? 5;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Редактировать отзыв',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Оценка: '),
                  ...List.generate(5, (i) => GestureDetector(
                    onTap: () => setInner(() => rating = i + 1),
                    child: Icon(
                      i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: const Color(0xFFFF8C00), size: 36,
                    ),
                  )),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 4,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Текст отзыва',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final text = textController.text.trim();
                  if (text.isEmpty) return;
                  await doc.reference.update({
                    'text': text,
                    'rating': rating.toDouble(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: const Color(0xFFFF8C00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xFFFF8C00),
                          const Color(0xFFFFA500),
                        ]
                      : [
                          const Color(0xFFFF8C00),
                          const Color(0xFFFFA500),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      const Text(
                        'Мои отзывы',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          uid == null
              ? SliverFillRemaining(
                  child: Center(child: const Text('Необходима авторизация')),
                )
              : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collectionGroup('reviews')
                  .where('uid', isEqualTo: uid)
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return SliverToBoxAdapter(
                    child: Center(child: const CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return SliverToBoxAdapter(
                    child: Center(child: Text('Ошибка: ${snap.error}')),
                  );
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return SliverFillRemaining(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1A1A) : Colors.grey[50],
                      ),
                      child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF8C00),
                                    Color(0xFFFFA500),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF8C00).withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.rate_review_outlined,
                                  size: 60, color: Colors.white),
                            ),
                            const SizedBox(height: 24),
                            Text('Отзывов пока нет',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 24, 
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFFFFA500) : const Color(0xFFFF8C00),
                                )),
                            const SizedBox(height: 12),
                            Text(
                              'Посетите карточку товара и оставьте свой отзыв — это поможет другим покупателям',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: isDark ? const Color(0xFF999999) : Colors.grey[600]),
                            ),
                            const SizedBox(height: 36),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFA500),
                                    Color(0xFFFF8C00),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 4),
                                  Icon(Icons.star_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 4),
                                  Icon(Icons.star_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 4),
                                  Icon(Icons.star_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 4),
                                  Icon(Icons.star_rounded, color: Colors.white, size: 20),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
                }
                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final doc = docs[i];
                      final data = doc.data() as Map<String, dynamic>;
                      final rating = (data['rating'] as num).toDouble();
                      final text = data['text'] as String? ?? '';
                      final date = DateTime.fromMillisecondsSinceEpoch(data['date'] as int);
                      final productId = doc.reference.parent.parent?.id ?? '';
                      final productIdInt = int.tryParse(productId);
                      final product = productIdInt == null
                          ? null
                          : context.read<ProductsProvider>().products
                              .where((p) => p.id == productIdInt)
                              .firstOrNull;

                      return _ReviewCard(
                        doc: doc,
                        product: product,
                        rating: rating,
                        text: text,
                        date: date,
                        onDelete: () => _delete(context, doc),
                        onEdit: () => _edit(context, doc),
                        onProductTap: product == null
                            ? null
                            : () => Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (_) => ProductDetailScreenEntry(
                                        product: _resolveProduct(context, product)!))),
                      );
                      },
                      childCount: docs.length,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final Product? product;
  final double rating;
  final String text;
  final DateTime date;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback? onProductTap;

  const _ReviewCard({
    required this.doc,
    required this.product,
    required this.rating,
    required this.text,
    required this.date,
    required this.onDelete,
    required this.onEdit,
    this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final image = product?.images.firstOrNull;

    return Card(
      elevation: isDark ? 3 : 1,
      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark 
              ? const Color(0xFFFF8C00).withValues(alpha: 0.2)
              : const Color(0xFFFF8C00).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product header
          InkWell(
            onTap: onProductTap,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF3A2A1A),
                          const Color(0xFF2A1A0A),
                        ]
                      : [
                          const Color(0xFFFFF3E0),
                          const Color(0xFFFFE0B2),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  // Product image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: image != null
                        ? Image.network(image,
                            width: 60, height: 60, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imagePlaceholder(scheme))
                        : _imagePlaceholder(scheme),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product?.name ?? 'Товар #${doc.reference.parent.parent?.id}',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, 
                              fontSize: 15, 
                              color: isDark ? const Color(0xFFFFA500) : const Color(0xFFFF8C00)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (product != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8C00).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(product!.price,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFFF8C00),
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onProductTap != null)
                    const Icon(Icons.chevron_right, color: Color(0xFFFF8C00)),
                ],
              ),
            ),
          ),

          // Review body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Row(
                      children: List.generate(5, (s) => Icon(
                        s < rating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 22,
                        color: s < rating.round() 
                            ? const Color(0xFFFFA500) 
                            : (isDark ? const Color(0xFF555555) : Colors.grey[300]),
                      )),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _ratingColor(rating).withValues(alpha: 0.3),
                            _ratingColor(rating).withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _ratingColor(rating)),
                      ),
                    ),
                    const Spacer(),
                    Text(_formatDate(date),
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF999999) : Colors.grey[600])),
                  ],
                ),
                const SizedBox(height: 10),
                if (text.isNotEmpty) ...[
                  Text(text,
                      style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark ? const Color(0xFFCCCCCC) : Colors.grey[800])),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA500).withValues(alpha: isDark ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: Color(0xFFFFA500), size: 20),
                        onPressed: onEdit,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: isDark ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent, size: 20),
                        onPressed: onDelete,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(ColorScheme scheme) => Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFA500),
              Color(0xFFFF8C00),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.music_note, color: Colors.white, size: 28),
      );

  Color _ratingColor(double r) {
    if (r >= 4) return const Color(0xFFFFA500); // Orange for good ratings
    if (r >= 3) return const Color(0xFFFF8C00); // Dark orange for medium
    return Colors.redAccent;
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
}
