import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

const _activeBorderWidth = 3.0;

class AppInnerTab {
  const AppInnerTab({required this.label, required this.child});

  final String label;
  final Widget child;
}

class AppInnerTabs extends StatefulWidget {
  const AppInnerTabs({
    super.key,
    required this.tabs,
    this.currentIndex,
    this.initialIndex = 0,
    this.onChanged,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 16),
  }) : assert(tabs.length > 0);

  final List<AppInnerTab> tabs;
  final int? currentIndex;
  final int initialIndex;
  final ValueChanged<int>? onChanged;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  State<AppInnerTabs> createState() => _AppInnerTabsState();
}

class _AppInnerTabsState extends State<AppInnerTabs> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = _clampIndex(widget.currentIndex ?? widget.initialIndex);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void didUpdateWidget(covariant AppInnerTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = _clampIndex(widget.currentIndex ?? _index);
    if (nextIndex != _index) {
      _index = nextIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        _pageController.animateToPage(
          _index,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _clampIndex(int value) => value.clamp(0, widget.tabs.length - 1).toInt();

  void _select(int index) {
    final nextIndex = _clampIndex(index);
    if (nextIndex == _index) return;
    setState(() => _index = nextIndex);
    widget.onChanged?.call(nextIndex);
    _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _handlePageChanged(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    widget.onChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null || widget.trailing != null) ...[
            Row(
              children: [
                if (widget.title != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            widget.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  )
                else
                  const Spacer(),
                if (widget.trailing != null) ...[
                  const SizedBox(width: 10),
                  widget.trailing!,
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            height: 42,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var index = 0; index < widget.tabs.length; index++)
                          _InnerTabButton(
                            label: widget.tabs[index].label,
                            selected: index == _index,
                            onTap: () => _select(index),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppPalette.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.black.withValues(alpha: 0.04),
                    offset: const Offset(0, 10),
                    blurRadius: 22,
                  ),
                ],
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppPalette.red,
                  width: _activeBorderWidth,
                ),
              ),
              child: PageView(
                controller: _pageController,
                onPageChanged: _handlePageChanged,
                children: widget.tabs.map((tab) => tab.child).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InnerTabButton extends StatelessWidget {
  const _InnerTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                height: selected ? 42 : 36,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: selected ? AppPalette.red : AppPalette.soft,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  border: Border.all(
                    color: selected ? AppPalette.red : AppPalette.border,
                    width: selected ? _activeBorderWidth : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppPalette.black.withValues(alpha: 0.07),
                            offset: const Offset(0, -2),
                            blurRadius: 12,
                          ),
                        ]
                      : const [],
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? AppPalette.white : AppPalette.muted,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
              if (selected)
                const Positioned(
                  left: 1,
                  right: 1,
                  bottom: 0,
                  height: _activeBorderWidth,
                  child: ColoredBox(color: AppPalette.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
