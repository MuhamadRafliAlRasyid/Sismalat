import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _tempSparepartKey = 'temp_sparepart_hashid';

  // ==================== LOGIN ====================
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("${Api.baseUrl}/login"),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode({"email": email, "password": password}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['token']);

        if (data['user'] != null) {
          await prefs.setString(
            'user_id',
            data['user']['id']?.toString() ?? '',
          );
          await prefs.setString(
            'bagian_id',
            data['user']['bagian_id']?.toString() ?? '',
          );
        }
      }

      return data;
    } catch (e) {
      return {"status": false, "message": "Gagal terhubung ke server"};
    }
  }

  // ==================== REGISTER ====================
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? role,
    int? bagianId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${Api.baseUrl}/register"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          if (role != null) "role": role,
          if (bagianId != null) "bagian_id": bagianId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data['status'] == true &&
          data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['token']);
      }

      return data;
    } catch (e) {
      return {"status": false, "message": "Gagal terhubung ke server"};
    }
  }

  // ==================== GET TOKEN ====================
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // ==================== LOGOUT ====================
  static Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      try {
        await http.post(
          Uri.parse("${Api.baseUrl}/logout"),
          headers: {
            "Accept": "application/json",
            "Authorization": "Bearer $token",
          },
        );
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ==================== GET PROFILE ====================
  static Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();
    if (token == null) {
      return {"status": false, "message": "Tidak ada token"};
    }

    try {
      final response = await http.get(
        Uri.parse("${Api.baseUrl}/profile"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      return response.statusCode == 200
          ? jsonDecode(response.body)
          : jsonDecode(response.body);
    } catch (e) {
      return {"status": false, "message": "Gagal mengambil profil"};
    }
  }

  // ==================== UPDATE PROFILE SENDIRI (User biasa) ====================
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? password,
    File? photo,
  }) async {
    final token = await getToken();
    if (token == null) return {"status": false, "message": "Tidak ada token"};

    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse("${Api.baseUrl}/profile"),
      );
      request.headers.addAll({
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      });

      request.fields['name'] = name;
      if (password != null && password.isNotEmpty)
        request.fields['password'] = password;
      if (photo != null) {
        request.files.add(
          await http.MultipartFile.fromPath('profile_photo', photo.path),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(response.body);

      print(
        '👤 UPDATE PROFILE RESPONSE: ${response.statusCode} - ${data['message']}',
      );
      return data;
    } catch (e) {
      print('❌ UPDATE PROFILE ERROR: $e');
      return {"status": false, "message": "Gagal memperbarui profil: $e"};
    }
  }

  static Future<Map<String, dynamic>> updateUser({
    required String hashid,
    required String name,
    String? email,
    String? password,
    String? role,
    int? bagianId,
    File? photo,
  }) async {
    final token = await getToken();
    if (token == null) return {"status": false, "message": "Tidak ada token"};
    if (hashid.isEmpty) return {"status": false, "message": "Hashid kosong"};

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${Api.baseUrl}/users/$hashid"),
      );

      request.fields['_method'] = 'PUT';
      request.headers.addAll({
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      });

      // PASTIKAN name selalu dikirim
      request.fields['name'] = name.trim();

      if (email != null && email.isNotEmpty) {
        request.fields['email'] = email.trim();
      }
      if (password != null && password.isNotEmpty) {
        request.fields['password'] = password.trim();
      }
      if (role != null && role.isNotEmpty) {
        request.fields['role'] = role;
      }
      if (bagianId != null) {
        request.fields['bagian_id'] = bagianId.toString();
      }

      if (photo != null) {
        request.files.add(
          await http.MultipartFile.fromPath('profile_photo', photo.path),
        );
      }

      print(
        '📤 Mengirim ke /users/$hashid | name="${name.trim()}" | fields=${request.fields}',
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(response.body);

      print(
        '🔄 UPDATE USER RESPONSE (${response.statusCode}): ${data['message'] ?? data}',
      );
      return data;
    } catch (e) {
      print('❌ UPDATE USER ERROR: $e');
      return {"status": false, "message": "Gagal update user: $e"};
    }
  }

  // ==================== GET ALL USERS (SELain ROLE ADMIN) ====================
  static Future<Map<String, dynamic>> getAllUsers({String? search}) async {
    final token = await getToken();
    if (token == null) {
      return {"status": false, "message": "Tidak ada token"};
    }

    try {
      String url = "${Api.baseUrl}/users";
      if (search != null && search.isNotEmpty) {
        url += "?search=$search";
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 ? data : data;
    } catch (e) {
      return {"status": false, "message": "Gagal mengambil daftar user: $e"};
    }
  }

  // ==================== DELETE USER ====================
  static Future<Map<String, dynamic>> deleteUser(String hashid) async {
    final token = await getToken();
    if (token == null) {
      return {"status": false, "message": "Tidak ada token"};
    }

    if (hashid.isEmpty) {
      return {"status": false, "message": "Hashid tidak boleh kosong"};
    }

    try {
      final response = await http.delete(
        Uri.parse("${Api.baseUrl}/users/$hashid"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {"status": false, "message": "Gagal menghapus user: $e"};
    }
  }

  // ==================== TEMP SPAREPART (QR Flow) ====================
  static Future<void> saveTempSparepart(String hashid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tempSparepartKey, hashid.trim());
  }

  static Future<String?> getTempSparepart() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tempSparepartKey);
  }

  static Future<void> clearTempSparepart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tempSparepartKey);
  }
}
