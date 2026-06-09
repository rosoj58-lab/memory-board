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
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.20);
    final sparkPaint = Paint()..color = AppColors.gold;
    final highlightPaint = Paint()..color = const Color(0xFFFFF7C2);
    final innerHighlightPaint = Paint()..color = const Color(0x59FFF7C2);
    final particlePaint = Paint()..color = const Color(0xFFEFFFFA);
    final mintParticlePaint = Paint()..color = AppColors.primary;

    canvas.drawCircle(center, w * 0.36, glowPaint);

    final spark = Path()
      ..moveTo(w * 0.50, h * 0.06)
      ..cubicTo(w * 0.55, h * 0.28, w * 0.59, h * 0.36, w * 0.74, h * 0.39)
      ..cubicTo(w * 0.92, h * 0.43, w * 0.92, h * 0.57, w * 0.73, h * 0.61)
      ..cubicTo(w * 0.59, h * 0.64, w * 0.55, h * 0.72, w * 0.50, h * 0.94)
      ..cubicTo(w * 0.45, h * 0.72, w * 0.41, h * 0.64, w * 0.27, h * 0.61)
      ..cubicTo(w * 0.08, h * 0.57, w * 0.08, h * 0.43, w * 0.26, h * 0.39)
      ..cubicTo(w * 0.41, h * 0.36, w * 0.45, h * 0.28, w * 0.50, h * 0.06)
      ..close();

    canvas.drawPath(
      spark.shift(Offset(0, h * 0.03)),
      Paint()..color = const Color(0x33201908),
    );
    canvas.drawPath(spark, sparkPaint);

    final innerSpark = Path()
      ..moveTo(w * 0.50, h * 0.24)
      ..cubicTo(w * 0.54, h * 0.40, w * 0.58, h * 0.44, w * 0.70, h * 0.50)
      ..cubicTo(w * 0.58, h * 0.56, w * 0.54, h * 0.60, w * 0.50, h * 0.76)
      ..cubicTo(w * 0.46, h * 0.60, w * 0.42, h * 0.56, w * 0.30, h * 0.50)
      ..cubicTo(w * 0.42, h * 0.44, w * 0.46, h * 0.40, w * 0.50, h * 0.24)
      ..close();
    canvas.drawPath(innerSpark, innerHighlightPaint);

    canvas.drawCircle(center, w * 0.13, highlightPaint);
    canvas.drawCircle(
      Offset(w * 0.26, h * 0.27),
      w * 0.045,
      particlePaint,
    );
    canvas.drawCircle(
      Offset(w * 0.78, h * 0.35),
      w * 0.04,
      mintParticlePaint,
    );
    canvas.drawCircle(
      Offset(w * 0.75, h * 0.78),
      w * 0.035,
      particlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
