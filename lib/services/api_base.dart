import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiBase {
  final String baseUrl;
  final String token;

  ApiBase({required this.baseUrl, required this.token});

  Map<String, String> get headers => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  Map<String, String> get multipartHeaders => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    // 'Content-Type': 'multipart/form-data', // otomatis ditambahkan oleh http.MultipartRequest
  };

  // Utility: decode response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      final body = json.decode(response.body);
      throw ApiException(
        statusCode: response.statusCode,
        message: body['message'] ?? 'Terjadi kesalahan',
        errors: body['errors'],
      );
    }
  }

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/$endpoint',
    ).replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: headers);
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final response = await http.post(
      uri,
      headers: {...headers, 'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final response = await http.put(
      uri,
      headers: {...headers, 'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final response = await http.delete(uri, headers: headers);
    return _handleResponse(response);
  }

  Future<dynamic> multipartPost(
    String endpoint, {
    required Map<String, String> fields,
    Map<String, String>? files,
  }) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(multipartHeaders)
      ..fields.addAll(fields);

    if (files != null) {
      for (final entry in files.entries) {
        request.files.add(
          await http.MultipartFile.fromPath(entry.key, entry.value),
        );
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  Future<dynamic> multipartPut(
    String endpoint, {
    required Map<String, String> fields,
    Map<String, String>? files,
  }) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final request = http.MultipartRequest('PUT', uri)
      ..headers.addAll(multipartHeaders)
      ..fields.addAll(fields);

    if (files != null) {
      for (final entry in files.entries) {
        request.files.add(
          await http.MultipartFile.fromPath(entry.key, entry.value),
        );
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }
}

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  ApiException({this.statusCode, required this.message, this.errors});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
