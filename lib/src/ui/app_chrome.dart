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

class SpiritMark extends StatelessWidget {
  const SpiritMark({
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
        painter: const _SpiritPainter(),
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

class _SpiritPainter extends CustomPainter {
  const _SpiritPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()..color = const Color(0xFFE9FFFA);
    final accentPaint = Paint()..color = AppColors.primaryStrong;
    final eyePaint = Paint()..color = const Color(0xFF09272E);

    final w = size.width;
    final h = size.height;
    final body = Path()
      ..moveTo(w * 0.50, h * 0.08)
      ..cubicTo(w * 0.24, h * 0.08, w * 0.14, h * 0.30, w * 0.14, h * 0.48)
      ..lineTo(w * 0.14, h * 0.78)
      ..quadraticBezierTo(w * 0.23, h * 0.70, w * 0.32, h * 0.80)
      ..quadraticBezierTo(w * 0.42, h * 0.90, w * 0.50, h * 0.78)
      ..quadraticBezierTo(w * 0.58, h * 0.90, w * 0.68, h * 0.80)
      ..quadraticBezierTo(w * 0.77, h * 0.70, w * 0.86, h * 0.78)
      ..lineTo(w * 0.86, h * 0.48)
      ..cubicTo(w * 0.86, h * 0.30, w * 0.76, h * 0.08, w * 0.50, h * 0.08)
      ..close();

    canvas.drawPath(body, bodyPaint);
    canvas.drawCircle(Offset(w * 0.36, h * 0.42), w * 0.055, eyePaint);
    canvas.drawCircle(Offset(w * 0.64, h * 0.42), w * 0.055, eyePaint);

    final smile = Path()
      ..moveTo(w * 0.40, h * 0.56)
      ..quadraticBezierTo(w * 0.50, h * 0.63, w * 0.60, h * 0.56);
    canvas.drawPath(
      smile,
      Paint()
        ..color = const Color(0xFF09272E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(Offset(w * 0.74, h * 0.24), w * 0.055, accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
