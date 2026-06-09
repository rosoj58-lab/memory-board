import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const background = Color(0xFF071A1F);
  static const surface = Color(0xFF102B34);
  static const surfaceAlt = Color(0xFF173A45);
  static const primary = Color(0xFF45E0C4);
  static const primaryStrong = Color(0xFF2DD4BF);
  static const success = Color(0xFF6EE7B7);
  static const danger = Color(0xFFFF647C);
  static const gold = Color(0xFFFFD166);
  static const textSoft = Color(0xFFB8D8D8);
}

class AppBackground extends StatelessWidget {
  const AppBackground({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: CustomPaint(
        painter: const _NightSpecklePainter(),
        child: child,
      ),
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
    final center = Offset(w * 0.50, h * 0.52);
    final glowPaint = Paint()
      ..color = const Color(0x6645E0C4)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.18);
    final petalPaint = Paint()..color = const Color(0xFFE9FFFA);
    final corePaint = Paint()..color = const Color(0xFFBFFEF2);
    final accentPaint = Paint()..color = AppColors.primaryStrong;
    final shadowPaint = Paint()..color = const Color(0x332DD4BF);

    canvas.drawCircle(center, w * 0.34, glowPaint);

    final petals = <RRect>[
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.50, h * 0.27),
          width: w * 0.24,
          height: h * 0.40,
        ),
        Radius.circular(w * 0.12),
      ),
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.50, h * 0.77),
          width: w * 0.24,
          height: h * 0.40,
        ),
        Radius.circular(w * 0.12),
      ),
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.27, h * 0.52),
          width: w * 0.40,
          height: h * 0.24,
        ),
        Radius.circular(w * 0.12),
      ),
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.73, h * 0.52),
          width: w * 0.40,
          height: h * 0.24,
        ),
        Radius.circular(w * 0.12),
      ),
    ];

    for (final petal in petals) {
      canvas.drawRRect(petal.shift(Offset(0, h * 0.025)), shadowPaint);
      canvas.drawRRect(petal, petalPaint);
    }

    canvas.drawCircle(center, w * 0.13, corePaint);
    canvas.drawCircle(
      Offset(w * 0.68, h * 0.28),
      w * 0.08,
      accentPaint,
    );
    canvas.drawCircle(
      Offset(w * 0.34, h * 0.72),
      w * 0.04,
      Paint()..color = const Color(0xFF8BF6E7),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
