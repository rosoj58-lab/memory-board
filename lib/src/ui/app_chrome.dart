import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const background = Color(0xFF061F22);
  static const surface = Color(0xFF103A42);
  static const surfaceAlt = Color(0xFF15535B);
  static const primary = Color(0xFF88E3D0);
  static const primaryStrong = Color(0xFF2DD4BF);
  static const success = Color(0xFF55E6A5);
  static const danger = Color(0xFFFF6B78);
  static const gold = Color(0xFFFFD86B);
  static const textSoft = Color(0xFFA9C8C4);
}

class AppBackground extends StatelessWidget {
  const AppBackground({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/magic_sparks_background.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xE8061F22),
                Color(0xC9061F22),
                Color(0x99061F22),
              ],
            ),
          ),
        ),
        CustomPaint(
          painter: const _NightSpecklePainter(),
          child: child,
        ),
      ],
    );
  }
}

class SparkMark extends StatelessWidget {
  const SparkMark({
    this.size = 36,
    this.glowing = false,
    super.key,
  });

  final double size;
  final bool glowing;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: glowing
            ? const [
                BoxShadow(
                  color: Color(0x6645E0C4),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: CustomPaint(
        size: Size.square(size),
        painter: const _SparkPainter(),
      ),
    );
  }
}

class AmbientSparkMark extends StatefulWidget {
  const AmbientSparkMark({
    this.size = 92,
    super.key,
  });

  final double size;

  @override
  State<AmbientSparkMark> createState() => _AmbientSparkMarkState();
}

class _AmbientSparkMarkState extends State<AmbientSparkMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = Curves.easeOutCubic.transform(_controller.value);
        final pulse = math.sin(progress * math.pi);
        return SizedBox.square(
          dimension: widget.size + 28,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(widget.size + 28),
                painter: _SparkHaloPainter(pulse),
              ),
              Transform.scale(
                scale: 1 + pulse * 0.035,
                child: child,
              ),
            ],
          ),
        );
      },
      child: SparkMark(size: widget.size, glowing: true),
    );
  }
}

class _SparkHaloPainter extends CustomPainter {
  const _SparkHaloPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) {
      return;
    }

    final center = size.center(Offset.zero);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.fromARGB((70 * progress).toInt(), 255, 216, 107),
          Color.fromARGB((38 * progress).toInt(), 136, 227, 208),
          const Color(0x00061F22),
        ],
        stops: const [0.0, 0.48, 1.0],
      ).createShader(Offset.zero & size);

    canvas.drawCircle(center, size.width * (0.24 + progress * 0.10), paint);
  }

  @override
  bool shouldRepaint(covariant _SparkHaloPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _NightSpecklePainter extends CustomPainter {
  const _NightSpecklePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x2259E8D4);
    final points = <Offset>[
      Offset(size.width * 0.14, size.height * 0.12),
      Offset(size.width * 0.78, size.height * 0.16),
      Offset(size.width * 0.32, size.height * 0.31),
      Offset(size.width * 0.88, size.height * 0.42),
      Offset(size.width * 0.12, size.height * 0.62),
      Offset(size.width * 0.70, size.height * 0.74),
      Offset(size.width * 0.44, size.height * 0.88),
    ];

    for (final point in points) {
      canvas.drawCircle(point, 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.50, h * 0.50);
    final glowPaint = Paint()
      ..color = const Color(0x6688E3D0)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.24);
    final outerGlowPaint = Paint()
      ..color = const Color(0x44FFD86B)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.12);
    final sparkPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFFFF7C2),
          Color(0xFFFFE873),
          Color(0xFFFFD86B),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    final highlightPaint = Paint()..color = const Color(0xFFFFF7C2);
    final innerHighlightPaint = Paint()..color = const Color(0x59FFF7C2);
    final particlePaint = Paint()..color = const Color(0xFFFFF1A6);
    final mintParticlePaint = Paint()..color = AppColors.primary;

    canvas.drawCircle(center, w * 0.42, glowPaint);
    canvas.drawCircle(center, w * 0.34, outerGlowPaint);

    final spark = Path()
      ..moveTo(w * 0.50, h * 0.04)
      ..cubicTo(w * 0.57, h * 0.27, w * 0.61, h * 0.38, w * 0.76, h * 0.42)
      ..cubicTo(w * 0.96, h * 0.47, w * 0.96, h * 0.55, w * 0.76, h * 0.60)
      ..cubicTo(w * 0.61, h * 0.64, w * 0.57, h * 0.75, w * 0.50, h * 0.96)
      ..cubicTo(w * 0.43, h * 0.75, w * 0.39, h * 0.64, w * 0.24, h * 0.60)
      ..cubicTo(w * 0.04, h * 0.55, w * 0.04, h * 0.47, w * 0.24, h * 0.42)
      ..cubicTo(w * 0.39, h * 0.38, w * 0.43, h * 0.27, w * 0.50, h * 0.04)
      ..close();

    canvas.drawPath(
      spark.shift(Offset(0, h * 0.025)),
      Paint()..color = const Color(0x25201908),
    );
    canvas.drawPath(spark, sparkPaint);

    final innerSpark = Path()
      ..moveTo(w * 0.50, h * 0.20)
      ..cubicTo(w * 0.54, h * 0.39, w * 0.60, h * 0.45, w * 0.74, h * 0.51)
      ..cubicTo(w * 0.60, h * 0.56, w * 0.54, h * 0.62, w * 0.50, h * 0.80)
      ..cubicTo(w * 0.46, h * 0.62, w * 0.40, h * 0.56, w * 0.26, h * 0.51)
      ..cubicTo(w * 0.40, h * 0.45, w * 0.46, h * 0.39, w * 0.50, h * 0.20)
      ..close();
    canvas.drawPath(innerSpark, innerHighlightPaint);

    canvas.drawCircle(center, w * 0.15, highlightPaint);
    canvas.drawCircle(
      Offset(w * 0.26, h * 0.27),
      w * 0.050,
      particlePaint,
    );
    canvas.drawCircle(
      Offset(w * 0.78, h * 0.35),
      w * 0.045,
      particlePaint,
    );
    canvas.drawCircle(
      Offset(w * 0.25, h * 0.75),
      w * 0.045,
      particlePaint,
    );
    canvas.drawCircle(
      Offset(w * 0.76, h * 0.78),
      w * 0.038,
      particlePaint,
    );
    canvas.drawCircle(
      Offset(w * 0.66, h * 0.24),
      w * 0.030,
      mintParticlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
