import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import '../models/product.dart';

/// Галерея изображений товара с зумом и навигацией
class ProductImageGallery extends StatefulWidget {
  final Product product;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;

  const ProductImageGallery({
    super.key,
    required this.product,
    this.onFavoriteToggle,
    this.isFavorite = false,
  });

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  int _currentImage = 0;
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openGallery() {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, __, ___) => FullScreenGallery(
          images: widget.product.images,
          initialIndex: _currentImage,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final product = widget.product;

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: scheme.primary,
      foregroundColor: Colors.white,
      title: Text(
        product.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        if (widget.onFavoriteToggle != null)
          IconButton(
            icon: Icon(
              widget.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: widget.isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: widget.onFavoriteToggle,
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: product.images.length,
              onPageChanged: (i) => setState(() => _currentImage = i),
              itemBuilder: (_, i) {
                final img = Image.network(
                  product.images[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Container(
                          color: scheme.primaryContainer,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                  errorBuilder: (_, __, ___) => Container(
                    color: scheme.primaryContainer,
                    child: Icon(
                      Icons.image_not_supported,
                      color: scheme.primary,
                      size: 60,
                    ),
                  ),
                );
                final child = i == 0
                    ? Hero(tag: 'product-img-${product.id}', child: img)
                    : img;
                return GestureDetector(
                  onTap: _openGallery,
                  child: _ZoomableImage(child: child),
                );
              },
            ),
            // Gradient overlay for title readability
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 80,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black45, Colors.transparent],
                  ),
                ),
              ),
            ),
            if (product.tag.isNotEmpty)
              Positioned(
                bottom: 24,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    product.tag,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (product.images.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    product.images.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentImage == i ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentImage == i
                            ? scheme.primary
                            : Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Zoomable image wrapper
class _ZoomableImage extends StatefulWidget {
  final Widget child;
  const _ZoomableImage({required this.child});

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage>
    with SingleTickerProviderStateMixin {
  final _transformController = TransformationController();
  late final AnimationController _animController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        _transformController.value = _animation!.value;
      });
  }

  @override
  void dispose() {
    _transformController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onDoubleTap(TapDownDetails details) {
    final isZoomed = _transformController.value != Matrix4.identity();
    final begin = _transformController.value;
    final Matrix4 end;
    if (isZoomed) {
      end = Matrix4.identity();
    } else {
      final pos = details.localPosition;
      end = Matrix4.identity()
        ..translateByVector3(Vector3(-pos.dx * 1.5, -pos.dy * 1.5, 0.0))
        ..scaleByVector3(Vector3(2.5, 2.5, 1.0));
    }
    _animation = Matrix4Tween(begin: begin, end: end)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
        );
    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: _onDoubleTap,
      onDoubleTap: () {},
      child: InteractiveViewer(
        transformationController: _transformController,
        minScale: 1.0,
        maxScale: 4.0,
        child: widget.child,
      ),
    );
  }
}

/// Full-screen gallery view
class FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenGallery({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late int _current;
  late final PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _ctrl,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  widget.images[i],
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.image_not_supported,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 8,
                left: 8,
                right: 8,
              ),
              color: Colors.black54,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    '${_current + 1} / ${widget.images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
          // Bottom dots
          if (widget.images.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _current == i ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _current == i ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
