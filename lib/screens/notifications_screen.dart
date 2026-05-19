import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notifications_provider.dart';
import '../models/app_notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<AppNotification> _items;

  @override
  void initState() {
    super.initState();
    _items = context.read<NotificationsProvider>().items;
  }

  Future<bool> _confirmClear(String text) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Очистить уведомления?'),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _goBack() async {
    Navigator.of(context).pop();
    await Future.delayed(const Duration(milliseconds: 400));
    if (context.mounted) {
      context.read<NotificationsProvider>().notify();
    }
  }

  void _markRead(String id) {
    setState(() {
      _items = _items
          .map((n) => n.id == id ? n.copyWith(read: true) : n)
          .toList();
    });
    context.read<NotificationsProvider>().markRead(id, silent: true);
  }

  void _markAllRead() {
    setState(() {
      _items = _items.map((n) => n.copyWith(read: true)).toList();
    });
    context.read<NotificationsProvider>().markAllRead(silent: true);
  }

  Future<void> _remove(String id) async {
    setState(() => _items.removeWhere((n) => n.id == id));
    await context.read<NotificationsProvider>().remove(id, silent: true);
  }

  Future<void> _clearRead() async {
    final can = await _confirmClear(
      'Будут удалены только прочитанные уведомления.',
    );
    if (!can || !context.mounted) return;
    final readIds = _items.where((n) => n.read).map((n) => n.id).toList();
    setState(() => _items.removeWhere((n) => n.read));
    final provider = context.read<NotificationsProvider>();
    for (final id in readIds) {
      provider.remove(id, silent: true);
    }
    if (context.mounted) provider.notify();
  }

  Future<void> _clearAll() async {
    final can = await _confirmClear(
      'Будут удалены все уведомления без возможности восстановления.',
    );
    if (!can || !context.mounted) return;
    setState(() => _items.clear());
    context.read<NotificationsProvider>().clearAll(silent: true);
  }

  String _formatDate(int ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _goBack,
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Уведомления',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_items.isNotEmpty)
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                          ),
                          onSelected: (v) async {
                            if (v == 'mark_all_read') {
                              _markAllRead();
                            } else if (v == 'clear_read') {
                              await _clearRead();
                            } else if (v == 'clear_all') {
                              await _clearAll();
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'mark_all_read',
                              child: Text('Прочитать все'),
                            ),
                            PopupMenuItem(
                              value: 'clear_read',
                              child: Text('Очистить прочитанные'),
                            ),
                            PopupMenuItem(
                              value: 'clear_all',
                              child: Text('Очистить все'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          _items.isEmpty
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
                            Icons.notifications_none,
                            size: 64,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Нет уведомлений',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Здесь будут появляться уведомления\nо скидках и новинках',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final n = _items[index];
                      return Dismissible(
                        key: ValueKey(n.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        onDismissed: (_) => _remove(n.id),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () {
                              if (!n.read) _markRead(n.id);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: n.read
                                    ? Theme.of(context).cardColor
                                    : scheme.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: n.read
                                      ? Colors.grey.withValues(alpha: 0.2)
                                      : scheme.primary.withValues(alpha: 0.3),
                                  width: n.read ? 1 : 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: n.read
                                          ? Colors.grey.withValues(alpha: 0.1)
                                          : scheme.primary.withValues(
                                              alpha: 0.15,
                                            ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      switch (n.type) {
                                        'discount' =>
                                          Icons.local_offer_outlined,
                                        'stock' => Icons.inventory_2_outlined,
                                        _ => Icons.receipt_long_outlined,
                                      },
                                      color: n.read
                                          ? Colors.grey
                                          : scheme.primary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                n.title,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                  color: n.read
                                                      ? Colors.grey[700]
                                                      : scheme.onSurface,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              _formatDate(n.createdAt),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: scheme.onSurface
                                                    .withValues(alpha: 0.55),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          n.message,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: scheme.onSurface.withValues(
                                              alpha: 0.75,
                                            ),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!n.read) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: scheme.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: scheme.primary.withValues(
                                              alpha: 0.4,
                                            ),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }, childCount: _items.length),
                  ),
                ),
        ],
      ),
    );
  }
}
