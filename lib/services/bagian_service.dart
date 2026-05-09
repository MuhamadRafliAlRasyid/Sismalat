import 'api_service.dart';

class BagianService {
  // Get All Bagian
  static Future<Map<String, dynamic>> getAll() async {
    return await ApiService.get('bagian');
  }

  // Get Detail Bagian (untuk Edit)
  static Future<Map<String, dynamic>> getById(String hashid) async {
    return await ApiService.get('bagian/$hashid');
  }

  // Create Bagian Baru
  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    return await ApiService.post('bagian', data);
  }

  // Update Bagian
  static Future<Map<String, dynamic>> update(
    String hashid,
    Map<String, dynamic> data,
  ) async {
    return await ApiService.put('bagian/$hashid', data);
  }

  // Delete Bagian
  static Future<Map<String, dynamic>> delete(String hashid) async {
    return await ApiService.delete('bagian/$hashid');
  }
}
