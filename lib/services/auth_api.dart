import 'package:http/http.dart';

import 'api_service.dart';

class AuthApi {
  static Future<Map<String, dynamic>> checkStep(String mobile) async {
    return await ApiService.post('auth/check', {'mobile': mobile});
  }

  static Future<Map<String, dynamic>> login({
    required String mobile,
    required String password,
  }) async {
    return await ApiService.post('auth/login', {
      'mobile': mobile,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String mobile,
    required String password,
    required String otpCode,
    String? nid, // optional based on your UI
  }) async {
    return await ApiService.post('auth/register', {
      'name': name,
      'email': email,
      'mobile': mobile,
      'password': password,
      'confirm_password': password,
      'otp_code': otpCode,
      if (nid != null) 'nid': nid,
    });
  }
}
