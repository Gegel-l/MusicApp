import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart' as auth;
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/products_provider.dart';
import '../providers/theme_provider.dart';
import '../models/product.dart';
import '../utils/routes.dart';
import '../utils/recently_viewed_service.dart';
import '../widgets/product_card.dart';
import 'admin_screen.dart';
import 'onboarding_screen.dart';
import 'orders_screen.dart';
import 'my_reviews_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onGoToCart;
  final VoidCallback? onGoToFavorites;
  const ProfileScreen({super.key, this.onGoToCart, this.onGoToFavorites});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _photoUrl;
  String? _displayName;
  bool _loadingPhoto = true;
  List<int> _recentIds = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    RecentlyViewedService.load().then((ids) => setState(() => _recentIds = ids));
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { setState(() => _loadingPhoto = false); return; }
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (mounted) {
      setState(() {
        _photoUrl = doc.data()?['photoUrl'] as String?;
        _displayName = doc.data()?['displayName'] as String?;
        _loadingPhoto = false;
      });
    }
    final count = (doc.data()?['reviewsCount'] as num?)?.toInt() ?? 0;
    if (count < 0) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'reviewsCount': 0}, SetOptions(merge: true));
    }
  }

  Future<void> _editPhoto() async {
    final controller = TextEditingController(text: _photoUrl ?? '');
    final scheme = Theme.of(context).colorScheme;

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.add_a_photo_outlined, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                const Text('Фото профиля',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            // Preview
            StatefulBuilder(builder: (_, setInner) {
              return Column(
                children: [
                  if (controller.text.isNotEmpty)
                    Center(
                      child: CircleAvatar(
                        radius: 48,
                        backgroundImage: NetworkImage(controller.text),
                        onBackgroundImageError: (_, __) {},
                        backgroundColor: scheme.primaryContainer,
                      ),
                    ),
                  if (controller.text.isNotEmpty) const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Ссылка на фото (URL)',
                      hintText: 'https://...',
                      prefixIcon: const Icon(Icons.link),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                controller.clear();
                                setInner(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setInner(() {}),
                  ),
                ],
              );
            }),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Сохранить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'photoUrl': result}, SetOptions(merge: true));

    if (mounted) setState(() => _photoUrl = result.isEmpty ? null : result);
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _displayName ?? '');
    final scheme = Theme.of(context).colorScheme;

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.badge_outlined, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                const Text('Имя пользователя',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Ваше имя',
                hintText: 'Например: Иван Иванов',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => controller.clear(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (controller.text.trim().isEmpty) return;
                      Navigator.pop(ctx, controller.text.trim());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Сохранить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'displayName': result}, SetOptions(merge: true));

    if (mounted) {
      setState(() => _displayName = result.isEmpty ? null : result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Имя сохранено'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'января', 'февраля', 'марта', 'апреля',
      'мая', 'июня', 'июля', 'августа',
      'сентября', 'октября', 'ноября', 'декабря',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  String _initials(User? user) {
    if (user?.email == null) return '?';
    return user!.email![0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final cartCount = context.watch<CartProvider>().totalCount;
    final favsCount = context.watch<FavoritesProvider>().count;
    final unreadNotifications = context.watch<NotificationsProvider>().unreadCount;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Профиль',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        ),
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.notifications_none, color: Colors.white),
                            if (unreadNotifications > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      unreadNotifications > 9 ? '9+' : '$unreadNotifications',
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
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _buildAppBarAvatar(user, scheme),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 32),

          // Avatar
          Center(
            child: Stack(
              children: [
                _loadingPhoto
                    ? CircleAvatar(
                        radius: 52,
                        backgroundColor: scheme.primaryContainer,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : GestureDetector(
                        onTap: _editPhoto,
                        child: Hero(
                          tag: 'profile-avatar',
                          child: CircleAvatar(
                            radius: 52,
                            backgroundColor: scheme.primaryContainer,
                            backgroundImage: (_photoUrl != null && _photoUrl!.isNotEmpty)
                                ? NetworkImage(_photoUrl!)
                                : null,
                            child: (_photoUrl == null || _photoUrl!.isEmpty)
                                ? Text(_initials(user),
                                    style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: scheme.primary))
                                : null,
                          ),
                        ),
                      ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _editPhoto,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2),
                      ),
                      child: const Icon(Icons.edit, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          // Display name
          GestureDetector(
            onTap: _editName,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _displayName != null && _displayName!.isNotEmpty
                      ? _displayName!
                      : 'Добавить имя',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _displayName != null && _displayName!.isNotEmpty
                        ? null
                        : scheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.edit_outlined, size: 16,
                    color: scheme.onSurface.withValues(alpha: 0.4)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              user?.email ?? 'Гость',
              style: TextStyle(fontSize: 14, color: scheme.onSurface.withValues(alpha: 0.6)),
            ),
          ),

          if (user?.metadata.creationTime != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'С нами с ${_formatDate(user!.metadata.creationTime!)}',
                  style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.4)),
                ),
              ),
            ),

          const SizedBox(height: 24),
          _StatsRow(
            cartCount: cartCount,
            favsCount: favsCount,
            uid: user?.uid,
            onCartTap: widget.onGoToCart,
            onFavsTap: widget.onGoToFavorites,
          ),
          const SizedBox(height: 24),

          // Recently viewed
          _RecentlyViewedSection(recentIds: _recentIds),

          _SectionTitle('Настройки'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Тёмная тема'),
            value: themeProvider.mode == ThemeMode.dark,
            onChanged: (_) => themeProvider.toggle(uid: user?.uid),
          ),
          const Divider(height: 1),

          _SectionTitle('Аккаунт'),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Уведомления'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (unreadNotifications > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unreadNotifications > 99 ? '99+' : '$unreadNotifications',
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('История заказов'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const OrdersScreen())),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.rate_review_outlined),
            title: const Text('Мои отзывы'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MyReviewsScreen())),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),

          if (user?.email == 'admin@mail.ru')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context, rootNavigator: true)
                    .push(slideRightRoute(const AdminScreen())),
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: const Text('Админ-панель'),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          if (user?.email == 'admin@mail.ru') const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                final cart = context.read<CartProvider>();
                final favs = context.read<FavoritesProvider>();
                await context.read<auth.AuthProvider>().logout();
                cart.clearForLogout();
                favs.clearForLogout();
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                    (_) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Выйти', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
              const SizedBox(height: 24),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarAvatar(User? user, ColorScheme scheme) {
    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      return GestureDetector(
        onTap: _editPhoto,
        child: CircleAvatar(
          radius: 16,
          backgroundImage: NetworkImage(_photoUrl!),
          onBackgroundImageError: (_, __) {},
          backgroundColor: scheme.primaryContainer,
        ),
      );
    }
    return GestureDetector(
      onTap: _editPhoto,
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.white.withValues(alpha: 0.25),
        child: Text(
          _initials(user),
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int cartCount;
  final int favsCount;
  final String? uid;
  final VoidCallback? onCartTap;
  final VoidCallback? onFavsTap;
  const _StatsRow({
    required this.cartCount,
    required this.favsCount,
    this.uid,
    this.onCartTap,
    this.onFavsTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(label: 'В корзине', value: '$cartCount',
                icon: Icons.shopping_cart_outlined, scheme: scheme, onTap: onCartTap),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(label: 'Избранное', value: '$favsCount',
                icon: Icons.favorite_border, scheme: scheme, onTap: onFavsTap),
          ),
          const SizedBox(width: 12),
          _ReviewsStatCard(uid: uid, scheme: scheme),
        ],
      ),
    );
  }
}

class _ReviewsStatCard extends StatelessWidget {
  final String? uid;
  final ColorScheme scheme;
  const _ReviewsStatCard({required this.uid, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder<DocumentSnapshot>(
        stream: uid == null
            ? null
            : FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .snapshots(),
        builder: (_, snap) {
          final data = snap.data?.data() as Map<String, dynamic>?;
          final count = (data?['reviewsCount'] as num?)?.toInt() ?? 0;
          return _StatCard(
            label: 'Отзывы',
            value: '$count',
            icon: Icons.rate_review_outlined,
            scheme: scheme,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyReviewsScreen()),
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ColorScheme scheme;
  final VoidCallback? onTap;
  const _StatCard(
      {required this.label, required this.value, required this.icon,
       required this.scheme, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: scheme.primary)),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}

class _RecentlyViewedSection extends StatelessWidget {
  final List<int> recentIds;
  const _RecentlyViewedSection({required this.recentIds});

  @override
  Widget build(BuildContext context) {
    if (recentIds.isEmpty) return const SizedBox.shrink();
    final allProducts = context.watch<ProductsProvider>().products;
    final products = recentIds
        .map((id) => allProducts.where((p) => p.id == id).firstOrNull)
        .whereType<Product>()
        .toList();
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text('Недавно смотрели',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: products.length,
            itemBuilder: (context, i) => SizedBox(
              width: 160,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ProductCard(product: products[i]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary)),
    );
  }
}
