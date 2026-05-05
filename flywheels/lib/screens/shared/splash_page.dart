import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/widgets/speedometer_loader.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final headlineMedium = Theme.of(context).textTheme.headlineMedium;
    final bodySmall = Theme.of(context).textTheme.bodySmall;
    final primaryMessageStyle = headlineMedium?.copyWith(
      fontSize: (headlineMedium.fontSize ?? 28) * 0.5,
    );
    final secondaryMessageStyle = bodySmall?.copyWith(
      fontSize: (bodySmall.fontSize ?? 14) * 0.5,
      color: AppPalette.muted,
    );

    return Scaffold(
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.scale(
                scale: 0.96 + (value * 0.04),
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SpeedometerLogoLoader(),
              const SizedBox(height: 24),
              Text('FLYWHEELS AUTO', style: primaryMessageStyle),
              const SizedBox(height: 8),
              Text(
                'Garage management, live service tracking, and customer care.',
                textAlign: TextAlign.center,
                style: secondaryMessageStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
