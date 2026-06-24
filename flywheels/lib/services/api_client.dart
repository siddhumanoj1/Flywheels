import 'dart:convert';

import 'package:flywheels/models/app_models.dart';
import 'package:http/http.dart' as http;

class OtpResponse {
  const OtpResponse({this.devOtp});

  final String? devOtp;
}

class CustomerAccountAlreadyExistsException implements Exception {
  const CustomerAccountAlreadyExistsException();
}

class FlywheelsApiClient {
  const FlywheelsApiClient({this.baseUrl = 'http://10.0.2.2:8080/api/v1'});

  final String baseUrl;

  Future<void> createCustomerAccount({
    required String name,
    required String phone,
    String? email,
    required bool dataSharingConsent,
    String? carNumber,
    String? model,
    String? fuelType,
    int? year,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'phone': phone,
      'dataSharingConsent': dataSharingConsent,
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
    };

    if (carNumber != null &&
        carNumber.trim().isNotEmpty &&
        model != null &&
        model.trim().isNotEmpty) {
      body['car'] = {
        'carNumber': carNumber.trim().toUpperCase(),
        'model': model.trim(),
        'fuelType': fuelType == null || fuelType.trim().isEmpty
            ? 'Petrol'
            : fuelType.trim(),
        'year': year ?? DateTime.now().year,
      };
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/customer-account'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 4));

    if (response.statusCode == 409) {
      throw const CustomerAccountAlreadyExistsException();
    }
    if (response.statusCode >= 400) {
      throw Exception('Failed to create customer account');
    }
  }

  Future<OtpResponse> requestOtp(String phone) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/request-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone}),
        )
        .timeout(const Duration(seconds: 4));

    if (response.statusCode >= 400) {
      throw Exception('Failed to request OTP');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return OtpResponse(devOtp: payload['devOtp'] as String?);
  }

  Future<AppSession?> verifyOtp(String phone, String code) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/verify-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone, 'code': code}),
        )
        .timeout(const Duration(seconds: 4));

    if (response.statusCode >= 400) {
      return null;
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final user = payload['user'] as Map<String, dynamic>;
    return AppSession(
      token: payload['token'] as String,
      user: GarageUser(
        id: user['id'] as String,
        name: user['name'] as String,
        phone: user['phone'] as String,
        role: switch (user['role'] as String) {
          'owner' => UserRole.owner,
          'masterMechanic' || 'master_mechanic' => UserRole.masterMechanic,
          'mechanic' => UserRole.mechanic,
          _ => UserRole.customer,
        },
        email: user['email'] as String?,
        dataSharingConsent:
            (user['dataSharingConsent'] as bool?) ??
            (user['data_sharing_consent'] as bool?) ??
            false,
      ),
    );
  }
}
