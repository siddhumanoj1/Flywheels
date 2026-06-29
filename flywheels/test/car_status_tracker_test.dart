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

    await tester.pump(const Duration(seconds: 4));

    expect(tester.takeException(), isNull);
    expect(find.text('Garage Service Tracker'), findsNothing);
    expect(find.text('Work In Progress'), findsOneWidget);
  });

  testWidgets('garage service tracker replays through delivery to on-road', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: GarageServiceTracker(status: JobStatus.onRoad)),
      ),
    );

    await tester.pump(const Duration(seconds: 7));

    expect(tester.takeException(), isNull);
    expect(find.text('On-Road'), findsOneWidget);
  });
}
