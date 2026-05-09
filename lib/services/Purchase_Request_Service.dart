// lib/services/purchase_request_service.dart

import 'api_service.dart';

class PurchaseRequestService {
  static Future<Map<String, dynamic>> getAll({
    int page = 1,
    String? search,
  }) async {
    String url = 'purchase-requests?page=$page';
    if (search != null && search.isNotEmpty) {
      url += '&search=$search';
    }
    return await ApiService.get(url);
  }

  static Future<Map<String, dynamic>> getById(String hashid) async {
    if (hashid.isEmpty) {
      return {"status": false, "message": "Hashid kosong"};
    }
    return await ApiService.get('purchase-requests/$hashid');
  }

  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    return await ApiService.post('purchase-requests', data);
  }

  static Future<Map<String, dynamic>> update(
    String hashid,
    Map<String, dynamic> data,
  ) async {
    return await ApiService.put('purchase-requests/$hashid', data);
  }

  static Future<Map<String, dynamic>> delete(String hashid) async {
    return await ApiService.delete('purchase-requests/$hashid');
  }

  static Future<Map<String, dynamic>> approve(String hashid) async {
    return await ApiService.post('purchase-requests/$hashid/approve', {});
  }

  static Future<Map<String, dynamic>> reject(
    String hashid,
    String notes,
  ) async {
    return await ApiService.post('purchase-requests/$hashid/reject', {
      'notes': notes,
    });
  }

  // ==================== COMPLETE (PO → Completed + Tambah Stok) ====================
  static Future<Map<String, dynamic>> complete(String hashid) async {
    if (hashid.isEmpty) {
      return {"status": false, "message": "Hashid kosong"};
    }

    try {
      final result = await ApiService.post(
        'purchase-requests/$hashid/complete',
        {}, // tidak perlu body
      );

      return result;
    } catch (e) {
      print('Complete Error: $e'); // sementara untuk debug
      return {"status": false, "message": "Gagal menyelesaikan PO"};
    }
  }

  // ==================== UTILITY ====================
  static Future<Map<String, dynamic>> getByIdentifier(String identifier) async {
    if (identifier.isEmpty) {
      return {"status": false, "message": "Identifier kosong"};
    }

    var result = await ApiService.get('spareparts/$identifier');

    // Fallback ke numeric ID jika hashid gagal
    if (result['status'] == false &&
        (result['message']?.toString().contains('Hash ID tidak valid') ??
            false)) {
      result = await ApiService.get('spareparts/id/$identifier');
    }

    return result;
  }
}
