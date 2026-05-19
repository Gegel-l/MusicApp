import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import 'main_tab.dart';
import 'catalog_screen.dart';
import 'favorites_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  Widget _buildTab(int index) {
    return HeroMode(
      enabled: _index == index,
      child: switch (index) {
        0 => MainTab(onGoToCatalog: () => _goToTab(1)),
        1 => const CatalogScreen(),
        2 => const FavoritesScreen(),
        3 => const CartScreen(),
        4 => ProfileScreen(
          onGoToCart: () => _goToTab(3),
          onGoToFavorites: () => _goToTab(2),
        ),
        _ => const MainTab(),
      },
    );
  }

  void _goToTab(int i) {
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().totalCount;
    final favsCount = context.watch<FavoritesProvider>().count;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: List.generate(5, _buildTab),
      ),
      bottomNavigationBar: _FloatingNavBar(
        index: _index,
        onTap: _goToTab,
        cartCount: cartCount,
        favsCount: favsCount,
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final int cartCount;
  final int favsCount;

  const _FloatingNavBar({
    required this.index,
    required this.onTap,
    required this.cartCount,
    required this.favsCount,
  });

  static const _items = [
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Главная'),
    (
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view,
      label: 'Каталог',
    ),
    (
      icon: Icons.favorite_border,
      activeIcon: Icons.favorite,
      label: 'Избранное',
    ),
    (
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag,
      label: 'Корзина',
    ),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: 'Профиль'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8C00).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final active = index == i;
              final badge = i == 2
                  ? favsCount
                  : i == 3
                  ? cartCount
                  : 0;

              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: active ? 16 : 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFFFF8C00).withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            active ? item.activeIcon : item.icon,
                            size: 22,
                            color: active
                                ? const Color(0xFFFF8C00)
                                : Colors.grey,
                          ),
                          if (badge > 0)
                            Positioned(
                              top: -4,
                              right: -6,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: scheme.error,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    badge > 9 ? '9+' : '$badge',
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (active) ...[
                        const SizedBox(width: 6),
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF8C00),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
