import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 한지 질감 + 은은한 전통 격자 배경.
class HanjiBackground extends StatelessWidget {
  const HanjiBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const CustomPaint(painter: _HanjiPainter()),
        child,
      ],
    );
  }
}

class _HanjiPainter extends CustomPainter {
  const _HanjiPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paper = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFF7EBD8),
          AppColors.beige,
          Color(0xFFE4CDAE),
        ],
        stops: [0, 0.55, 1],
      ).createShader(rect);
    canvas.drawRect(rect, paper);

    _fiber(canvas, size);
    _lattice(canvas, size);
    _cornerOrnament(canvas, const Offset(18, 18), false, false);
    _cornerOrnament(canvas, Offset(size.width - 18, 18), true, false);
    _cornerOrnament(canvas, Offset(18, size.height - 18), false, true);
    _cornerOrnament(canvas, Offset(size.width - 18, size.height - 18), true, true);
    _vignette(canvas, size);
  }

  void _fiber(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final paint = Paint()..strokeWidth = 0.6;
    for (var i = 0; i < 90; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      paint.color = AppColors.ink.withValues(alpha: 0.025 + rnd.nextDouble() * 0.03);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + rnd.nextDouble() * 28 - 8, y + rnd.nextDouble() * 6),
        paint,
      );
    }
  }

  void _lattice(Canvas canvas, Size size) {
    const step = 46.0;
    final line = Paint()
      ..color = AppColors.crimson.withValues(alpha: 0.07)
      ..strokeWidth = 0.8;
    final gold = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var y = step; y < size.height; y += step) {
      for (var x = step; x < size.width; x += step) {
        final c = Offset(x, y);
        canvas.drawLine(c + const Offset(-8, 0), c + const Offset(8, 0), line);
        canvas.drawLine(c + const Offset(0, -8), c + const Offset(0, 8), line);
        canvas.drawCircle(c, 3.2, gold);
      }
    }
  }

  void _cornerOrnament(Canvas canvas, Offset origin, bool flipX, bool flipY) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(flipX ? -1 : 1, flipY ? -1 : 1);
    final paint = Paint()
      ..color = AppColors.crimson.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final path = Path()
      ..moveTo(0, 36)
      ..lineTo(0, 8)
      ..quadraticBezierTo(0, 0, 8, 0)
      ..lineTo(36, 0);
    canvas.drawPath(path, paint);
    canvas.drawPath(
      Path()
        ..moveTo(0, 22)
        ..lineTo(0, 10)
        ..quadraticBezierTo(0, 6, 6, 6)
        ..lineTo(22, 6),
      paint..color = AppColors.gold.withValues(alpha: 0.45),
    );
    canvas.restore();
  }

  void _vignette(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          AppColors.ink.withValues(alpha: 0.06),
        ],
        stops: const [0.62, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
