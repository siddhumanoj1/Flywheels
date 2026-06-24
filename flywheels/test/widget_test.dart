import 'package:flywheels/app/app.dart';
import 'package:flywheels/controllers/app_controller.dart';
import 'package:flywheels/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots into splash state', (tester) async {
    await tester.pumpWidget(const FlywheelsApp());
    expect(find.text('FLYWHEELS AUTO'), findsOneWidget);
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
