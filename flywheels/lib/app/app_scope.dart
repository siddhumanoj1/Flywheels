import 'package:flywheels/controllers/app_controller.dart';
import 'package:flutter/widgets.dart';

class FlywheelsScope extends InheritedNotifier<AppController> {
  const FlywheelsScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FlywheelsScope>();
    assert(scope != null, 'FlywheelsScope is missing in the widget tree.');
    return scope!.notifier!;
  }

  static AppController read(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<FlywheelsScope>();
    final scope = element?.widget as FlywheelsScope?;
    assert(scope != null, 'FlywheelsScope is missing in the widget tree.');
    return scope!.notifier!;
  }
}
