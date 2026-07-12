import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart';

class NotificationService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Map<String, String> _headers(String? token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  /* ================= GET ALL NOTIFICATIONS ================= */
  static Future<Map<String, dynamic>> getAll() async {
    try {
      final token = await _getToken();

      print('🔔 [NotificationService] Fetching notifications...');
      print('🌐 [NotificationService] URL: ${Api.baseUrl}/notifications');

      final response = await http.get(
        Uri.parse('${Api.baseUrl}/notifications'),
        headers: _headers(token),
      );

      print('🔔 [NotificationService] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // ✅ Pastikan return Map<String, dynamic>
        if (decoded is Map<String, dynamic>) {
          if (decoded['success'] == true) {
            print('✅ [NotificationService] Success');
            return decoded;
          }
        }
      }

      print('❌ [NotificationService] Failed: ${response.statusCode}');
      return <String, dynamic>{
        'success': false,
        'notifications': <Map<String, dynamic>>[],
        'unread_count': 0,
        'message': 'HTTP ${response.statusCode}',
      };
    } catch (e) {
      print('❌ [NotificationService] Error: $e');
      return <String, dynamic>{
        'success': false,
        'notifications': <Map<String, dynamic>>[],
        'unread_count': 0,
        'message': e.toString(),
      };
    }
  }

  /* ================= GET UNREAD COUNT ================= */
  static Future<int> getUnreadCount() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${Api.baseUrl}/notifications/unread-count'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['success'] == true) {
          return (decoded['count'] as int?) ?? 0;
        }
      }
      return 0;
    } catch (e) {
      print('❌ [NotificationService] getUnreadCount error: $e');
      return 0;
    }
  }

  /* ================= MARK AS READ ================= */
  static Future<bool> markAsRead(String id) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Api.baseUrl}/notifications/$id/mark-read'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded['success'] == true;
        }
      }
      return false;
    } catch (e) {
      print('❌ [NotificationService] markAsRead error: $e');
      return false;
    }
  }

  /* ================= MARK ALL AS READ ================= */
  static Future<bool> markAllAsRead() async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Api.baseUrl}/notifications/mark-all-read'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded['success'] == true;
        }
      }
      return false;
    } catch (e) {
      print('❌ [NotificationService] markAllAsRead error: $e');
      return false;
    }
  }

  /* ================= DELETE NOTIFICATION ================= */
  static Future<bool> delete(String id) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('${Api.baseUrl}/notifications/$id'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded['success'] == true;
        }
      }
      return false;
    } catch (e) {
      print('❌ [NotificationService] delete error: $e');
      return false;
    }
  }
}
