import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    final displaySize = size * 1.2;
    return ClipRRect(
      borderRadius: BorderRadius.circular(displaySize * 0.24),
      child: Image.asset(
        'assets/branding/flywheels-logo.png',
        width: displaySize,
        height: displaySize,
        fit: BoxFit.cover,
      ),
    );
  }
}

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    this.compact = false,
    this.center = false,
    this.titleColor,
    this.subtitleColor,
  });

  final bool compact;
  final bool center;
  final Color? titleColor;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final titleStyle = compact
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.headlineMedium;
    final subtitleStyle = Theme.of(context).textTheme.bodySmall;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          'FLYWHEELS AUTO',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: titleStyle?.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Garage management, live service tracking, and customer care.',
          maxLines: compact ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: subtitleStyle?.copyWith(
            color: subtitleColor,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
