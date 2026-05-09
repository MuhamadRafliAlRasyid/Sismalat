// lib/services/pengambilan_service.dart
import 'api_service.dart';

class PengambilanService {
  static Future<Map<String, dynamic>> getAll({
    int page = 1,
    String? search,
  }) async {
    String url = 'pengambilan?page=$page';
    if (search != null && search.isNotEmpty) url += '&search=$search';
    return await ApiService.get(url);
  }

  static Future<Map<String, dynamic>> getById(String hashid) async {
    if (hashid.isEmpty) return {"status": false, "message": "Hashid kosong"};
    return await ApiService.get('pengambilan/$hashid');
  }

  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    return await ApiService.post('pengambilan', data);
  }

  static Future<Map<String, dynamic>> update(
    String hashid,
    Map<String, dynamic> data,
  ) async {
    return await ApiService.put('pengambilan/$hashid', data);
  }

  static Future<Map<String, dynamic>> delete(String hashid) async {
    return await ApiService.delete('pengambilan/$hashid');
  }

  // Untuk form create (ambil daftar sparepart)
  static Future<Map<String, dynamic>> getSpareparts() async {
    return await ApiService.get(
      'spareparts?per_page=100',
    ); // atau endpoint khusus jika ada
  }
}
