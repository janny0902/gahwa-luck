import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum CurrencyKind { amulet, rice }

/// 부적·쌀알을 아이콘과 수량으로 보여주는 재화 배지.
class CurrencyBadge extends StatelessWidget {
  const CurrencyBadge({
    super.key,
    required this.kind,
    required this.count,
    this.selected = false,
    this.onTap,
  });

  final CurrencyKind kind;
  final int? count;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = kind == CurrencyKind.amulet ? '부적' : '쌀알';
    return Material(
      color: const Color(0xFFFFF8EE).withValues(alpha: selected ? 1 : 0.92),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: (selected ? AppColors.crimson : AppColors.gold).withValues(alpha: 0.7),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
          child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 34,
            child: CustomPaint(
              painter: kind == CurrencyKind.amulet
                  ? const _AmuletPainter()
                  : const _RicePainter(),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.1,
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                count == null ? '—' : '$count',
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.15,
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
          ),
        ),
      ),
    );
  }
}

class _AmuletPainter extends CustomPainter {
  const _AmuletPainter();

  @override
  void paint(Canvas canvas, Size size) {
    RRect paperOf(double inset) {
      return RRect.fromRectAndRadius(
        Rect.fromLTWH(4 + inset, 1 + inset, size.width - 8 - inset * 2, size.height - 2 - inset * 2),
        const Radius.circular(2),
      );
    }

    final paper = paperOf(0);
    canvas.drawRRect(paper, Paint()..color = const Color(0xFFF6D56A));
    canvas.drawRRect(
      paperOf(1.2),
      Paint()
        ..color = AppColors.crimson
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
    canvas.drawRRect(
      paperOf(3.1),
      Paint()
        ..color = AppColors.crimson.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );

    final tp = TextPainter(
      text: const TextSpan(
        text: '福',
        style: TextStyle(
          color: AppColors.crimson,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2 - 1),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RicePainter extends CustomPainter {
  const _RicePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bowl = Paint()..color = const Color(0xFF8C4A32);
    final rim = Paint()
      ..color = const Color(0xFF5C2E1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final bowlRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.72),
      width: 20,
      height: 9,
    );
    canvas.drawOval(bowlRect, bowl);
    canvas.drawOval(bowlRect, rim);

    const grains = <Offset>[
      Offset(0, -6),
      Offset(-5, -1),
      Offset(5, -2),
      Offset(-2, 2),
      Offset(3, 3),
    ];
    final grain = Paint()..color = const Color(0xFFFFF6E4);
    final edge = Paint()
      ..color = const Color(0xFFD7C4A2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    final center = Offset(size.width / 2, size.height * 0.42);
    for (final g in grains) {
      canvas.save();
      canvas.translate(center.dx + g.dx, center.dy + g.dy);
      canvas.rotate(g.dx * 0.08);
      final r = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-2.2, -4.2, 4.4, 8.4),
        const Radius.circular(3),
      );
      canvas.drawRRect(r, grain);
      canvas.drawRRect(r, edge);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
