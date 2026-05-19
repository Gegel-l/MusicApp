import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';
import '../providers/reviews_provider.dart';

/// Секция отзывов
class ProductReviewsSection extends StatefulWidget {
  final int productId;

  const ProductReviewsSection({super.key, required this.productId});

  @override
  State<ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<ProductReviewsSection> {
  @override
  void initState() {
    super.initState();
    context.read<ReviewsProvider>().loadReviews(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final provider = context.watch<ReviewsProvider>();
    final reviews = provider.getReviews(widget.productId);
    final avg = provider.averageRating(widget.productId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Отзывы',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                if (reviews.isNotEmpty) ...[
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 2),
                  Text(
                    avg.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    ' (${reviews.length})',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ],
            ),
            TextButton.icon(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => AddReviewDialog(productId: widget.productId),
              ),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Написать'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Пока нет отзывов. Будьте первым!',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ...reviews.map(
            (r) => ReviewCard(review: r, scheme: scheme),
          ),
      ],
    );
  }
}

/// Карточка отзыва
class ReviewCard extends StatelessWidget {
  final Review review;
  final ColorScheme scheme;

  const ReviewCard({
    super.key,
    required this.review,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  review.author,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              review.text,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '${review.date.day.toString().padLeft(2, '0')}.${review.date.month.toString().padLeft(2, '0')}.${review.date.year}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// Диалог добавления отзыва
class AddReviewDialog extends StatefulWidget {
  final int productId;

  const AddReviewDialog({super.key, required this.productId});

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  final _textController = TextEditingController();
  int _rating = 5;
  String _authorName = '';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final name = doc.data()?['displayName'] as String?;
    if (mounted && name != null && name.isNotEmpty) {
      setState(() => _authorName = name);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        20,
        16,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Оставить отзыв',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          if (_authorName.isNotEmpty)
            Text(
              'от $_authorName',
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Текст отзыва',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Оценка: '),
              ...List.generate(
                5,
                (i) => GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final text = _textController.text.trim();
              if (text.isEmpty) return;
              final author = _authorName.isNotEmpty
                  ? _authorName
                  : (FirebaseAuth.instance.currentUser?.email ?? 'Аноним');
              context.read<ReviewsProvider>().addReview(
                    widget.productId,
                    Review(
                      author: author,
                      text: text,
                      rating: _rating.toDouble(),
                      date: DateTime.now(),
                    ),
                  );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }
}
