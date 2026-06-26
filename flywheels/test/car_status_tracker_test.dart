import 'package:flywheels/models/app_models.dart';
import 'package:flywheels/widgets/car_status_tracker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('garage service tracker builds with bundled status assets', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GarageServiceTracker(status: JobStatus.workInProgress),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.text('Garage Service Tracker'), findsOneWidget);
    expect(find.text('Work In Progress'), findsOneWidget);
  });
}
