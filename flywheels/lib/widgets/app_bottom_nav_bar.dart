import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/widgets/automotive_widgets.dart';
import 'package:flutter/material.dart';

class AppBottomNavItem {
  const AppBottomNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
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
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppPalette.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppPalette.border),
          boxShadow: [
            BoxShadow(
              color: AppPalette.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isActive = index == currentIndex;
            final badgeCount = index < badgeCounts.length
                ? badgeCounts[index]
                : 0;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isActive ? AppPalette.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive ? AppPalette.black : AppPalette.border,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onTap(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              isActive ? item.activeIcon : item.icon,
                              size: 21,
                              color: isActive
                                  ? AppPalette.white
                                  : AppPalette.black,
                            ),
                            if (badgeCount > 0)
                              Positioned(
                                right: -11,
                                top: -8,
                                child: _NavBadge(count: badgeCount),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isActive
                                    ? AppPalette.white
                                    : AppPalette.black,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        LedIndicator(active: isActive),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
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
            color: AppPalette.red.withValues(alpha: 0.36),
            blurRadius: 8,
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
