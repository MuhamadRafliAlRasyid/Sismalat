import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import 'auth_service.dart';

class ApiService {
  static Future<Map<String, dynamic>> get(String endpoint) async {
    return _request('GET', endpoint);
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    return _request('POST', endpoint, body: body);
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    return _request('PUT', endpoint, body: body);
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    return _request('DELETE', endpoint);
  }

  static Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) {
      return {
        "status": false,
        "message": "Sesi telah berakhir. Silakan login kembali.",
      };
    }

    final uri = Uri.parse("${Api.baseUrl}/$endpoint");

    try {
      final response = method == 'GET'
          ? await http.get(uri, headers: _headers(token))
          : method == 'POST'
          ? await http.post(
              uri,
              headers: _headers(token),
              body: jsonEncode(body),
            )
          : method == 'PUT'
          ? await http.put(
              uri,
              headers: _headers(token),
              body: jsonEncode(body),
            )
          : await http.delete(uri, headers: _headers(token));

      return jsonDecode(response.body);
    } catch (e) {
      return {
        "status": false,
        "message": "Gagal terhubung ke server. Periksa koneksi.",
      };
    }
  }

  static Map<String, String> _headers(String token) => {
    "Content-Type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer $token",
  };
}
