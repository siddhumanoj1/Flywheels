import 'package:flywheels/app/app_scope.dart';
import 'package:flywheels/controllers/app_controller.dart';
import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/models/app_models.dart';
import 'package:flywheels/screens/auth/login_page.dart';
import 'package:flywheels/screens/customer/customer_home_page.dart';
import 'package:flywheels/screens/owner/owner_home_page.dart';
import 'package:flywheels/screens/shared/splash_page.dart';
import 'package:flutter/material.dart';

class FlywheelsApp extends StatefulWidget {
  const FlywheelsApp({super.key});

  @override
  State<FlywheelsApp> createState() => _FlywheelsAppState();
}

class _FlywheelsAppState extends State<FlywheelsApp> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.bootstrap();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlywheelsScope(
      controller: _controller,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FLYWHEELS AUTO',
        theme: AppTheme.light(),
        home: _FlywheelsHome(controller: _controller),
      ),
    );
  }
}

class _FlywheelsHome extends StatelessWidget {
  const _FlywheelsHome({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: controller.isBootstrapping
              ? const SplashPage()
              : controller.session == null
              ? const LoginPage()
              : controller.session!.role == UserRole.owner
              ? const OwnerHomePage()
              : const CustomerHomePage(),
        );
      },
    );
  }
}
