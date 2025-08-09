import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int status;
  final String message;

  ApiException(this.status, this.message);

  @override
  String toString() => 'ApiException($status): $message';
}

dynamic _handleResponse(http.Response response) {
  final statusCode = response.statusCode;
  if (statusCode >= 200 && statusCode < 300) {
    return response.body.isEmpty ? null : jsonDecode(response.body);
  }

// Try to read a backend "message"
  String msg = 'Request failed';
  try {
    final body = jsonDecode(response.body);
    if (body is Map && body['message'] is String) {
      msg = body['message'];
    } else {
      msg = response.body.toString();
    }
  } catch (_) {
    msg = response.body.toString();
  }

  throw ApiException(statusCode, msg);
}
