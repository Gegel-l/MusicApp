import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/instrument_configurator_provider.dart';

String _formatRub(double amount) {
  final formatted = amount.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]} ',
  );
  return '$formatted ₽';
}

/// Секция конфигуратора инструмента
class ProductConfiguratorSection extends StatelessWidget {
  final Product product;

  const ProductConfiguratorSection({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cfg = context.watch<InstrumentConfiguratorProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                'Конфигуратор инструмента',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),

          // Colors
          if (product.effectiveConfiguratorColors.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Цвет / отделка',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: product.effectiveConfiguratorColors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final opt = product.effectiveConfiguratorColors[index];
                  final selected = cfg.selectedColorId == opt.id;
                  final tint = opt.resolveColor();
                  return Tooltip(
                    message: opt.label,
                    child: ChoiceChip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                      labelPadding: EdgeInsets.zero,
                      avatar: tint == null
                          ? null
                          : CircleAvatar(
                              radius: 8,
                              backgroundColor: tint,
                              child: const SizedBox.shrink(),
                            ),
                      label: Text(
                        opt.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      selected: selected,
                      showCheckmark: false,
                      onSelected: (v) {
                        if (v) {
                          cfg.selectColor(opt.id);
                        } else {
                          cfg.selectColor(null);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],

          // Accessories
          if (product.effectiveConfiguratorAccessories.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Аксессуары',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: product.effectiveConfiguratorAccessories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final a = product.effectiveConfiguratorAccessories[index];
                  final on = cfg.selectedAccessoryIds.contains(a.id);
                  final text =
                      '${a.label}${a.priceAddon > 0 ? ' (+${_formatRub(a.priceAddon)})' : ''}';
                  return Tooltip(
                    message: text,
                    child: FilterChip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                      labelPadding: EdgeInsets.zero,
                      label: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      selected: on,
                      onSelected: (_) => cfg.toggleAccessory(a.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
