import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart';

class DashboardService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Map<String, String> _headers(String? token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  /* ================= GET ADMIN DASHBOARD STATS ================= */
  static Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${Api.baseUrl}/admin/dashboard/stats'),
        headers: _headers(token),
      );

      print('📊 [DashboardService] Admin Stats Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }

      return {
        'success': false,
        'total_alat': 0,
        'total_dipinjam': 0,
        'total_dikembalikan': 0,
      };
    } catch (e) {
      print('❌ [DashboardService] getAdminStats error: $e');
      return {
        'success': false,
        'total_alat': 0,
        'total_dipinjam': 0,
        'total_dikembalikan': 0,
      };
    }
  }

  /* ================= GET KARYAWAN DASHBOARD STATS ================= */
  static Future<Map<String, dynamic>> getKaryawanStats() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${Api.baseUrl}/karyawan/dashboard/stats'),
        headers: _headers(token),
      );

      print(
        '📊 [DashboardService] Karyawan Stats Status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }

      return {
        'success': false,
        'total_dipinjam': 0,
        'total_dikembalikan': 0,
        'alat_tersedia': 0,
        'pengambilan_terbaru': [],
        'alat_dipinjam': [],
      };
    } catch (e) {
      print('❌ [DashboardService] getKaryawanStats error: $e');
      return {
        'success': false,
        'total_dipinjam': 0,
        'total_dikembalikan': 0,
        'alat_tersedia': 0,
        'pengambilan_terbaru': [],
        'alat_dipinjam': [],
      };
    }
  }
}
