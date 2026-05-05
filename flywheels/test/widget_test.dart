import 'package:flywheels/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots into splash state', (tester) async {
    await tester.pumpWidget(const FlywheelsApp());
    expect(find.text('FLYWHEELS AUTO'), findsOneWidget);
  });
}

