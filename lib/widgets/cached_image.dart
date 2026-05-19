import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Оптимизированный виджет изображения с кэшированием
class CachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 300),
        placeholder: (context, url) => placeholder ??
            Container(
              width: width,
              height: height,
              color: scheme.primaryContainer.withValues(alpha: 0.3),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
        errorWidget: (context, url, error) => errorWidget ??
            Container(
              width: width,
              height: height,
              color: scheme.primaryContainer.withValues(alpha: 0.3),
              child: Icon(
                Icons.image_not_supported,
                color: scheme.primary,
                size: 32,
              ),
            ),
      ),
    );
  }
}
