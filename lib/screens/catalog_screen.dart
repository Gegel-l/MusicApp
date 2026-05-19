import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/products_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import '../widgets/product_detail_entry.dart';
import '../utils/search_history_service.dart';

enum _Sort { none, priceAsc, priceDesc, ratingDesc, newest }

class CatalogScreen extends StatefulWidget {
  final String? initialCategory;
  const CatalogScreen({super.key, this.initialCategory});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late String? _category;
  String? _tag;
  final bool _highRating = false;
  _Sort _sort = _Sort.none;
  String _search = '';
  bool _searchActive = false;
  int _visibleCount = 6;
  bool _loadingMore = false;
  bool _showScrollTop = false;
  bool _isGrid = true;
  RangeValues? _priceRange;
  double _priceMin = 0;
  double _priceMax = 0;
  List<String> _history = [];
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  static const _categories = [
    {
      'label': 'Клавишные',
      'icon': Icons.piano,
      'image': 'assets/categories/piano.png',
    },
    {
      'label': 'Струнные',
      'icon': Icons.queue_music,
      'image': 'assets/categories/guitar.png',
    },
    {
      'label': 'Духовые',
      'icon': Icons.music_note,
      'image': 'assets/categories/saxophone.png',
    },
    {
      'label': 'Ударные',
      'icon': Icons.speaker,
      'image': 'assets/categories/drums.png',
    },
    {
      'label': 'Электронные',
      'icon': Icons.electrical_services,
      'image': 'assets/categories/synthesizer.png',
    },
    {
      'label': 'Аксессуары',
      'icon': Icons.build_outlined,
      'image': 'assets/categories/accessories.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _scrollController.addListener(_onScroll);
    SearchHistoryService.load().then((h) => setState(() => _history = h));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final px = _scrollController.position.pixels;
    final show = px > 300;
    if (show != _showScrollTop) {
      setState(() => _showScrollTop = show);
    }
    if (_loadingMore) return;
    if (px >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    final total = _filtered.length;
    if (_visibleCount >= total) return;
    setState(() => _loadingMore = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _visibleCount = (_visibleCount + 6).clamp(0, total);
          _loadingMore = false;
        });
      }
    });
  }

  void _reset() => setState(() => _visibleCount = 6);

  void _resetAll() => setState(() {
    _category = null;
    _tag = null;
    _sort = _Sort.none;
    _visibleCount = 6;
  });

  int get _activeFilterCount =>
      (_category != null ? 1 : 0) +
      (_tag != null ? 1 : 0) +
      (_highRating ? 1 : 0);
  //Filtering function
  List<Product> get _filtered {
    final all = context.read<ProductsProvider>().products;
    final list =
        all.where((p) {
          final matchCat = _category == null || p.category == _category;
          final matchTag = _tag == null || p.tag == _tag;
          final matchRating = !_highRating || p.rating >= 4.0;
          final matchSearch =
              _search.isEmpty || //
              p.name.toLowerCase().contains(_search.toLowerCase()) ||
              p.category.toLowerCase().contains(_search.toLowerCase()) ||
              p.tag.toLowerCase().contains(_search.toLowerCase()) ||
              p.description.toLowerCase().contains(_search.toLowerCase());
          final matchPrice =
              _priceRange == null || // ///
              (p.amount >= _priceRange!.start && p.amount <= _priceRange!.end);
          return matchCat &&
              matchTag &&
              matchRating &&
              matchSearch &&
              matchPrice;

          ///
        }).toList()..sort(
          (a, b) => switch (_sort) {
            _Sort.priceAsc => a.amount.compareTo(b.amount),
            _Sort.priceDesc => b.amount.compareTo(a.amount),

            ///
            _Sort.ratingDesc => b.rating.compareTo(a.rating),
            _Sort.newest => b.id.compareTo(a.id),
            _Sort.none => 0,
          },
        );
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final products = context.watch<ProductsProvider>().products;
    if (products.isNotEmpty && _priceRange == null) {
      final amounts = products.map((p) => p.amount).toList();
      _priceMin = amounts.reduce((a, b) => a < b ? a : b);
      _priceMax = amounts.reduce((a, b) => a > b ? a : b);
      _priceRange = RangeValues(_priceMin, _priceMax);
    }
    final filtered = _filtered;
    final visible = filtered.take(_visibleCount).toList();
    ////
    return Scaffold(
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 250),
        offset: _showScrollTop ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: _showScrollTop ? 1 : 0,
          child: FloatingActionButton.small(
            onPressed: () => _scrollController.animateTo(
              0, //
              duration: const Duration(milliseconds: 400),

              ///
              curve: Curves.easeOut,
            ),
            tooltip: 'Наверх',
            child: const Icon(Icons.keyboard_arrow_up),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            CustomScrollView(
              controller: _scrollController, ////////
              slivers: [
                // Кастомный header
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
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Каталог',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (_activeFilterCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.25,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$_activeFilterCount',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Поисковая строка
                            TextField(
                              controller: _searchController,
                              onChanged: (v) => setState(() {
                                _search = v;
                                _searchActive = v.isNotEmpty;
                                _reset();
                              }),
                              onSubmitted: (v) {
                                if (v.trim().isNotEmpty) {
                                  SearchHistoryService.add(
                                    v.trim(),
                                  ).then((h) => setState(() => _history = h));
                                }
                              },
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Поиск товаров...',
                                hintStyle: TextStyle(color: Colors.grey[600]),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.grey[600],
                                ),
                                suffixIcon: _search.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          color: Colors.grey[600],
                                        ),
                                        onPressed: () => setState(() {
                                          _search = '';
                                          _searchActive = false;
                                          _searchController.clear();
                                          _reset();
                                        }),
                                      )
                                    : null,
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Search history
                if (_search.isEmpty && _history.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'История поиска',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => SearchHistoryService.clear().then(
                                  (_) => setState(() => _history = []),
                                ),
                                child: const Text(
                                  'Очистить',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ..._history.map(
                          (q) => ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.history,
                              size: 18,
                              color: Colors.grey,
                            ),
                            title: Text(q),
                            trailing: GestureDetector(
                              onTap: () => SearchHistoryService.remove(
                                q,
                              ).then((h) => setState(() => _history = h)),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                            onTap: () {
                              _searchController.text = q;
                              setState(() {
                                _search = q;
                                _reset();
                              });
                            },
                          ),
                        ),
                        const Divider(height: 1),
                      ],
                    ),
                  ),

                // Category tiles
                if (!_searchActive) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child: Text(
                        'Категории',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemCount: _categories.length,
                        itemBuilder: (context, i) {
                          final cat = _categories[i];
                          final label = cat['label'] as String;
                          final icon = cat['icon'] as IconData;
                          final image = cat['image'] as String?;
                          final isSelected = _category == label;
                          final color = scheme.primary;
                          return GestureDetector(
                            onTap: () {
                              final currentOffset = _scrollController.hasClients
                                  ? _scrollController.offset
                                  : 0.0;
                              setState(() {
                                _category = isSelected ? null : label;
                                _reset();
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (_scrollController.hasClients) {
                                  _scrollController.jumpTo(
                                    currentOffset.clamp(
                                      0.0,
                                      _scrollController
                                          .position
                                          .maxScrollExtent,
                                    ),
                                  );
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 120,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color
                                    : color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? color
                                      : color.withValues(alpha: 0.15),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // Фоновое изображение (прозрачное)
                                  if (image != null)
                                    Positioned(
                                      right: -15,
                                      bottom: -15,
                                      width: 90,
                                      height: 90,
                                      child: Opacity(
                                        opacity: isSelected ? 0.6 : 0.5,
                                        child: Image.asset(
                                          image,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => Icon(
                                            icon,
                                            size: 90,
                                            color: isSelected
                                                ? Colors.white.withValues(
                                                    alpha: 0.2,
                                                  )
                                                : color.withValues(alpha: 0.12),
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    // Фоновая иконка (если нет изображения)
                                    Positioned(
                                      right: -15,
                                      bottom: -15,
                                      child: Icon(
                                        icon,
                                        size: 80,
                                        color: isSelected
                                            ? Colors.white.withValues(
                                                alpha: 0.2,
                                              )
                                            : color.withValues(alpha: 0.12),
                                      ),
                                    ),
                                  // Текст сверху слева в 1 строку
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    right: 8,
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : color,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children:
                              [
                                {
                                  'label': 'Хит',
                                  'icon': Icons.local_fire_department,
                                },
                                {'label': 'Новинка', 'icon': Icons.fiber_new},
                                {
                                  'label': 'Скидка',
                                  'icon': Icons.sell_outlined,
                                },
                              ].map((item) {
                                final tag = item['label'] as String;
                                final icon = item['icon'] as IconData;
                                final color = scheme.primary;
                                final isSelected = _tag == tag;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      final currentOffset =
                                          _scrollController.hasClients
                                          ? _scrollController.offset
                                          : 0.0;
                                      setState(() {
                                        _tag = isSelected ? null : tag;
                                        _reset();
                                      });
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            if (_scrollController.hasClients) {
                                              _scrollController.jumpTo(
                                                currentOffset.clamp(
                                                  0.0,
                                                  _scrollController
                                                      .position
                                                      .maxScrollExtent,
                                                ),
                                              );
                                            }
                                          });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? color
                                            : color.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isSelected
                                              ? color
                                              : color.withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            icon,
                                            size: 15,
                                            color: isSelected
                                                ? Colors.white
                                                : color,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            tag,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? Colors.white
                                                  : color,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],

                // Active filters
                if (_category != null || _tag != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (_category != null)
                                  _ActiveChip(
                                    label: _category!,
                                    onDeleted: () {
                                      final currentOffset =
                                          _scrollController.hasClients
                                          ? _scrollController.offset
                                          : 0.0;
                                      setState(() {
                                        _category = null;
                                        _reset();
                                      });
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            if (_scrollController.hasClients) {
                                              _scrollController.jumpTo(
                                                currentOffset.clamp(
                                                  0.0,
                                                  _scrollController
                                                      .position
                                                      .maxScrollExtent,
                                                ),
                                              );
                                            }
                                          });
                                    },
                                  ),
                                if (_tag != null)
                                  _ActiveChip(
                                    label: _tag!,
                                    onDeleted: () {
                                      final currentOffset =
                                          _scrollController.hasClients
                                          ? _scrollController.offset
                                          : 0.0;
                                      setState(() {
                                        _tag = null;
                                        _reset();
                                      });
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            if (_scrollController.hasClients) {
                                              _scrollController.jumpTo(
                                                currentOffset.clamp(
                                                  0.0,
                                                  _scrollController
                                                      .position
                                                      .maxScrollExtent,
                                                ),
                                              );
                                            }
                                          });
                                    },
                                  ),
                              ],
                            ),
                          ),
                          if (_category != null ||
                              _tag != null ||
                              _sort != _Sort.none)
                            TextButton(
                              onPressed: _resetAll,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey,
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text(
                                'Сбросить всё',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                // Filter bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            _category != null
                                ? _category!
                                : _search.isNotEmpty
                                ? 'Результаты поиска'
                                : 'Все товары',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isGrid ? Icons.view_list : Icons.grid_view,
                          ),
                          tooltip: _isGrid ? 'Список' : 'Сетка',
                          onPressed: () => setState(() => _isGrid = !_isGrid),
                        ),
                      ],
                    ),
                  ),
                ),

                // Фильтры сортировки
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _CatalogSortChip(
                          label: 'По умолчанию',
                          icon: Icons.clear_all,
                          isSelected: _sort == _Sort.none,
                          onTap: () => setState(() => _sort = _Sort.none),
                        ),
                        const SizedBox(width: 8),
                        _CatalogSortChip(
                          label: 'Дешевле',
                          icon: Icons.arrow_upward,
                          isSelected: _sort == _Sort.priceAsc,
                          onTap: () => setState(() => _sort = _Sort.priceAsc),
                        ),
                        const SizedBox(width: 8),
                        _CatalogSortChip(
                          label: 'Дороже',
                          icon: Icons.arrow_downward,
                          isSelected: _sort == _Sort.priceDesc,
                          onTap: () => setState(() => _sort = _Sort.priceDesc),
                        ),
                        const SizedBox(width: 8),
                        _CatalogSortChip(
                          label: 'По рейтингу',
                          icon: Icons.star,
                          isSelected: _sort == _Sort.ratingDesc,
                          onTap: () => setState(() => _sort = _Sort.ratingDesc),
                        ),
                        const SizedBox(width: 8),
                        _CatalogSortChip(
                          label: 'Новинки',
                          icon: Icons.new_releases_outlined,
                          isSelected: _sort == _Sort.newest,
                          onTap: () => setState(() => _sort = _Sort.newest),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Products grid
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        _search.isNotEmpty
                            ? 'Ничего не найдено по запросу «$_search»'
                            : 'Нет товаров в этой категории',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else if (_isGrid)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => ProductCard(product: visible[i]),
                        childCount: visible.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.50,
                          ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _ProductListTile(product: visible[i]),
                        childCount: visible.length,
                      ),
                    ),
                  ),

                if (_loadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (filtered.isNotEmpty && _visibleCount < filtered.length)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Text(
                          'Показано ${visible.length} из ${filtered.length}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;
  const _ActiveChip({required this.label, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDeleted,
            child: Icon(Icons.close, size: 15, color: color),
          ),
        ],
      ),
    );
  }
}

class _ProductListTile extends StatelessWidget {
  final Product product;
  const _ProductListTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cart = context.watch<CartProvider>();
    final favs = context.watch<FavoritesProvider>();
    final qtyTotal = cart.totalQuantityForProduct(product.id);
    final inCart = qtyTotal > 0;
    final isFav = favs.contains(product.id);
    final quantity = qtyTotal;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreenEntry(product: product),
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Image
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    product.images.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: scheme.primaryContainer,
                      child: Icon(
                        Icons.image_not_supported,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  if (product.tag.isNotEmpty)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.tag,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          '${product.rating}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.price,
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => context
                                  .read<FavoritesProvider>()
                                  .toggle(product),
                              child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : Colors.grey,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (inCart)
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => context
                                        .read<CartProvider>()
                                        .decrementBestEffortProduct(product.id),
                                    child: Icon(
                                      Icons.remove_circle,
                                      color: scheme.primary,
                                      size: 22,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Text(
                                      '$quantity',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => context
                                        .read<CartProvider>()
                                        .add(product),
                                    child: Icon(
                                      Icons.add_circle,
                                      color: scheme.primary,
                                      size: 22,
                                    ),
                                  ),
                                ],
                              )
                            else
                              GestureDetector(
                                onTap: () =>
                                    context.read<CartProvider>().add(product),
                                child: Icon(
                                  Icons.add_circle,
                                  color: scheme.primary,
                                  size: 24,
                                ),
                              ),
                          ],
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
    );
  }
}

class _CatalogSortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CatalogSortChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? scheme.primary
              : scheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? scheme.primary
                : scheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : scheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : scheme.primary,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
