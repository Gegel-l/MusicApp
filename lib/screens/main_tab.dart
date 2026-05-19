import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/products_provider.dart';
import '../providers/compare_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/skeleton_card.dart';
import 'notifications_screen.dart';
import 'compare_screen.dart';
import '../utils/search_history_service.dart';

enum SortOption { none, priceAsc, priceDesc, ratingDesc, newest }

class MainTab extends StatefulWidget {
  final VoidCallback? onGoToCatalog;
  const MainTab({super.key, this.onGoToCatalog});

  @override
  State<MainTab> createState() => _MainTabState();
}

class _MainTabState extends State<MainTab> {
  String _searchQuery = '';
  SortOption _sort = SortOption.none;
  final bool _loading = false;
  List<String> _history = [];
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  final _bannerController = PageController();
  int _bannerIndex = 0;
  Timer? _bannerTimer;

  static const _banners = [
    {
      'title': 'Скидки до 30%',
      'subtitle': 'На все инструменты\nэтого месяца',
      'icon': Icons.piano,
    },
    {
      'title': 'Новые гитары',
      'subtitle': 'Акустика и электро\nот ведущих брендов',
      'icon': Icons.queue_music,
    },
    {
      'title': 'Ударные инструменты',
      'subtitle': 'Барабаны, перкуссия\nи аксессуары',
      'icon': Icons.speaker,
    },
    {
      'title': 'Электроника',
      'subtitle': 'Синтезаторы и MIDI\nдля профессионалов',
      'icon': Icons.electrical_services,
    },
  ];

  @override
  void initState() {
    super.initState();
    SearchHistoryService.load().then((h) => setState(() => _history = h));
    _bannerTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      final next = (_bannerIndex + 1) % _banners.length;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _bannerController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    setState(() => _sort = SortOption.none);
    await context.read<ProductsProvider>().refresh();
  }

  List _getFiltered(List products) => products.where((p) {
    final matchSearch = _searchQuery.isEmpty ||
        p.name.toLowerCase().contains(_searchQuery.toLowerCase());
    return matchSearch;
  }).toList()
    ..sort((a, b) => switch (_sort) {
          SortOption.priceAsc   => a.amount.compareTo(b.amount),
          SortOption.priceDesc  => b.amount.compareTo(a.amount),
          SortOption.ratingDesc => b.rating.compareTo(a.rating),
          SortOption.newest     => b.id.compareTo(a.id),
          SortOption.none       => 0,
        });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final productsProvider = context.watch<ProductsProvider>();
    context.read<NotificationsProvider>().syncFromProducts(productsProvider.products);

    if (productsProvider.loading) {
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset('assets/icon/icon.png', width: 32, height: 32, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('MusicFIR',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 12,
                  crossAxisSpacing: 14, childAspectRatio: 0.50,
                ),
                itemCount: 6,
                itemBuilder: (_, __) => const SkeletonCard(),
              ),
            ),
          ],
        ),
      );
    }

    final filtered = _getFiltered(productsProvider.products);
    final visible = filtered.take(6).toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: scheme.primary,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Кастомный header в стиле Ozon
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
                             Expanded(
                               child: Text('MusicFIR',
                                   style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                             ),
                              Consumer<CompareProvider>(
                                builder: (context, compare, _) => IconButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (_, __, ___) => const CompareScreen(),
                                    transitionsBuilder: (_, anim, __, child) =>
                                        FadeTransition(opacity: anim, child: child),
                                    transitionDuration: const Duration(milliseconds: 200),
                                  ),
                                ),
                                  icon: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      const Icon(Icons.compare_arrows, color: Colors.white, size: 26),
                                      if (compare.count > 0)
                                        Positioned(
                                          right: -2,
                                          top: -2,
                                          child: Container(
                                            width: 18,
                                            height: 18,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                compare.count > 9 ? '9+' : '${compare.count}',
                                                style: TextStyle(
                                                  color: Theme.of(context).primaryColor,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                             Consumer<NotificationsProvider>(
                               builder: (context, notif, _) => IconButton(
                                 onPressed: () => Navigator.push(
                                   context,
                                   PageRouteBuilder(
                                     pageBuilder: (_, __, ___) => const NotificationsScreen(),
                                     transitionsBuilder: (_, anim, __, child) =>
                                         FadeTransition(opacity: anim, child: child),
                                     transitionDuration: const Duration(milliseconds: 200),
                                   ),
                                 ),
                                 icon: Stack(
                                   clipBehavior: Clip.none,
                                   children: [
                                     const Icon(Icons.notifications_none, color: Colors.white, size: 26),
                                     if (notif.unreadCount > 0)
                                       Positioned(
                                         right: -2,
                                         top: -2,
                                         child: Container(
                                           width: 18,
                                           height: 18,
                                           decoration: const BoxDecoration(
                                             color: Colors.red,
                                             shape: BoxShape.circle,
                                           ),
                                           child: Center(
                                             child: Text(
                                               notif.unreadCount > 9 ? '9+' : '${notif.unreadCount}',
                                               style: const TextStyle(
                                                 color: Colors.white,
                                                 fontSize: 9,
                                                 fontWeight: FontWeight.bold,
                                               ),
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
                        const SizedBox(height: 12),
                        // Поисковая строка
                        TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() {
                            _searchQuery = v;
                          }),
                          onSubmitted: (v) {
                            if (v.trim().isNotEmpty) {
                              SearchHistoryService.add(v.trim()).then((h) => setState(() => _history = h));
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
                            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.close, color: Colors.grey[600]),
                                    onPressed: () => setState(() {
                                      _searchQuery = '';
                                      _searchController.clear();
                                    }),
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Search history
            if (_searchQuery.isEmpty && _history.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('История поиска',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                          GestureDetector(
                            onTap: () => SearchHistoryService.clear().then((_) => setState(() => _history = [])),
                            child: const Text('Очистить',
                                style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ),
                        ],
                      ),
                    ),
                    ..._history.map((q) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.history, size: 18, color: Colors.grey),
                      title: Text(q),
                      trailing: GestureDetector(
                        onTap: () => SearchHistoryService.remove(q).then((h) => setState(() => _history = h)),
                        child: const Icon(Icons.close, size: 16, color: Colors.grey),
                      ),
                      onTap: () {
                        _searchController.text = q;
                        setState(() => _searchQuery = q);
                      },
                    )),
                    const Divider(height: 1),
                  ],
                ),
              ),

            // Banner slider
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 140,
                      child: PageView.builder(
                        controller: _bannerController,
                        itemCount: _banners.length,
                        onPageChanged: (i) => setState(() => _bannerIndex = i),
                        itemBuilder: (_, i) {
                          final b = _banners[i];
                          return GestureDetector(
                            onTap: () {
                              widget.onGoToCatalog?.call();
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(b['title'] as String,
                                            style: const TextStyle(
                                                color: Colors.white70, fontSize: 10)),
                                        const SizedBox(height: 2),
                                        Text(b['subtitle'] as String,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                height: 1.2)),
                                        const SizedBox(height: 6),
                                        ElevatedButton(
                                          onPressed: () {
                                            widget.onGoToCatalog?.call();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: scheme.primary,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: const Text('Смотреть',
                                              style: TextStyle(fontSize: 11)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(b['icon'] as IconData,
                                      size: 52,
                                      color: Colors.white.withValues(alpha: 0.2)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _banners.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _bannerIndex == i ? 20 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _bannerIndex == i
                                ? scheme.primary
                                : scheme.primary.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  _searchQuery.isNotEmpty
                      ? 'Результаты поиска'
                      : 'Популярные товары',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
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
                    _SortChip(
                      label: 'По умолчанию',
                      icon: Icons.clear_all,
                      isSelected: _sort == SortOption.none,
                      onTap: () => setState(() => _sort = SortOption.none),
                    ),
                    const SizedBox(width: 8),
                    _SortChip(
                      label: 'Дешевле',
                      icon: Icons.arrow_upward,
                      isSelected: _sort == SortOption.priceAsc,
                      onTap: () => setState(() => _sort = SortOption.priceAsc),
                    ),
                    const SizedBox(width: 8),
                    _SortChip(
                      label: 'Дороже',
                      icon: Icons.arrow_downward,
                      isSelected: _sort == SortOption.priceDesc,
                      onTap: () => setState(() => _sort = SortOption.priceDesc),
                    ),
                    const SizedBox(width: 8),
                    _SortChip(
                      label: 'По рейтингу',
                      icon: Icons.star,
                      isSelected: _sort == SortOption.ratingDesc,
                      onTap: () => setState(() => _sort = SortOption.ratingDesc),
                    ),
                    const SizedBox(width: 8),
                    _SortChip(
                      label: 'Новинки',
                      icon: Icons.new_releases_outlined,
                      isSelected: _sort == SortOption.newest,
                      onTap: () => setState(() => _sort = SortOption.newest),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            if (filtered.isEmpty)
              SliverFillRemaining(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? 'Ничего не найдено по запросу «$_searchQuery»'
                          : 'Нет товаров в этой категории',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              )
            else if (_loading)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const SkeletonCard(),
                    childCount: 6,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 12,
                    crossAxisSpacing: 14, childAspectRatio: 0.50,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => ProductCard(product: visible[i]),
                    childCount: visible.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 12,
                    crossAxisSpacing: 14, childAspectRatio: 0.50,
                  ),
                ),
              ),
            if (!_loading && filtered.length > 6)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => widget.onGoToCatalog?.call(),
                      icon: const Icon(Icons.grid_view_rounded, size: 18),
                      label: const Text('Смотреть все товары'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortChip({
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
          color: isSelected ? scheme.primary : scheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? scheme.primary : scheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : scheme.primary),
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
