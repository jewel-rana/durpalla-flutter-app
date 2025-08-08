import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://apigw.durpalla.com/api/v2';
  late final http.Client _client;

  ApiService({http.Client? client})
      : _client = client ?? http.Client();

  static Uri buildUri(String endpoint, [Map<String, String>? params]) {
    return Uri.parse('$baseUrl/$endpoint').replace(queryParameters: params);
  }

  Future<Map<String, dynamic>> lockItem({
    required int tripId,
    required String itemType, // "seat" | "cabin"
    required int itemId,
    required String idempotencyKey,
  }) async {
    final uri = Uri.parse('$baseUrl/cart/locks');
    final res = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-Idempotency-Key': idempotencyKey,
      },
      body: jsonEncode({
        'trip_id': tripId,
        'item_type': itemType,
        'item_id': itemId,
      }),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    if (res.statusCode == 409 || res.statusCode == 410 || res.statusCode == 423) {
      throw Exception('Item unavailable. Please pick another.');
    }

    throw Exception('Failed to lock item (${res.statusCode}).');
  }

  Future<void> releaseLock(String lockId) async {
    final uri = Uri.parse('$baseUrl/cart/locks/$lockId');
    final res = await _client.delete(uri);
    if (res.statusCode != 204) {
      // non-fatal for UI; backend might have already expired it
      throw Exception('Failed to release lock.');
    }
  }

  Future<List<Map<String, dynamic>>> fetchCart() async {
    final uri = Uri.parse('$baseUrl/cart');
    final res = await _client.get(uri);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to fetch cart.');
  }

  // simple wrappers you can reuse
  static Future<Map<String, dynamic>> post(String path, Map body,
      {Map<String, String>? headers}) async {
    final res = await http.post(Uri.parse('$baseUrl/$path'),
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json', ...?headers});
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('POST $path failed: ${res.statusCode}');
  }

  static Future<void> delete(String path) async {
    final res = await http.delete(Uri.parse('$baseUrl/$path'));
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception('DELETE $path failed: ${res.statusCode}');
    }
  }


  static Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final response = await http.get(url, headers: _headers());
    print('GET $url');
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    return _handleResponse(response);
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final response = await http.put(
      url,
      headers: _headers(),
      body: jsonEncode(data),
    );

    return _handleResponse(response);
  }

  static Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // 'Authorization': 'Bearer YOUR_TOKEN_HERE' // Add token here if needed
    };
  }

  static dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'API request failed: [${response.statusCode}] ${response.body}');
    }
  }
}