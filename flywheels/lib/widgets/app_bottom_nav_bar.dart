import 'dart:math' as math;

import 'package:flywheels/core/theme/app_theme.dart';
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

enum AppMatrixIcon {
  home,
  docs,
  wheels,
  chat,
  profile,
  team,
  car,
  dashboard,
  rupee,
  left,
  right;

  static AppMatrixIcon fromLabel(String label) {
    final normalized = label.trim().toLowerCase();
    if (normalized.contains('dashboard')) return AppMatrixIcon.dashboard;
    if (normalized.contains('salary') ||
        normalized.contains('rupee') ||
        normalized.contains('pay')) {
      return AppMatrixIcon.rupee;
    }
    if (normalized.contains('right') || normalized.contains('next')) {
      return AppMatrixIcon.right;
    }
    if (normalized.contains('left') ||
        normalized.contains('back') ||
        normalized.contains('previous')) {
      return AppMatrixIcon.left;
    }
    if (normalized == 'cars' || normalized.contains('car')) {
      return AppMatrixIcon.car;
    }
    if (normalized.contains('team')) return AppMatrixIcon.team;
    if (normalized.contains('wheel')) return AppMatrixIcon.wheels;
    if (normalized.contains('chat')) return AppMatrixIcon.chat;
    if (normalized.contains('doc')) return AppMatrixIcon.docs;
    if (normalized.contains('profile')) return AppMatrixIcon.profile;
    return AppMatrixIcon.home;
  }
}

class MatrixIconSurface extends StatelessWidget {
  const MatrixIconSurface({
    super.key,
    required this.type,
    this.active = true,
    this.circularClip = false,
    this.showBackground = true,
  });

  final AppMatrixIcon type;
  final bool active;
  final bool circularClip;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MatrixIconPainter(
        type: type,
        active: active,
        circularClip: circularClip,
        showBackground: showBackground,
      ),
    );
  }
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

  static const _aspectRatio = 2000 / 330;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final navWidth = math.min(availableWidth * 0.98, 1220.0);
          final navHeight = navWidth / _aspectRatio;
          final layout = _NavLayout.forCount(items.length);

          return SizedBox(
            height: navHeight,
            child: Center(
              child: SizedBox(
                width: navWidth,
                height: navHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned.fill(
                      child: CustomPaint(painter: _NavPlatePainter()),
                    ),
                    Positioned(
                      left: navWidth * 0.39,
                      bottom: navHeight * 0.08,
                      width: navWidth * 0.22,
                      height: navHeight * 0.38,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                          gradient: RadialGradient(
                            radius: 0.66,
                            colors: [Color(0xC2000000), Color(0x00000000)],
                          ),
                        ),
                      ),
                    ),
                    for (var index = 0; index < items.length; index++)
                      _PositionedNavButton(
                        index: index,
                        item: items[index],
                        layout: layout,
                        navWidth: navWidth,
                        navHeight: navHeight,
                        active: index == currentIndex,
                        badgeCount: index < badgeCounts.length
                            ? badgeCounts[index]
                            : 0,
                        onTap: () => onTap(index),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavLayout {
  const _NavLayout({
    required this.centerIndex,
    required this.positions,
    required this.cardWidth,
    required this.cardHeight,
    required this.cardTop,
    required this.centerWidth,
    required this.centerTop,
  });

  final int centerIndex;
  final List<double> positions;
  final double cardWidth;
  final double cardHeight;
  final double cardTop;
  final double centerWidth;
  final double centerTop;

  static _NavLayout forCount(int count) {
    if (count == 7) {
      return const _NavLayout(
        centerIndex: 3,
        positions: [0.10, 0.23, 0.36, 0.50, 0.64, 0.77, 0.90],
        cardWidth: 0.121,
        cardHeight: 0.7018,
        cardTop: 0.14,
        centerWidth: 0.14036,
        centerTop: -0.012,
      );
    }

    if (count == 5) {
      return const _NavLayout(
        centerIndex: 2,
        positions: [0.122, 0.293, 0.50, 0.707, 0.878],
        cardWidth: 0.13,
        cardHeight: 0.73,
        cardTop: 0.14,
        centerWidth: 0.151,
        centerTop: -0.012,
      );
    }

    final positions = List<double>.generate(
      count,
      (index) => (index + 1) / (count + 1),
    );
    return _NavLayout(
      centerIndex: count ~/ 2,
      positions: positions,
      cardWidth: math.min(0.16, 0.72 / math.max(count, 1)),
      cardHeight: 0.73,
      cardTop: 0.14,
      centerWidth: 0.151,
      centerTop: -0.012,
    );
  }
}

class _PositionedNavButton extends StatelessWidget {
  const _PositionedNavButton({
    required this.index,
    required this.item,
    required this.layout,
    required this.navWidth,
    required this.navHeight,
    required this.active,
    required this.badgeCount,
    required this.onTap,
  });

  final int index;
  final AppBottomNavItem item;
  final _NavLayout layout;
  final double navWidth;
  final double navHeight;
  final bool active;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCenter = index == layout.centerIndex;
    final width = navWidth * (isCenter ? layout.centerWidth : layout.cardWidth);
    final height = isCenter ? width : navHeight * layout.cardHeight;
    final top = navHeight * (isCenter ? layout.centerTop : layout.cardTop);
    final left = navWidth * layout.positions[index] - width / 2;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: _NavButton(
        label: item.label,
        matrixType: AppMatrixIcon.fromLabel(item.label),
        active: active,
        center: isCenter,
        badgeCount: badgeCount,
        onTap: onTap,
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.matrixType,
    required this.active,
    required this.center,
    required this.badgeCount,
    required this.onTap,
  });

  final String label;
  final AppMatrixIcon matrixType;
  final bool active;
  final bool center;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      selected: active,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final borderRadius = center
              ? BorderRadius.circular(999)
              : BorderRadius.circular(constraints.biggest.shortestSide * 0.22);

          return AnimatedScale(
            duration: const Duration(milliseconds: 80),
            curve: Curves.easeOut,
            scale: active ? 0.93 : 1,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: DecoratedBox(
                decoration: center
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF252727), Color(0xFF1D1F1F)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppPalette.black.withValues(alpha: 0.17),
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: AppPalette.black.withValues(alpha: 0.35),
                            offset: const Offset(0, 15),
                            blurRadius: 22,
                          ),
                        ],
                      )
                    : BoxDecoration(
                        borderRadius: borderRadius,
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0, 0.46, 1],
                          colors: [
                            Color(0xFF2B2D2E),
                            Color(0xFF242626),
                            Color(0xFF202222),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppPalette.black.withValues(alpha: 0.28),
                            offset: const Offset(0, 16),
                            blurRadius: 25,
                          ),
                        ],
                      ),
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: 1,
                        child: ColoredBox(
                          color: AppPalette.white.withValues(alpha: 0.06),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: center ? 3 : 1,
                        child: ColoredBox(
                          color: AppPalette.black.withValues(alpha: 0.64),
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _MatrixIconPainter(
                            type: matrixType,
                            active: active,
                            circularClip: center,
                            showBackground: true,
                          ),
                        ),
                      ),
                      if (badgeCount > 0)
                        Positioned(
                          right: center ? -1 : 5,
                          top: center ? 2 : 5,
                          child: _NavBadge(count: badgeCount),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
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
            color: AppPalette.red.withValues(alpha: 0.45),
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

class _NavPlatePainter extends CustomPainter {
  const _NavPlatePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 2000, size.height / 330);
    final path = _buildPlatePath();

    canvas.save();
    canvas.translate(0, 10);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppPalette.black.withValues(alpha: 0.34)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.restore();

    canvas.save();
    canvas.translate(0, -4);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppPalette.white.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.restore();

    canvas.drawPath(path, Paint()..color = const Color(0xFF191B1B));
    canvas.restore();
  }

  Path _buildPlatePath() {
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
  bool shouldRepaint(covariant _NavPlatePainter oldDelegate) => false;
}

class _MatrixIconPainter extends CustomPainter {
  const _MatrixIconPainter({
    required this.type,
    required this.active,
    required this.circularClip,
    required this.showBackground,
  });

  final AppMatrixIcon type;
  final bool active;
  final bool circularClip;
  final bool showBackground;

  static const _size = 24;
  static const _baseDotSize = 8.0;
  static const _baseGap = 1.0;
  static const _iconScaleBoost = 1.01;
  static const _litIconScale = 0.90;
  static const _baseGlowBlur = 25.0;
  static const _offDotColor = Color(0xFF151515);
  static const _activeDotColor = Color(0xFFFF2B2B);

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / _size;
    final cellHeight = size.height / _size;
    final dotRatio = math.min(
      0.96,
      (_baseDotSize / (_baseDotSize + _baseGap)) * _iconScaleBoost,
    );
    final dotSize = math.min(cellWidth, cellHeight) * dotRatio;
    final dotScale = dotSize / _baseDotSize;
    final radius = dotSize / 2;
    final centerOffset = size.center(Offset.zero);
    final clipRadius = size.shortestSide / 2;
    final offPaint = Paint()..color = _offDotColor;
    final onPaint = Paint()
      ..color = active ? _activeDotColor : AppPalette.white;
    final glowPaint = Paint()
      ..color = _activeDotColor.withValues(alpha: 0.72)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        _baseGlowBlur * dotScale * _litIconScale,
      );

    if (showBackground) {
      for (var y = 0; y < _size; y++) {
        for (var x = 0; x < _size; x++) {
          final center = Offset((x + 0.5) * cellWidth, (y + 0.5) * cellHeight);
          if (circularClip && (center - centerOffset).distance > clipRadius) {
            continue;
          }
          canvas.drawCircle(center, radius, offPaint);
        }
      }
    }

    // Exact 24x24 icon shape from the ZIP, drawn 10% smaller.
    // The shape formulas are not remapped or rounded, so the icon stays accurate.
    final iconWidth = size.width * _litIconScale;
    final iconHeight = size.height * _litIconScale;
    final iconLeft = (size.width - iconWidth) / 2;
    final iconTop = (size.height - iconHeight) / 2;
    final iconCellWidth = iconWidth / _size;
    final iconCellHeight = iconHeight / _size;
    final iconDotSize = math.min(iconCellWidth, iconCellHeight) * dotRatio;
    final iconRadius = iconDotSize / 2;

    for (var y = 0; y < _size; y++) {
      for (var x = 0; x < _size; x++) {
        if (!_isDotOn(x, y)) continue;

        final center = Offset(
          iconLeft + (x + 0.5) * iconCellWidth,
          iconTop + (y + 0.5) * iconCellHeight,
        );
        if (circularClip && (center - centerOffset).distance > clipRadius) {
          continue;
        }

        if (active) canvas.drawCircle(center, iconRadius, glowPaint);
        canvas.drawCircle(center, iconRadius, onPaint);
      }
    }
  }

  bool _isDotOn(int x, int y) {
    switch (type) {
      case AppMatrixIcon.home:
        final roof = y >= 3 && y <= 11 && (x - 11.5).abs() <= (y - 2);
        final base =
            y >= 12 &&
            y <= 20 &&
            x >= 5 &&
            x <= 18 &&
            !(x >= 10 && x <= 13 && y >= 15);
        return roof || base;

      case AppMatrixIcon.docs:
        final paper = x >= 5 && x <= 19 && y >= 3 && y <= 21;
        final lines = x >= 8 && x <= 16 && y >= 7 && y <= 17 && y % 3 == 1;
        return paper && !lines;

      case AppMatrixIcon.wheels:
        final distance = math.sqrt(
          math.pow(x - 11.5, 2) + math.pow(y - 11.5, 2),
        );
        final ring = distance >= 8 && distance <= 10;
        final hub = distance <= 1;
        final spokes =
            distance <= 10 &&
            ((x - 11.5).abs() <= 1 ||
                (y - 11.5).abs() <= 1 ||
                (x - y).abs() <= 1 ||
                (x + y - 23).abs() <= 1);
        return ring || hub || (spokes && distance > 2);

      case AppMatrixIcon.chat:
        final bubble = x >= 3 && x <= 20 && y >= 4 && y <= 16;
        final tail =
            x >= 6 && x <= 10 && y >= 16 && y <= 20 && (x - 6) <= (20 - y);
        final cutouts =
            y >= 9 &&
            y <= 11 &&
            ((x >= 6 && x <= 8) ||
                (x >= 10 && x <= 12) ||
                (x >= 14 && x <= 16));
        return (bubble || tail) && !cutouts;

      case AppMatrixIcon.profile:
        var head = false;
        var body = false;

        if (y == 3 || y == 11) {
          head = x >= 9 && x <= 14;
        } else if (y == 4 || y == 10) {
          head = x >= 8 && x <= 15;
        } else if (y >= 5 && y <= 9) {
          head = x >= 7 && x <= 16;
        }

        if (y == 13) {
          body = x >= 7 && x <= 16;
        } else if (y == 14) {
          body = x >= 6 && x <= 17;
        } else if (y == 15) {
          body = x >= 5 && x <= 18;
        } else if (y >= 16 && y <= 20) {
          body = x >= 4 && x <= 19;
        }

        return head || body;

      case AppMatrixIcon.team:
        if (y == 7 && x >= 11 && x <= 13) return true;
        if (y == 8 && x >= 10 && x <= 14) return true;
        if (y == 9 && x >= 10 && x <= 14) return true;
        if (y == 10 && x >= 10 && x <= 14) return true;
        if (y == 11 && x >= 11 && x <= 13) return true;
        if (y == 13 && x >= 10 && x <= 14) return true;
        if (y == 14 && x >= 9 && x <= 15) return true;
        if (y == 15 && x >= 8 && x <= 16) return true;
        if (y == 16 && x >= 8 && x <= 16) return true;
        if (y == 17 && x >= 8 && x <= 16) return true;

        if (y == 7 && x >= 5 && x <= 6) return true;
        if (y == 8 && x >= 4 && x <= 7) return true;
        if (y == 9 && x >= 4 && x <= 7) return true;
        if (y == 10 && x >= 5 && x <= 6) return true;
        if (y == 12 && x >= 4 && x <= 7) return true;
        if (y == 13 && x >= 3 && x <= 7) return true;
        if (y == 14 && x >= 3 && x <= 6) return true;
        if (y == 15 && x >= 3 && x <= 6) return true;

        if (y == 7 && x >= 18 && x <= 19) return true;
        if (y == 8 && x >= 17 && x <= 20) return true;
        if (y == 9 && x >= 17 && x <= 20) return true;
        if (y == 10 && x >= 18 && x <= 19) return true;
        if (y == 12 && x >= 17 && x <= 20) return true;
        if (y == 13 && x >= 17 && x <= 21) return true;
        if (y == 14 && x >= 18 && x <= 21) return true;
        if (y == 15 && x >= 18 && x <= 21) return true;
        return false;

      case AppMatrixIcon.car:
        final roof =
            (y == 6 && x >= 7 && x <= 16) ||
            (y == 7 && x >= 6 && x <= 17) ||
            (y == 8 && x >= 6 && x <= 17) ||
            (y == 9 && x >= 4 && x <= 19) ||
            (y == 10 && x >= 5 && x <= 18);

        final body =
            (y >= 11 && y <= 12 && x >= 4 && x <= 19) ||
            (y >= 12 && y <= 13 && x >= 3 && x <= 20) ||
            (y == 14 && x >= 8 && x <= 15) ||
            (y >= 15 && y <= 16 && x >= 3 && x <= 20) ||
            (y == 17 && x >= 3 && x <= 20);

        final leftBumper = x == 3 && y >= 12 && y <= 17;
        final rightBumper = x == 20 && y >= 12 && y <= 17;
        final leftWheel = x >= 4 && x <= 6 && y >= 15 && y <= 18;
        final rightWheel = x >= 17 && x <= 19 && y >= 15 && y <= 18;

        final window =
            (x >= 8 && x <= 15 && y >= 7 && y <= 10) ||
            (x >= 7 && x <= 16 && y >= 8 && y <= 10);

        return (roof ||
                body ||
                leftBumper ||
                rightBumper ||
                leftWheel ||
                rightWheel) &&
            !window;

      case AppMatrixIcon.dashboard:
        const rows = {
          4: [
            [9, 14],
          ],
          5: [
            [7, 16],
          ],
          6: [
            [5, 7],
            [11, 11],
            [16, 18],
          ],
          7: [
            [4, 6],
            [11, 11],
            [17, 19],
          ],
          8: [
            [3, 5],
            [11, 11],
            [18, 20],
          ],
          9: [
            [3, 4],
            [6, 6],
            [17, 17],
            [19, 20],
          ],
          10: [
            [2, 3],
            [7, 7],
            [16, 16],
            [20, 21],
          ],
          11: [
            [2, 3],
            [15, 15],
            [20, 21],
          ],
          12: [
            [2, 2],
            [14, 15],
            [21, 21],
          ],
          13: [
            [1, 2],
            [13, 14],
            [21, 22],
          ],
          14: [
            [1, 2],
            [11, 13],
            [21, 22],
          ],
          15: [
            [1, 5],
            [10, 10],
            [13, 13],
            [18, 22],
          ],
          16: [
            [1, 2],
            [10, 10],
            [13, 13],
            [21, 22],
          ],
          17: [
            [1, 2],
            [11, 12],
            [21, 22],
          ],
          18: [
            [2, 3],
            [20, 21],
          ],
          19: [
            [2, 3],
            [20, 21],
          ],
        };
        return (rows[y] ?? const <List<int>>[]).any(
          (range) => x >= range[0] && x <= range[1],
        );

      case AppMatrixIcon.rupee:
        const rows = {
          3: [
            [4, 19],
          ],
          4: [
            [4, 19],
          ],
          5: [
            [12, 15],
          ],
          6: [
            [13, 16],
          ],
          7: [
            [14, 17],
          ],
          8: [
            [4, 19],
            [14, 17],
          ],
          9: [
            [4, 19],
            [14, 17],
          ],
          10: [
            [13, 16],
          ],
          11: [
            [12, 15],
          ],
          12: [
            [7, 14],
          ],
          13: [
            [8, 12],
          ],
          14: [
            [9, 11],
          ],
          15: [
            [10, 12],
          ],
          16: [
            [11, 13],
          ],
          17: [
            [12, 14],
          ],
          18: [
            [13, 15],
          ],
          19: [
            [14, 16],
          ],
          20: [
            [15, 17],
          ],
        };
        return (rows[y] ?? const <List<int>>[]).any(
          (range) => x >= range[0] && x <= range[1],
        );

      case AppMatrixIcon.left:
        const rows = {
          4: [
            [9, 9],
          ],
          5: [
            [8, 9],
          ],
          6: [
            [7, 9],
          ],
          7: [
            [6, 9],
          ],
          8: [
            [5, 9],
          ],
          9: [
            [4, 21],
          ],
          10: [
            [3, 21],
          ],
          11: [
            [2, 21],
          ],
          12: [
            [1, 21],
          ],
          13: [
            [2, 21],
          ],
          14: [
            [3, 21],
          ],
          15: [
            [4, 21],
          ],
          16: [
            [5, 9],
          ],
          17: [
            [6, 9],
          ],
          18: [
            [7, 9],
          ],
          19: [
            [8, 9],
          ],
          20: [
            [9, 9],
          ],
        };
        return (rows[y] ?? const <List<int>>[]).any(
          (range) => x >= range[0] && x <= range[1],
        );

      case AppMatrixIcon.right:
        const rows = {
          4: [
            [14, 14],
          ],
          5: [
            [14, 15],
          ],
          6: [
            [14, 16],
          ],
          7: [
            [14, 17],
          ],
          8: [
            [14, 18],
          ],
          9: [
            [2, 19],
          ],
          10: [
            [2, 20],
          ],
          11: [
            [2, 21],
          ],
          12: [
            [2, 22],
          ],
          13: [
            [2, 21],
          ],
          14: [
            [2, 20],
          ],
          15: [
            [2, 19],
          ],
          16: [
            [14, 18],
          ],
          17: [
            [14, 17],
          ],
          18: [
            [14, 16],
          ],
          19: [
            [14, 15],
          ],
          20: [
            [14, 14],
          ],
        };
        return (rows[y] ?? const <List<int>>[]).any(
          (range) => x >= range[0] && x <= range[1],
        );
    }
  }

  @override
  bool shouldRepaint(covariant _MatrixIconPainter oldDelegate) {
    return type != oldDelegate.type ||
        active != oldDelegate.active ||
        circularClip != oldDelegate.circularClip ||
        showBackground != oldDelegate.showBackground;
  }
}
