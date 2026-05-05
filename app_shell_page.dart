import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_button_styles.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/theme_mode_provider.dart';
import '../../../core/widgets/premium_scaffold.dart';
import '../../../core/widgets/typewriter_button.dart';
import 'package:trainer/features/food/presentation/food_page.dart';
import 'package:trainer/features/home/presentation/home_page.dart';
import 'package:trainer/features/hub/presentation/hub_page.dart';
import 'package:trainer/features/workout/presentation/workout_page.dart';

class AppShellPage extends ConsumerStatefulWidget {
  const AppShellPage({super.key});

  @override
  ConsumerState<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends ConsumerState<AppShellPage> {
  int index = 0;

  static final List<Widget> _pages = <Widget>[
    HomePage(),
    FoodPage(),
    WorkoutPage(),
    HubPage(),
  ];

  static const List<_NavItemData> _items = <_NavItemData>[
    _NavItemData('Home', Icons.home_outlined, Icons.home, AppColors.homeRed),
    _NavItemData('Calorie In', Icons.local_dining_outlined, Icons.local_dining, AppColors.foodBlue),
    _NavItemData('Calorie Out', Icons.fitness_center_outlined, Icons.fitness_center, AppColors.workoutGreen),
    _NavItemData('Hub', Icons.hub_outlined, Icons.hub, AppColors.hubYellow),
  ];

  @override
  Widget build(BuildContext context) {
    final bool lightMode = Theme.of(context).brightness == Brightness.light;
    final colorScheme = Theme.of(context).colorScheme;
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    return PremiumScaffold(
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          height: 96,
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: AppButtonStyles.typewriterRadius,
              border: Border.all(
                color: lightMode ? AppColors.buttonOutline : Colors.white.withValues(alpha: 0.82),
                width: lightMode ? 1.5 : 1.1,
              ),
              boxShadow: lightMode
                  ? const <BoxShadow>[]
                  : <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 12),
                      ),
                    ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List<Widget>.generate(_items.length, (int itemIndex) {
                final _NavItemData item = _items[itemIndex];
                final bool selected = itemIndex == index;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TypewriterPressable(
                      onPressed: () => setState(() => index = itemIndex),
                      accentColor: item.color,
                      selected: selected,
                      filled: true,
                      backgroundColor: lightMode
                          ? null
                          : (selected ? item.color : const Color(0xFF2F3136)),
                      foregroundColor: lightMode
                          ? null
                          : (selected
                              ? AppButtonStyles.foregroundForAccent(item.color)
                              : Colors.white),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: selected
                                        ? (lightMode ? Colors.black : AppButtonStyles.foregroundForAccent(item.color))
                                        : (lightMode ? Colors.black : Colors.white),
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Icon(
                            selected ? item.selectedIcon : item.icon,
                            color: selected
                                ? (lightMode ? Colors.black : AppButtonStyles.foregroundForAccent(item.color))
                                : (lightMode ? Colors.black : Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
      child: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 72),
            child: IndexedStack(index: index, children: _pages),
          ),
          Positioned(
            top: 12,
            right: 18,
            child: SafeArea(
              bottom: false,
              child: _ThemeToggleButton(
                themeMode: themeMode,
                onToggle: () {
                  final Brightness activeBrightness = Theme.of(context).brightness;
                  final ThemeMode nextMode = switch (themeMode) {
                    ThemeMode.light => ThemeMode.dark,
                    ThemeMode.dark => ThemeMode.light,
                    ThemeMode.system => activeBrightness == Brightness.dark
                        ? ThemeMode.light
                        : ThemeMode.dark,
                  };
                  ref.read(themeModeProvider.notifier).state = nextMode;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData(this.label, this.icon, this.selectedIcon, this.color);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Color color;
}

class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton({
    required this.themeMode,
    required this.onToggle,
  });

  final ThemeMode themeMode;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final Brightness activeBrightness = Theme.of(context).brightness;

    return TypewriterPressable(
      onPressed: onToggle,
      accentColor: activeBrightness == Brightness.dark ? Colors.white : null,
      filled: true,
      backgroundColor: activeBrightness == Brightness.dark ? const Color(0xFF1F2328) : AppColors.buttonLightFill,
      foregroundColor: activeBrightness == Brightness.dark ? Colors.white : Colors.black,
      borderRadius: BorderRadius.circular(32),
      padding: const EdgeInsets.all(0),
      child: SizedBox(
        width: 48,
        height: 48,
        child: _TwoLypGlyph(
          strokeColor: activeBrightness == Brightness.dark ? Colors.white : Colors.black,
          backgroundColor: activeBrightness == Brightness.dark ? const Color(0xFF1F2328) : AppColors.buttonLightFill,
        ),
      ),
    );
  }
}

class _TwoLypGlyph extends StatelessWidget {
  const _TwoLypGlyph({
    required this.strokeColor,
    required this.backgroundColor,
  });

  final Color strokeColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 18.4,
        height: 34.1,
        child: CustomPaint(
          painter: _DiamondStemLogoPainter(
            strokeColor: strokeColor,
            backgroundColor: backgroundColor,
          ),
        ),
      ),
    );
  }
}

class _DiamondStemLogoPainter extends CustomPainter {
  const _DiamondStemLogoPainter({
    required this.strokeColor,
    required this.backgroundColor,
  });

  final Color strokeColor;
  final Color backgroundColor;

  @override
void paint(Canvas canvas, Size size) {
  final center = Offset(size.width / 2, size.height / 2);

  final Paint stemPaint = Paint()
    ..color = strokeColor
    ..style = PaintingStyle.fill;

  final Paint diamondPaint = Paint()
    ..color = strokeColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  final double diamondSize = (size.width * 0.8) - 2;
  final double innerSize = (diamondSize * 0.75) - 1;

  // 🔹 Draw STEM (perfect center)
  final stemHeight = size.height;
  final stemWidth = 1.0;

  canvas.drawRect(
    Rect.fromCenter(
      center: center,
      width: stemWidth,
      height: stemHeight,
    ),
    stemPaint,
  );

  // 🔹 Move to diamond center (slightly ABOVE center)
  final diamondCenter = Offset(center.dx, center.dy - size.height * 0.25);

  canvas.save();
  canvas.translate(diamondCenter.dx, diamondCenter.dy);
  canvas.rotate(math.pi / 4);

  // 🔹 Outer diamond
  canvas.drawRect(
    Rect.fromCenter(
      center: Offset.zero,
      width: diamondSize,
      height: diamondSize,
    ),
    diamondPaint,
  );

  // 🔹 Colored inner lines
  final half = innerSize / 2;

  final colors = [
    AppColors.foodBlue,
    AppColors.workoutGreen,
    AppColors.hubYellow,
    AppColors.homeRed,
  ];

  final points = [
    [Offset(-half, -half), Offset(half, -half)],
    [Offset(half, -half), Offset(half, half)],
    [Offset(half, half), Offset(-half, half)],
    [Offset(-half, half), Offset(-half, -half)],
  ];

  for (int i = 0; i < 4; i++) {
    final paint = Paint()
      ..color = colors[i]
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(points[i][0], points[i][1], paint);
  }

  // 🔹 Inner cutout
  canvas.restore();
}

  @override
  bool shouldRepaint(covariant _DiamondStemLogoPainter oldDelegate) =>
      oldDelegate.strokeColor != strokeColor || oldDelegate.backgroundColor != backgroundColor;
}
