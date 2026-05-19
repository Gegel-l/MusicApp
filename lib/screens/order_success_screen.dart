import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class OrderSuccessScreen extends StatefulWidget {
  final int itemCount;
  final String totalAmount;
  const OrderSuccessScreen({super.key, required this.itemCount, required this.totalAmount});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with TickerProviderStateMixin {
  late final AnimationController _circleCtrl;
  late final AnimationController _checkCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _particleCtrl;

  late final Animation<double> _circleScale;
  late final Animation<double> _checkDraw;
  late final Animation<double> _textFade;
  late final Animation<double> _textSlide;

  @override
  void initState() {
    super.initState();

    _circleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _checkCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _textCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();

    _circleScale = CurvedAnimation(parent: _circleCtrl, curve: Curves.elasticOut);
    _checkDraw   = CurvedAnimation(parent: _checkCtrl,  curve: Curves.easeOutCubic);
    _textFade    = CurvedAnimation(parent: _textCtrl,   curve: Curves.easeIn);
    _textSlide   = Tween(begin: 30.0, end: 0.0)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    _circleCtrl.forward().then((_) =>
        _checkCtrl.forward().then((_) =>
            _textCtrl.forward()));

    _sendEmail();
  }

  Future<void> _sendEmail() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    try {
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': 'service_ctgu04h',
          'template_id': 'template_h2w5s5l',
          'user_id': '5JF8T2PbeyfsMwQfG',
          'accessToken': 'tKhxG7dm9dmOVoFLsEbc_',
          'template_params': {
            'to_email': email,
            'email': email,
            'name': email,
            'item_count': '${widget.itemCount}',
            'total_amount': widget.totalAmount,
          },
        }),
      );
      debugPrint('EmailJS status: ${response.statusCode}');
      debugPrint('EmailJS body: ${response.body}');
    } catch (e) {
      debugPrint('EmailJS error: $e');
    }
  }

  @override
  void dispose() {
    _circleCtrl.dispose();
    _checkCtrl.dispose();
    _textCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Particles
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              painter: _ParticlePainter(_particleCtrl.value, scheme.primary),
              size: MediaQuery.of(context).size,
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    // Animated circle + checkmark
                    ScaleTransition(
                      scale: _circleScale,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.4),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: AnimatedBuilder(
                          animation: _checkDraw,
                          builder: (_, __) => CustomPaint(
                            painter: _CheckPainter(_checkDraw.value),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Text block
                    AnimatedBuilder(
                      animation: _textCtrl,
                      builder: (_, __) => Opacity(
                        opacity: _textFade.value,
                        child: Transform.translate(
                          offset: Offset(0, _textSlide.value),
                          child: Column(
                            children: [
                              const Text(
                                'Заказ оформлен!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${widget.itemCount} ${_itemWord(widget.itemCount)} на сумму',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  widget.totalAmount,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: scheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Ожидайте доставку в течение 3–5 дней',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[600],
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 56),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: scheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: const Text(
                                    'Отлично!',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _itemWord(int n) {
    if (n % 100 >= 11 && n % 100 <= 19) return 'товаров';
    switch (n % 10) {
      case 1: return 'товар';
      case 2: case 3: case 4: return 'товара';
      default: return 'товаров';
    }
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  _CheckPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Checkmark path: two segments
    final p1 = Offset(cx - 22, cy);
    final p2 = Offset(cx - 6, cy + 16);
    final p3 = Offset(cx + 22, cy - 16);

    final totalLen = (p2 - p1).distance + (p3 - p2).distance;
    final drawn = totalLen * progress;

    final seg1 = (p2 - p1).distance;
    if (drawn <= seg1) {
      final t = drawn / seg1;
      canvas.drawLine(p1, Offset.lerp(p1, p2, t)!, paint);
    } else {
      canvas.drawLine(p1, p2, paint);
      final t = (drawn - seg1) / (p3 - p2).distance;
      canvas.drawLine(p2, Offset.lerp(p2, p3, t.clamp(0, 1))!, paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}

class _Particle {
  final double x, startY, speed, size, angle;
  final Color color;
  _Particle(this.x, this.startY, this.speed, this.size, this.angle, this.color);
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color baseColor;
  static final _rng = Random(42);
  static late final List<_Particle> _particles;
  static bool _initialized = false;

  _ParticlePainter(this.progress, this.baseColor) {
    if (!_initialized) {
      _particles = List.generate(30, (i) => _Particle(
        _rng.nextDouble(),
        _rng.nextDouble() * 0.4,
        0.3 + _rng.nextDouble() * 0.7,
        3 + _rng.nextDouble() * 5,
        _rng.nextDouble() * 2 * pi,
        [baseColor, Colors.amber, Colors.pinkAccent, Colors.lightBlueAccent][i % 4],
      ));
      _initialized = true;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final y = (p.startY + progress * p.speed) % 1.0;
      final x = p.x + sin(progress * 2 * pi + p.angle) * 0.03;
      final opacity = (1.0 - y).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.size,
        Paint()..color = p.color.withValues(alpha: opacity * 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
