import 'api_service.dart';

class PengembalianService {
  // Get All Pengembalian
  static Future<Map<String, dynamic>> getAll({
    String? search,
    int page = 1,
  }) async {
    String url = 'pengembalian?page=$page';
    if (search != null && search.isNotEmpty) {
      url += '&search=$search';
    }
    return await ApiService.get(url);
  }

  // Get Detail Pengembalian
  static Future<Map<String, dynamic>> getById(String hashid) async {
    return await ApiService.get('pengembalian/$hashid');
  }

  // Create Pengembalian Baru
  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    return await ApiService.post('pengembalian', data);
  }

  // Update Pengembalian
  static Future<Map<String, dynamic>> update(
    String hashid,
    Map<String, dynamic> data,
  ) async {
    return await ApiService.put('pengembalian/$hashid', data);
  }

  // Delete Pengembalian
  static Future<Map<String, dynamic>> delete(String hashid) async {
    return await ApiService.delete('pengembalian/$hashid');
  }
}
