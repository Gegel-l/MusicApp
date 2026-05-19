import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/instrument_configurator_provider.dart';
import '../screens/product_detail_screen.dart';

/// Оборачивает [ProductDetailScreen] в свой [InstrumentConfiguratorProvider] на время маршрута.
class ProductDetailScreenEntry extends StatelessWidget {
  const ProductDetailScreenEntry({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<InstrumentConfiguratorProvider>(
      create: (_) => InstrumentConfiguratorProvider(product),
      child: ProductDetailScreen(product: product),
    );
  }
}
