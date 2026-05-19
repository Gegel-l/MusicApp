import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/compare_provider.dart';
import '../widgets/product_detail_entry.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  late List<Product> _products;

  @override
  void initState() {
    super.initState();
    _products = context.read<CompareProvider>().products;
  }

  void _remove(int id) async {
    final compare = context.read<CompareProvider>();
    if (_products.length == 1) {
      Navigator.of(context).pop();
      await Future.delayed(const Duration(milliseconds: 400));
      compare.remove(id);
    } else {
      setState(() => _products.removeWhere((p) => p.id == id));
      compare.remove(id);
    }
  }

  void _clear() async {
    final compare = context.read<CompareProvider>();
    Navigator.of(context).pop();
    await Future.delayed(const Duration(milliseconds: 400));
    compare.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_products.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Сравнение товаров')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.compare_arrows, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Добавьте товары для сравнения',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    final allSpecKeys = _products
        .expand((p) => p.specs.keys)
        .toSet()
        .toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Сравнение'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Очистить сравнение?'),
                backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Отмена'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _clear();
                    },
                    child: const Text('Очистить'),
                  ),
                ],
              ),
            ),
            icon: const Icon(Icons.delete_outline, size: 20),
            label: const Text('Очистить'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductCards(context),
            const SizedBox(height: 16),
            _buildSection(context, 'Основные', [
              _buildRow(context, 'Рейтинг', (p) => '⭐ ${p.rating.toStringAsFixed(1)}'),
              _buildRow(context, 'Категория', (p) => p.category),
              _buildRow(context, 'Цена', (p) => '${p.price} ₽'),
            ]),
            if (allSpecKeys.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildSection(
                context,
                'Характеристики',
                allSpecKeys.map((key) => _buildRow(
                  context,
                  key,
                  (p) => p.specs[key] ?? '—',
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductCards(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 16),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _products.map((product) => _buildProductChip(context, product)).toList()
              ..insert(0, const SizedBox(width: 4)),
          ),
        ),
      ),
    );
  }

  Widget _buildProductChip(BuildContext context, Product product) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreenEntry(product: product),
              ),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 100,
                    width: 100,
                    child: product.images.isNotEmpty
                        ? Image.network(
                            product.images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[200],
                              child: Icon(Icons.image_not_supported,
                                  color: isDark ? Colors.grey[600] : Colors.grey[400]),
                            ),
                            loadingBuilder: (_, child, progress) =>
                                progress == null ? child : Container(
                                  color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[200],
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                ),
                          )
                        : Container(
                            color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[200],
                            child: Icon(
                              Icons.image_not_supported,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: -4,
                  right: -4,
                  child: GestureDetector(
                    onTap: () => _remove(product.id),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${product.price} ₽',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String Function(Product) getValue) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: isDark ? const Color(0xFF333333) : Colors.grey[200],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _products.map((p) {
              final value = getValue(p);
              return Container(
                constraints: BoxConstraints(
                  maxWidth: (MediaQuery.of(context).size.width - 64 - (_products.length - 1) * 8) / _products.length,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
