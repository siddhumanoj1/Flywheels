import 'dart:math' as math;

import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/widgets/brand_logo.dart';
import 'package:flutter/material.dart';

class SpeedometerLogoLoader extends StatefulWidget {
  const SpeedometerLogoLoader({super.key, this.size = 220, this.logoSize = 106});

  final double size;
  final double logoSize;

  @override
  State<SpeedometerLogoLoader> createState() => _SpeedometerLogoLoaderState();
}

class _SpeedometerLogoLoaderState extends State<SpeedometerLogoLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1180),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _SpeedometerThrobberPainter(progress: _controller.value),
            child: child,
          );
        },
        child: Center(child: BrandLogo(size: widget.logoSize)),
      ),
    );
  }
}

class _SpeedometerThrobberPainter extends CustomPainter {
  const _SpeedometerThrobberPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final eased = Curves.easeOutCubic.transform(progress);
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 15;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final startAngle = -math.pi * 1.18;
    final sweepAngle = math.pi * 1.36;
    final activeSweep = sweepAngle * (0.12 + eased * 0.84);
    final pulse = 0.5 + (math.sin(progress * math.pi) * 0.5);

    final trackPaint = Paint()
      ..color = AppPalette.soft
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;
    final glowPaint = Paint()
      ..color = AppPalette.red.withValues(alpha: 0.08 + pulse * 0.14)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 18;
    final activePaint = Paint()
      ..color = AppPalette.red
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;

    canvas.drawArc(rect, startAngle, sweepAngle, false, trackPaint);
    canvas.drawArc(rect, startAngle, activeSweep, false, glowPaint);
    canvas.drawArc(rect, startAngle, activeSweep, false, activePaint);

    final tickPaint = Paint()
      ..color = AppPalette.black.withValues(alpha: 0.42)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    const tickCount = 19;
    for (var i = 0; i < tickCount; i++) {
      final angle = startAngle + (sweepAngle * i / (tickCount - 1));
      final isMajor = i % 3 == 0;
      final outer = Offset(
        center.dx + math.cos(angle) * (radius + 2),
        center.dy + math.sin(angle) * (radius + 2),
      );
      final inner = Offset(
        center.dx + math.cos(angle) * (radius - (isMajor ? 16 : 10)),
        center.dy + math.sin(angle) * (radius - (isMajor ? 16 : 10)),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }

    final needleAngle = startAngle + activeSweep;
    final needleLength = radius * 0.86;
    final baseLength = radius * 0.13;
    final halfBaseWidth = radius * 0.035;
    final tip = Offset(
      center.dx + math.cos(needleAngle) * needleLength,
      center.dy + math.sin(needleAngle) * needleLength,
    );
    final baseCenter = Offset(
      center.dx - math.cos(needleAngle) * baseLength,
      center.dy - math.sin(needleAngle) * baseLength,
    );
    final perpendicular = Offset(
      math.cos(needleAngle + math.pi / 2),
      math.sin(needleAngle + math.pi / 2),
    );
    final needlePath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        baseCenter.dx + perpendicular.dx * halfBaseWidth,
        baseCenter.dy + perpendicular.dy * halfBaseWidth,
      )
      ..lineTo(
        baseCenter.dx - perpendicular.dx * halfBaseWidth,
        baseCenter.dy - perpendicular.dy * halfBaseWidth,
      )
      ..close();
    canvas.drawShadow(needlePath, AppPalette.red, 8, false);
    canvas.drawPath(needlePath, Paint()..color = AppPalette.red);
    canvas.drawCircle(center, 5.5, Paint()..color = AppPalette.black);
    canvas.drawCircle(center, 3, Paint()..color = AppPalette.red);
  }

  @override
  bool shouldRepaint(covariant _SpeedometerThrobberPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
