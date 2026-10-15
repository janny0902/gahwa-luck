import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/app_theme.dart';

/// 한지 질감 + 은은한 전통 격자 배경.
/// [animated]면 구름이 흐르고 단풍·은행잎이 천천히 떨어진다.
/// [calm]은 글을 읽고 입력하는 화면용으로 잎을 줄이고 옅게 한다.
class HanjiBackground extends StatefulWidget {
  const HanjiBackground({
    super.key,
    required this.child,
    this.animated = true,
    this.calm = false,
  });

  final Widget child;
  final bool animated;
  final bool calm;

  @override
  State<HanjiBackground> createState() => _HanjiBackgroundState();
}

class _HanjiBackgroundState extends State<HanjiBackground>
    with SingleTickerProviderStateMixin {
  final _seconds = ValueNotifier<double>(0);
  Ticker? _ticker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final wantTicker = widget.animated && !reduceMotion;
    if (wantTicker && _ticker == null) {
      _ticker = createTicker((elapsed) {
        _seconds.value = elapsed.inMicroseconds / 1e6;
      })..start();
    } else if (!wantTicker && _ticker != null) {
      _ticker!.dispose();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const RepaintBoundary(child: CustomPaint(painter: _HanjiPainter())),
        if (widget.animated)
          RepaintBoundary(
            child: CustomPaint(painter: _DriftPainter(_seconds, leaves: false, calm: widget.calm)),
          ),
        widget.child,
        // 잎은 카드 위로 지나가야 보인다. 터치는 아래로 통과시킨다.
        if (widget.animated)
          RepaintBoundary(
            child: IgnorePointer(
              child: CustomPaint(painter: _DriftPainter(_seconds, leaves: true, calm: widget.calm)),
            ),
          ),
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

    _sun(canvas, size);
    _fiber(canvas, size);
    _lattice(canvas, size);
    _mountains(canvas, size);
    _cornerOrnament(canvas, const Offset(18, 18), false, false);
    _cornerOrnament(canvas, Offset(size.width - 18, 18), true, false);
    _cornerOrnament(canvas, Offset(18, size.height - 18), false, true);
    _cornerOrnament(canvas, Offset(size.width - 18, size.height - 18), true, true);
    _vignette(canvas, size);
  }

  /// 일월오봉도의 붉은 해를 옅게.
  void _sun(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.82, size.height * 0.16);
    final radius = size.width * 0.2;
    canvas.drawCircle(
      center,
      radius * 1.6,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.crimson.withValues(alpha: 0.10),
            AppColors.crimson.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 1.6)),
    );
    canvas.drawCircle(center, radius, Paint()..color = AppColors.crimson.withValues(alpha: 0.09));
  }

  /// 아래쪽 먹빛 산 능선 세 겹.
  void _mountains(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final layers = [
      (base: 0.80, peaks: [0.08, 0.30, 0.55, 0.78, 1.0], lift: 0.13, alpha: 0.06),
      (base: 0.86, peaks: [0.0, 0.22, 0.46, 0.70, 0.92], lift: 0.10, alpha: 0.08),
      (base: 0.93, peaks: [0.12, 0.38, 0.62, 0.88], lift: 0.07, alpha: 0.10),
    ];
    for (final layer in layers) {
      final baseY = h * layer.base;
      final path = Path()..moveTo(0, h)..lineTo(0, baseY);
      var lastX = 0.0;
      for (final p in layer.peaks) {
        final peakX = w * p;
        final midX = (lastX + peakX) / 2;
        path.quadraticBezierTo(midX, baseY, peakX, baseY - h * layer.lift * (0.6 + 0.4 * math.sin(p * 9)));
        lastX = peakX;
      }
      path.quadraticBezierTo((lastX + w) / 2, baseY, w, baseY);
      path.lineTo(w, h);
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.ink.withValues(alpha: layer.alpha),
              AppColors.ink.withValues(alpha: layer.alpha * 0.3),
            ],
          ).createShader(Rect.fromLTWH(0, baseY - h * layer.lift, w, h)),
      );
    }
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
      ..color = AppColors.crimson.withValues(alpha: 0.05)
      ..strokeWidth = 0.8;
    final gold = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.08)
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

class _Leaf {
  _Leaf(math.Random rnd)
      : x = rnd.nextDouble(),
        offset = rnd.nextDouble(),
        fallSpeed = 18 + rnd.nextDouble() * 22,
        sway = 18 + rnd.nextDouble() * 30,
        swaySpeed = 0.4 + rnd.nextDouble() * 0.6,
        phase = rnd.nextDouble() * math.pi * 2,
        spin = (rnd.nextBool() ? 1 : -1) * (0.3 + rnd.nextDouble() * 0.9),
        size = 9 + rnd.nextDouble() * 9,
        maple = rnd.nextDouble() < 0.6,
        alpha = 0.32 + rnd.nextDouble() * 0.25;

  final double x;
  final double offset;
  final double fallSpeed;
  final double sway;
  final double swaySpeed;
  final double phase;
  final double spin;
  final double size;
  final bool maple;
  final double alpha;
}

class _Cloud {
  const _Cloud(this.y, this.offset, this.speed, this.scale);
  final double y;
  final double offset;
  final double speed;
  final double scale;
}

class _DriftPainter extends CustomPainter {
  _DriftPainter(this.seconds, {required this.leaves, required this.calm})
      : super(repaint: seconds);

  final ValueNotifier<double> seconds;
  final bool leaves;
  final bool calm;

  static final _leaves = List.generate(10, (i) => _Leaf(math.Random(100 + i)));
  static const _clouds = [
    _Cloud(0.10, 0.1, 6, 1.0),
    _Cloud(0.27, 0.6, 4, 0.75),
    _Cloud(0.62, 0.35, 5, 0.85),
  ];
  static final _maplePath = _buildMaple();
  static final _ginkgoPath = _buildGinkgo();

  @override
  void paint(Canvas canvas, Size size) {
    final t = seconds.value;
    if (!leaves) {
      for (final cloud in _clouds) {
        _drawCloud(canvas, size, cloud, t);
      }
      return;
    }
    final leafPaint = Paint();
    final count = calm ? 5 : _leaves.length;
    final fade = calm ? 0.6 : 1.0;
    for (final leaf in _leaves.take(count)) {
      final travel = size.height + 80;
      final y = (leaf.offset * travel + t * leaf.fallSpeed) % travel - 40;
      final x = leaf.x * size.width + math.sin(t * leaf.swaySpeed + leaf.phase) * leaf.sway;
      // 흔들릴 때 잎이 뒤집히듯 가로 폭이 줄었다 늘었다 한다.
      final flip = math.cos(t * leaf.swaySpeed * 1.3 + leaf.phase);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * leaf.spin + leaf.phase);
      canvas.scale(leaf.size / 10 * (0.35 + 0.65 * flip.abs()), leaf.size / 10);
      leafPaint.color = (leaf.maple ? const Color(0xFFC0392B) : const Color(0xFFD9A62E))
          .withValues(alpha: leaf.alpha * fade);
      canvas.drawPath(leaf.maple ? _maplePath : _ginkgoPath, leafPaint);
      canvas.restore();
    }
  }

  void _drawCloud(Canvas canvas, Size size, _Cloud cloud, double t) {
    final width = 150 * cloud.scale;
    final span = size.width + width * 2;
    final x = (cloud.offset * span + t * cloud.speed) % span - width;
    final y = size.height * cloud.y;
    final s = cloud.scale;
    final fill = Paint()..color = Colors.white.withValues(alpha: 0.38);
    final line = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    // 전통 상운: 둥근 덩이 셋 + 아래로 말리는 꼬리.
    final path = Path()
      ..addOval(Rect.fromCircle(center: Offset(x + 40 * s, y), radius: 22 * s))
      ..addOval(Rect.fromCircle(center: Offset(x + 72 * s, y - 10 * s), radius: 28 * s))
      ..addOval(Rect.fromCircle(center: Offset(x + 106 * s, y + 2 * s), radius: 20 * s));
    canvas.drawPath(path, fill);
    canvas.drawPath(path, line);
    final tail = Path()
      ..moveTo(x + 18 * s, y + 18 * s)
      ..quadraticBezierTo(x + 70 * s, y + 30 * s, x + 128 * s, y + 18 * s)
      ..quadraticBezierTo(x + 142 * s, y + 12 * s, x + 136 * s, y + 4 * s);
    canvas.drawPath(tail, line);
  }

  static Path _buildMaple() {
    // 반지름 10 안의 다섯 갈래 단풍잎.
    final path = Path();
    const lobes = 5;
    for (var i = 0; i <= lobes * 2; i++) {
      final angle = -math.pi / 2 + i * math.pi / lobes;
      final r = i.isEven ? 10.0 : 4.2;
      final point = Offset(math.cos(angle) * r, math.sin(angle) * r);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    path.addRect(const Rect.fromLTWH(-0.6, 3, 1.2, 8));
    return path;
  }

  static Path _buildGinkgo() {
    // 부채꼴 은행잎과 짧은 꼭지.
    return Path()
      ..moveTo(0, 8)
      ..quadraticBezierTo(-11, -2, -8, -8)
      ..quadraticBezierTo(-3, -11, 0, -7)
      ..quadraticBezierTo(3, -11, 8, -8)
      ..quadraticBezierTo(11, -2, 0, 8)
      ..close()
      ..addRect(const Rect.fromLTWH(-0.6, 7, 1.2, 6));
  }

  @override
  bool shouldRepaint(covariant _DriftPainter oldDelegate) => false;
}
