import 'api_service.dart';

class BarangService {
  // ==================== GET ALL BARANG ====================
  static Future<Map<String, dynamic>> getAll({
    String? search,
    int page = 1,
    int perPage = 1000, // Default besar untuk dropdown
  }) async {
    String url = 'spareparts?page=$page&per_page=$perPage';
    if (search != null && search.isNotEmpty) {
      url += '&search=$search';
    }
    return await ApiService.get(url);
  }

  // ==================== GET DETAIL BARANG ====================
  static Future<Map<String, dynamic>> getById(String hashid) async {
    if (hashid.isEmpty) {
      return {"status": false, "message": "Hashid kosong"};
    }

    final result = await ApiService.get('spareparts/$hashid');

    // Tambahkan logging untuk debug
    print(
      'DEBUG getById($hashid) => status: ${result['status']}, message: ${result['message']}',
    );

    return result;
  }

  // ==================== CREATE BARANG ====================
  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    return await ApiService.post('spareparts', data);
  }

  // ==================== UPDATE BARANG ====================
  // ==================== UPDATE BARANG ====================
  static Future<Map<String, dynamic>> update(
    String hashid,
    Map<String, dynamic> data,
  ) async {
    if (hashid.isEmpty) {
      return {"status": false, "message": "Hashid kosong"};
    }

    final result = await ApiService.put('spareparts/$hashid', data);

    print(
      'DEBUG Update Barang($hashid) => status: ${result['status']}, message: ${result['message']}',
    );

    return result;
  }

  // ==================== DELETE BARANG ====================
  static Future<Map<String, dynamic>> delete(String hashid) async {
    return await ApiService.delete('spareparts/$hashid');
  }

  // ==================== CHECK STOCK ====================
  static Future<Map<String, dynamic>> checkStock() async {
    return await ApiService.get('spareparts/check-stock');
  }

  // ==================== REGENERATE QR CODE ====================
  static Future<Map<String, dynamic>> regenerateQr(String hashid) async {
    return await ApiService.post('spareparts/$hashid/regenerate-qr', {});
  }

  // ==================== GENERATE ALL QR CODES ====================
  static Future<Map<String, dynamic>> generateAllQr() async {
    return await ApiService.get('spareparts/generate-all-qr');
  }

  // Get trashed items
  static Future<Map<String, dynamic>> getTrashed() async {
    return await ApiService.get('spareparts/trashed');
  }

  // ==================== GET BARANG BY ID OR HASHID (FLEXIBLE) ====================
  // Digunakan khusus untuk notifikasi yang kadang kirim numeric ID
  // ==================== GET BY IDENTIFIER (HASHID or NUMERIC) ====================
  static Future<Map<String, dynamic>> getByIdentifier(String identifier) async {
    if (identifier.isEmpty) {
      return {"status": false, "message": "Identifier kosong"};
    }

    print('DEBUG getByIdentifier($identifier) - mencoba sebagai hashid...');

    var result = await ApiService.get('spareparts/$identifier');

    // Jika gagal karena hashid tidak valid, coba numeric ID
    if (result['status'] == false &&
        (result['message']?.toString().contains('Hash ID tidak valid') ??
            false)) {
      print(
        'DEBUG getByIdentifier($identifier) - hashid gagal, mencoba /id/...',
      );
      result = await ApiService.get('spareparts/id/$identifier');
    }

    print(
      'DEBUG getByIdentifier($identifier) FINAL => status: ${result['status']}, message: ${result['message']}',
    );

    return result;
  }

  // Restore
  static Future<Map<String, dynamic>> restore(String hashid) async {
    return await ApiService.post('spareparts/$hashid/restore', {});
  }

  // Force Delete
  static Future<Map<String, dynamic>> forceDelete(String hashid) async {
    return await ApiService.delete('spareparts/$hashid/force-delete');
  }
}
