import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/api.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _tempAlatKey =
      'temp_alat_hashid'; // ✅ GANTI dari sparepart

  // ==================== LOGIN ====================
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 [AuthService] Login attempt: $email');

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

      print('🔐 [AuthService] Status: ${response.statusCode}');
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
          await prefs.setString('user_data', jsonEncode(data['user']));
        }

        print('✅ [AuthService] Login success');
      }

      return data;
    } catch (e) {
      print('❌ [AuthService] Login error: $e');
      return {"status": false, "message": "Gagal terhubung ke server: $e"};
    }
  }

  // ==================== LOGIN DENGAN GOOGLE ====================
  static Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      print('🔵 [AuthService] Google login attempt');

      // ✅ PENTING: Pakai Web Client ID dari file JSON
      const String webClientId =
          '473082664127-tlacpc7a98nmrro96jhataj6c5i4e97s.apps.googleusercontent.com';

      // ✅ PERBAIKAN: Tambahkan BOTH clientId dan serverClientId
      // - clientId: untuk iOS (diperlukan)
      // - serverClientId: untuk Android (diperlukan)
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: webClientId, // ✅ Untuk iOS
        serverClientId: webClientId, // ✅ Untuk Android
        scopes: ['email', 'profile'],
      );

      // ✅ Sign out dulu untuk clear cache
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print('⚠️ [AuthService] Google login cancelled');
        return {
          "status": false,
          "message": "Login Google dibatalkan oleh pengguna",
        };
      }

      print('✅ [AuthService] Google user selected: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null) {
        print('❌ [AuthService] No ID token received');
        return {
          "status": false,
          "message": "Gagal mendapatkan ID token Google",
        };
      }

      // ✅ DEBUG: Decode JWT untuk cek audience
      try {
        final parts = idToken.split('.');
        if (parts.length == 3) {
          final payload = parts[1];
          final normalized = base64Url.normalize(payload);
          final decoded = utf8.decode(base64Url.decode(normalized));
          final jsonPayload = jsonDecode(decoded);
          print('🔍 [AuthService] JWT audience: ${jsonPayload['aud']}');
          print('🔍 [AuthService] JWT email: ${jsonPayload['email']}');
        }
      } catch (e) {
        print('⚠️ [AuthService] Could not decode JWT: $e');
      }

      print('📤 [AuthService] Sending ID token to Laravel...');

      // ✅ Kirim ke Laravel backend
      final response = await http
          .post(
            Uri.parse("${Api.baseUrl}/auth/google"),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode({
              "id_token": idToken,
              "access_token": accessToken,
            }),
          )
          .timeout(const Duration(seconds: 15));

      print('🔵 [AuthService] Status: ${response.statusCode}');
      print('🔵 [AuthService] Response: ${response.body}');

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
          await prefs.setString('user_data', jsonEncode(data['user']));
        }

        print('✅ [AuthService] Google login success');
      }

      return data;
    } catch (e) {
      print('❌ [AuthService] Google login error: $e');
      return {"status": false, "message": "Gagal login dengan Google: $e"};
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

    // ✅ Sign out dari Google juga
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove('user_id');
    await prefs.remove('bagian_id');
    await prefs.remove('user_data');

    print('✅ [AuthService] Logout success');
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // ✅ Simpan user data terbaru
        if (data['status'] == true && data['user'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(data['user']));
        }
        return data;
      }
      return jsonDecode(response.body);
    } catch (e) {
      return {"status": false, "message": "Gagal mengambil profil"};
    }
  }

  // ==================== UPDATE PROFILE ====================
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
      if (password != null && password.isNotEmpty) {
        request.fields['password'] = password;
      }
      if (photo != null) {
        request.files.add(
          await http.MultipartFile.fromPath('profile_photo', photo.path),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(response.body);

      print('👤 UPDATE PROFILE: ${response.statusCode} - ${data['message']}');
      return data;
    } catch (e) {
      print('❌ UPDATE PROFILE ERROR: $e');
      return {"status": false, "message": "Gagal memperbarui profil: $e"};
    }
  }

  // ==================== UPDATE USER (Admin) ====================
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

      print('📤 Mengirim ke /users/$hashid | name="${name.trim()}"');

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(response.body);

      print(
        '🔄 UPDATE USER (${response.statusCode}): ${data['message'] ?? data}',
      );
      return data;
    } catch (e) {
      print('❌ UPDATE USER ERROR: $e');
      return {"status": false, "message": "Gagal update user: $e"};
    }
  }

  // ==================== GET ALL USERS ====================
  static Future<Map<String, dynamic>> getAllUsers({String? search}) async {
    final token = await getToken();
    if (token == null) {
      return {"success": false, "message": "Tidak ada token"};
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final paginationData = data['data'];
          List usersList = [];

          if (paginationData is List) {
            usersList = paginationData;
          } else if (paginationData is Map &&
              paginationData.containsKey('data')) {
            usersList = paginationData['data'] ?? [];
          }

          return {
            "success": true,
            "data": usersList,
            "pagination": paginationData is Map ? paginationData : null,
          };
        }

        return data;
      }

      return {
        "success": false,
        "message": "Server error: ${response.statusCode}",
      };
    } catch (e) {
      return {"success": false, "message": "Gagal mengambil daftar user: $e"};
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

  // ==================== TEMP ALAT (QR Flow) ✅ BARU ====================
  static Future<void> saveTempAlat(String hashid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tempAlatKey, hashid.trim());
    print('💾 [AuthService] Temp alat saved: $hashid');
  }

  static Future<String?> getTempAlat() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tempAlatKey);
  }

  static Future<void> clearTempAlat() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tempAlatKey);
    print('🗑️ [AuthService] Temp alat cleared');
  }

  // ==================== HELPER METHODS ====================
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('user_id');
    return id != null ? int.tryParse(id) : null;
  }

  static Future<int?> getBagianId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('bagian_id');
    return id != null ? int.tryParse(id) : null;
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
