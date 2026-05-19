import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/instrument_configurator.dart' show configuratorLabelSlug;
import '../models/product.dart';
import '../providers/products_provider.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductsProvider>().products;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Header в стиле Ozon
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: scheme.primary,
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
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Админ-панель',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(Icons.inventory_2_outlined, color: Colors.white70, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${products.length} товаров',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          products.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Нет товаров',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Нажмите + чтобы добавить первый товар',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ProductTile(
                          product: products[i],
                          onEdit: () => _openForm(context, products[i]),
                          onDelete: () => _confirmDelete(context, products[i]),
                        ),
                      ),
                      childCount: products.length,
                    ),
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Добавить товар'),
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _openForm(BuildContext context, Product? product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ProductsProvider>(),
        child: _ProductForm(product: product),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product p) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Удалить товар?'),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(dialogContext).style,
            children: [
              const TextSpan(text: 'Товар '),
              TextSpan(text: '«${p.name}»',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: ' будет удалён из Firebase без возможности восстановления.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await FirebaseFirestore.instance
                  .collection('products')
                  .doc(p.id.toString())
                  .delete();
              if (context.mounted) context.read<ProductsProvider>().refresh();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ProductTile({required this.product, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                product.images.first,
                width: 70, height: 70, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 70, height: 70,
                  color: scheme.primaryContainer,
                  child: Icon(Icons.image_not_supported, color: scheme.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (product.tag.isNotEmpty) ...[  
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(product.tag,
                          style: TextStyle(fontSize: 11, color: scheme.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(product.price,
                      style: TextStyle(color: scheme.primary,
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.category_outlined, size: 13, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(product.category,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.star, size: 13, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text('${product.rating}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                _ActionBtn(
                  icon: Icons.edit_outlined,
                  color: scheme.primary,
                  onTap: onEdit,
                ),
                const SizedBox(height: 6),
                _ActionBtn(
                  icon: Icons.delete_outline,
                  color: Colors.red,
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _ProductForm extends StatefulWidget {
  final Product? product;
  const _ProductForm({this.product});

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _category;
  late final TextEditingController _description;
  late final TextEditingController _tag;
  late final TextEditingController _rating;
  late final TextEditingController _images;
  late final TextEditingController _specs;
  late final TextEditingController _audioUrl;
  late final TextEditingController _videoUrl;
  late final TextEditingController _configuratorColors;
  late final TextEditingController _configuratorAccessories;
  bool _loading = false;

  static const _categories = [
    'Клавишные', 'Струнные', 'Духовые', 'Ударные', 'Электронные', 'Аксессуары'
  ];

  static const _tags = ['', 'Хит', 'Новинка', 'Скидка'];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name        = TextEditingController(text: p?.name ?? '');
    _price       = TextEditingController(text: p?.price ?? '');
    _category    = TextEditingController(text: p?.category ?? _categories.first);
    _description = TextEditingController(text: p?.description ?? '');
    _tag         = TextEditingController(text: p?.tag ?? '');
    _rating      = TextEditingController(text: p?.rating.toString() ?? '5.0');
    _images      = TextEditingController(text: p?.images.join('\n') ?? '');
    _specs       = TextEditingController(
      text: p?.specs.entries.map((e) => '${e.key}: ${e.value}').join('\n') ?? '',
    );
    _audioUrl    = TextEditingController(text: p?.audioUrl ?? '');
    _videoUrl    = TextEditingController(text: p?.videoUrl ?? '');
    _configuratorColors = TextEditingController(
      text: p == null || p.configuratorColors.isEmpty
          ? ''
          : p.configuratorColors
              .map((c) =>
                  '${c.label}${c.hex != null && c.hex!.trim().isNotEmpty ? '|${c.hex!.trim()}' : ''}')
              .join('\n'),
    );
    _configuratorAccessories = TextEditingController(
      text: p == null || p.configuratorAccessories.isEmpty
          ? ''
          : p.configuratorAccessories
              .map((a) => '${a.id}|${a.label}|${a.priceAddon.toStringAsFixed(0)}')
              .join('\n'),
    );
  }

  List<Map<String, dynamic>> _parseConfiguratorColorsPayload() {
    final out = <Map<String, dynamic>>[];
    for (final line in _configuratorColors.text.split('\n')) {
      final t = line.trim();
      if (t.isEmpty) continue;
      final parts = t.split('|');
      final label = parts.first.trim();
      if (label.isEmpty) continue;
      final hex = parts.length > 1 ? parts[1].trim() : '';
      final slug = configuratorLabelSlug(label);
      final id = slug.isEmpty ? label.hashCode.abs().toString() : slug;
      out.add({
        'id': id,
        'label': label,
        if (hex.isNotEmpty) 'hex': hex.startsWith('#') ? hex : '#$hex',
      });
    }
    return out;
  }

  List<Map<String, dynamic>> _parseConfiguratorAccessoriesPayload() {
    final out = <Map<String, dynamic>>[];
    for (final line in _configuratorAccessories.text.split('\n')) {
      final t = line.trim();
      if (t.isEmpty) continue;
      final parts = t.split('|');
      if (parts.length < 3) continue;
      final id = parts[0].trim();
      final label = parts[1].trim();
      final price = double.tryParse(parts[2].trim()) ?? 0;
      if (id.isEmpty || label.isEmpty) continue;
      out.add({'id': id, 'label': label, 'priceAddon': price});
    }
    return out;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _price,
      _category,
      _description,
      _tag,
      _rating,
      _images,
      _specs,
      _audioUrl,
      _videoUrl,
      _configuratorColors,
      _configuratorAccessories,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final db = FirebaseFirestore.instance;
    final isEdit = widget.product != null;
    final id = isEdit
        ? widget.product!.id
        : DateTime.now().millisecondsSinceEpoch % 1000000;

    final specs = <String, String>{};
    for (final line in _specs.text.trim().split('\n')) {
      final parts = line.split(':');
      if (parts.length >= 2) {
        specs[parts[0].trim()] = parts.sublist(1).join(':').trim();
      }
    }

    final allImages = _images.text.trim().split('\n').where((s) => s.isNotEmpty).toList();
    if (allImages.isEmpty) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы одну ссылку на изображение')));
      return;
    }

    final priceStr = _price.text.trim().endsWith('₽')
        ? _price.text.trim()
        : '${_price.text.trim()} ₽';

    final cfgColors = _parseConfiguratorColorsPayload();
    final cfgAccessory = _parseConfiguratorAccessoriesPayload();

    await db.collection('products').doc(id.toString()).set({
      'id': id,
      'name': _name.text.trim(),
      'price': priceStr,
      'amount': double.tryParse(_price.text.trim().replaceAll(RegExp(r'[^\d.]'), '')) ?? 0,
      'category': _category.text.trim(),
      'description': _description.text.trim(),
      'tag': _tag.text.trim(),
      'rating': double.tryParse(_rating.text.trim()) ?? 5.0,
      'images': allImages,
      'specs': specs,
      if (_audioUrl.text.trim().isNotEmpty) 'audioUrl': _audioUrl.text.trim(),
      if (_videoUrl.text.trim().isNotEmpty) 'videoUrl': _videoUrl.text.trim(),
      if (cfgColors.isNotEmpty) 'configuratorColors': cfgColors,
      if (cfgAccessory.isNotEmpty) 'configuratorAccessories': cfgAccessory,
    });

    if (mounted) {
      context.read<ProductsProvider>().refresh();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEdit = widget.product != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Form(
        key: _formKey,
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(isEdit ? Icons.edit_outlined : Icons.add_box_outlined,
                        color: scheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Text(isEdit ? 'Редактировать' : 'Новый товар',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: EdgeInsets.fromLTRB(
                    20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
                children: [
                  _sectionLabel('Основное'),
                  _field(_name, 'Название товара', icon: Icons.label_outline, required: true),
                  _field(_price, 'Цена', icon: Icons.attach_money, hint: '12 500 ₽', required: true,
                      keyboardType: TextInputType.number),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _categories.contains(_category.text) ? _category.text : _categories.first,
                          isExpanded: true,
                          decoration: _decoration('Категория'),
                          items: _categories.map((c) =>
                              DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => _category.text = v ?? _categories.first,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _tags.contains(_tag.text) ? _tag.text : '',
                          isExpanded: true,
                          decoration: _decoration('Тег'),
                          items: _tags.map((t) =>
                              DropdownMenuItem(value: t, child: Text(t.isEmpty ? 'Без тега' : t))).toList(),
                          onChanged: (v) => _tag.text = v ?? '',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _field(_rating, 'Рейтинг', icon: Icons.star_outline,
                      keyboardType: TextInputType.number, hint: '4.5'),
                  const SizedBox(height: 8),
                  _sectionLabel('Описание'),
                  _field(_description, 'Описание товара', icon: Icons.description_outlined,
                      required: true, maxLines: 4),
                  _sectionLabel('Изображения'),
                  _field(_images, 'Ссылки на фото (каждая с новой строки)',
                      icon: Icons.image_outlined, required: true, maxLines: 4),
                  _sectionLabel('Медиа'),
                  _field(_audioUrl, 'Ссылка на аудио (mp3/wav)',
                      icon: Icons.audiotrack_outlined,
                      hint: 'https://.../sound.mp3'),
                  _field(_videoUrl, 'Ссылка на видео-обзор (mp4)',
                      icon: Icons.ondemand_video_outlined,
                      hint: 'Только прямая ссылка: https://.../overview.mp4'),
                  _sectionLabel('Характеристики'),
                  _field(_specs, 'Ключ: Значение (каждая с новой строки)',
                      icon: Icons.tune_outlined, maxLines: 5),
                  _sectionLabel('Конфигуратор (опционально)'),
                  _field(
                    _configuratorColors,
                    'Цвета: Название|#HEX (hex можно пропустить), по одной строке',
                    icon: Icons.color_lens_outlined,
                    maxLines: 4,
                    hint: 'Чёрный|#212121\nНатуральное дерево',
                  ),
                  _field(
                    _configuratorAccessories,
                    'Аксессуары: id|Название|цена_добавки (₽), по строке',
                    icon: Icons.extension_outlined,
                    maxLines: 4,
                    hint: 'case|Жёсткий кейс|2500\nstrap|Ремень|800',
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(isEdit ? 'Сохранить изменения' : 'Добавить товар',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 10),
    child: Text(label,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary)),
  );

  Widget _field(TextEditingController ctrl, String label,
      {bool required = false, int maxLines = 1,
      TextInputType? keyboardType, String? hint, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: _decoration(label, icon, hint),
        validator: required ? (v) => v!.trim().isEmpty ? 'Обязательное поле' : null : null,
      ),
    );
  }

  InputDecoration _decoration(String label, [IconData? icon, String? hint]) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      );
}
