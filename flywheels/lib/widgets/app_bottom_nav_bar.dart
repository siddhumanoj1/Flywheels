import 'dart:math' as math;

import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/widgets/exact_icon.dart';
import 'package:flutter/material.dart';

class AppBottomNavItem {
  const AppBottomNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.color,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Color? color;
}

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.badgeCounts = const [],
  });

  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<int> badgeCounts;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(constraints.maxWidth, 1220.0);
          final height = width * 330 / 2000;

          return Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: CustomPaint(painter: _NavPlate())),
                  Positioned(
                    left: width * 0.39,
                    right: width * 0.39,
                    bottom: height * 0.08,
                    height: height * 0.38,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: RadialGradient(
                          colors: [
                            AppPalette.black.withValues(alpha: 0.46),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  ..._buildButtons(width, height),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildButtons(double width, double height) {
    if (items.isEmpty) return const [];

    final centerIndex = items.length ~/ 2;
    final cardPositions = <int, double>{0: 0.122, 1: 0.293, 3: 0.707, 4: 0.878};

    return List.generate(items.length, (index) {
      final item = items[index];
      final isCenter = index == centerIndex;
      final isActive = index == currentIndex;
      final badgeCount = index < badgeCounts.length ? badgeCounts[index] : 0;

      if (isCenter) {
        final size = width * 0.151;
        return Positioned(
          left: width * 0.5 - size / 2,
          top: height * -0.012,
          width: size,
          height: size,
          child: _NavButton(
            item: item,
            isActive: isActive,
            isCenter: true,
            badgeCount: badgeCount,
            onTap: () => onTap(index),
          ),
        );
      }

      final left =
          cardPositions[index] ?? _fallbackPosition(index, items.length);
      final cardWidth = width * 0.13;
      return Positioned(
        left: width * left - cardWidth / 2,
        top: height * 0.14,
        width: cardWidth,
        height: height * 0.73,
        child: _NavButton(
          item: item,
          isActive: isActive,
          isCenter: false,
          badgeCount: badgeCount,
          onTap: () => onTap(index),
        ),
      );
    });
  }

  double _fallbackPosition(int index, int count) {
    if (count <= 1) return 0.5;
    return 0.12 + index * (0.76 / (count - 1));
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.isActive,
    required this.isCenter,
    required this.badgeCount,
    required this.onTap,
  });

  final AppBottomNavItem item;
  final bool isActive;
  final bool isCenter;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconData = isActive ? item.activeIcon : item.icon;
    final kind = ExactIconKind.fromIconData(iconData);

    return Semantics(
      button: true,
      selected: isActive,
      label: item.label,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        scale: isActive ? 0.93 : 1,
        child: Material(
          color: Colors.transparent,
          shape: isCenter ? const CircleBorder() : null,
          child: InkWell(
            customBorder: isCenter ? const CircleBorder() : null,
            borderRadius: isCenter ? null : BorderRadius.circular(18),
            onTap: onTap,
            child: DecoratedBox(
              decoration: isCenter ? _centerDecoration : _cardDecoration,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  ExactDotMatrixIcon(
                    kind,
                    size: isCenter ? 36 : 29,
                    color: isCenter
                        ? (kind == ExactIconKind.dashboard
                              ? const Color(0xFFFF0000)
                              : kind.glowColor)
                        : kind.glowColor,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: isCenter ? 6 : 4,
                      top: isCenter ? 6 : 4,
                      child: _NavBadge(count: badgeCount),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration get _cardDecoration {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0, 0.46, 1],
        colors: [Color(0xFF2B2D2E), Color(0xFF242626), Color(0xFF202222)],
      ),
      boxShadow: [
        BoxShadow(
          color: AppPalette.white.withValues(alpha: 0.06),
          blurRadius: 0,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: AppPalette.black.withValues(alpha: 0.28),
          blurRadius: 25,
          offset: const Offset(0, 16),
        ),
      ],
    );
  }

  BoxDecoration get _centerDecoration {
    return BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF252727), Color(0xFF1D1F1F)],
      ),
      boxShadow: [
        BoxShadow(
          color: AppPalette.white.withValues(alpha: 0.07),
          blurRadius: 0,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: AppPalette.black.withValues(alpha: 0.17),
          spreadRadius: 5,
        ),
        BoxShadow(
          color: AppPalette.black.withValues(alpha: 0.35),
          blurRadius: 22,
          offset: const Offset(0, 15),
        ),
      ],
    );
  }
}

class _NavPlate extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = _platePath();
    canvas.save();
    canvas.scale(size.width / 2000, size.height / 330);

    canvas.drawPath(
      path.shift(const Offset(0, 10)),
      Paint()
        ..color = AppPalette.black.withValues(alpha: 0.34)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawPath(
      path.shift(const Offset(0, -4)),
      Paint()
        ..color = AppPalette.white.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(path, Paint()..color = const Color(0xFF191B1B));
    canvas.restore();
  }

  Path _platePath() {
    return Path()
      ..moveTo(160, 22)
      ..lineTo(700, 22)
      ..cubicTo(785, 22, 792, 117, 884, 117)
      ..cubicTo(918, 117, 922, 18, 1000, 18)
      ..cubicTo(1078, 18, 1082, 117, 1116, 117)
      ..cubicTo(1208, 117, 1215, 22, 1300, 22)
      ..lineTo(1840, 22)
      ..cubicTo(1929, 22, 1998, 92, 1998, 168)
      ..cubicTo(1998, 247, 1927, 309, 1838, 309)
      ..lineTo(162, 309)
      ..cubicTo(73, 309, 2, 247, 2, 168)
      ..cubicTo(2, 92, 71, 22, 160, 22)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _NavPlate oldDelegate) => false;
}

class _NavBadge extends StatelessWidget {
  const _NavBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppPalette.red,
        borderRadius: BorderRadius.circular(99),
        boxShadow: [
          BoxShadow(
            color: AppPalette.red.withValues(alpha: 0.55),
            blurRadius: 10,
          ),
        ],
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppPalette.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          fontSize: 10,
        ),
      ),
    );
  }
}
