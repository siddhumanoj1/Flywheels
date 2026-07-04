import 'package:flywheels/app/app.dart';
import 'package:flywheels/app/app_scope.dart';
import 'package:flywheels/controllers/app_controller.dart';
import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/models/app_models.dart';
import 'package:flywheels/screens/owner/owner_document_tab.dart';
import 'package:flywheels/services/api_client.dart';
import 'package:flywheels/services/demo_seed.dart';
import 'package:flywheels/widgets/speedometer_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots into splash state', (tester) async {
    await tester.pumpWidget(const FlywheelsApp());
    expect(find.byType(SpeedometerLogoLoader), findsOneWidget);
  });

  test(
    'customer registration creates customer and blocks duplicates',
    () async {
      final controller = AppController(apiClient: const _FakeApiClient());
      addTearDown(controller.dispose);

      final user = await controller.createCustomerAccount(
        name: 'New Customer',
        phone: '9999988888',
        email: 'customer@example.com',
        dataSharingConsent: true,
        carNumber: 'TS10AB1234',
        model: 'Hyundai i20',
        fuelType: 'Petrol',
        year: 2024,
        imagePath: 'custom-car.png',
      );

      expect(user, isNotNull);
      expect(user!.email, 'customer@example.com');
      expect(user.dataSharingConsent, isTrue);
      expect(controller.userByPhone('9999988888'), user);
      final cars = controller.carsForCustomer(user.id);
      expect(cars, hasLength(1));
      expect(cars.single.imageUrl, 'custom-car.png');

      expect(
        await controller.createCustomerAccount(
          name: 'Duplicate Customer',
          phone: '9999988888',
          dataSharingConsent: true,
        ),
        isNull,
      );
      expect(
        await controller.createCustomerAccount(
          name: 'Owner Collision',
          phone: '9876543210',
          dataSharingConsent: true,
        ),
        isNull,
      );
    },
  );

  testWidgets('document studio opens a receipt preview for a new customer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = AppController(apiClient: const _FakeApiClient())
      ..isBootstrapping = false
      ..session = const AppSession(
        user: DemoSeed.ownerUser,
        token: 'demo-owner-token',
      );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      FlywheelsScope(
        controller: controller,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: SizedBox.expand(child: OwnerDocumentTab()),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Receipt'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('New customer').last);
    await tester.pumpAndSettle();

    Future<void> enterField(String label, String value) async {
      final finder = find.widgetWithText(TextField, label);
      await tester.ensureVisible(finder);
      await tester.enterText(finder, value);
      await tester.pump();
    }

    await enterField('Customer name', 'Test Customer');
    await enterField('Customer phone', '9000090000');
    await enterField('Vehicle number', 'TS10ZZ9999');
    await enterField('Car model', 'Test Sedan');

    final notesField = find.byType(TextField).last;
    await tester.ensureVisible(notesField);
    await tester.enterText(notesField, 'Oil filter - 690\nLabour - 500');
    await tester.pump();

    await tester.ensureVisible(find.text('Parse Receipt'));
    await tester.tap(find.text('Parse Receipt'));
    await tester.pumpAndSettle();

    expect(find.text('Edit details'), findsOneWidget);
    final createButton = find.byIcon(Icons.description_rounded).last;
    await tester.scrollUntilVisible(
      createButton,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(find.text('Receipt preview'), findsOneWidget);
  });
}

class _FakeApiClient extends FlywheelsApiClient {
  const _FakeApiClient();

  @override
  Future<void> createCustomerAccount({
    required String name,
    required String phone,
    String? email,
    required bool dataSharingConsent,
    String? carNumber,
    String? model,
    String? fuelType,
    int? year,
  }) async {}
}
