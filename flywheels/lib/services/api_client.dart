import 'dart:convert';

import 'package:flywheels/models/app_models.dart';
import 'package:http/http.dart' as http;

class OtpResponse {
  const OtpResponse({this.devOtp});

  final String? devOtp;
}

class FlywheelsApiClient {
  const FlywheelsApiClient({this.baseUrl = 'http://10.0.2.2:8080/api/v1'});

  final String baseUrl;

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
        role: (user['role'] as String) == 'owner'
            ? UserRole.owner
            : UserRole.customer,
      ),
    );
  }
}
