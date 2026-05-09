import 'api_base.dart';

class AlatService {
  final ApiBase _api;

  AlatService({required String baseUrl, required String token})
    : _api = ApiBase(baseUrl: baseUrl, token: token);
  String get baseUrl => _api.baseUrl;

  /// List alat dengan pagination
  Future<Map<String, dynamic>> getAlats({
    String? search,
    String? kategoriId,
    int perPage = 12,
    int page = 1,
  }) async {
    final params = <String, String>{};
    if (search != null) params['search'] = search;
    if (kategoriId != null) params['kategori_id'] = kategoriId;
    params['per_page'] = perPage.toString();
    params['page'] = page.toString();

    return await _api.get('alat', queryParams: params);
  }

  /// Detail alat
  Future<Map<String, dynamic>> getAlat(String hashid) async {
    return await _api.get('alat/$hashid');
  }

  /// Buat alat baru (dengan foto opsional)
  Future<Map<String, dynamic>> createAlat({
    required Map<String, String> fields,
    String? fotoPath,
  }) async {
    if (fotoPath != null) {
      return await _api.multipartPost(
        'alat',
        fields: fields,
        files: {'foto': fotoPath},
      );
    }
    return await _api.post('alat', body: fields);
  }

  /// Update alat
  Future<Map<String, dynamic>> updateAlat(
    String hashid, {
    required Map<String, String> fields,
    String? fotoPath,
  }) async {
    final endpoint = 'alat/$hashid';
    if (fotoPath != null) {
      return await _api.multipartPut(
        endpoint,
        fields: fields,
        files: {'foto': fotoPath},
      );
    }
    return await _api.put(endpoint, body: fields);
  }

  /// Soft delete alat
  Future<Map<String, dynamic>> deleteAlat(String hashid) async {
    return await _api.delete('alat/$hashid');
  }

  /// Daftar alat yang dihapus (sampah)
  Future<Map<String, dynamic>> getTrashed() async {
    return await _api.get('alat/trashed');
  }

  /// Pulihkan alat dari sampah
  Future<Map<String, dynamic>> restoreAlat(String hashid) async {
    return await _api.post('alat/$hashid/restore');
  }

  /// Hapus permanen
  Future<Map<String, dynamic>> forceDeleteAlat(String hashid) async {
    return await _api.delete('alat/$hashid/force-delete');
  }

  /// Alat kadaluarsa / warning
  Future<Map<String, dynamic>> getExpiredAlerts() async {
    return await _api.get('alat/expired-alerts');
  }

  /// List kalibrasi milik alat tertentu
  Future<Map<String, dynamic>> getKalibrasiByAlat(
    String alatHashid, {
    String? search,
    int perPage = 10,
  }) async {
    final params = <String, String>{};
    if (search != null) params['search'] = search;
    params['per_page'] = perPage.toString();

    return await _api.get('alat/$alatHashid/kalibrasi', queryParams: params);
  }

  /// Tambah kalibrasi ke alat
  Future<Map<String, dynamic>> createKalibrasi(
    String alatHashid,
    Map<String, dynamic> data,
  ) async {
    return await _api.post('alat/$alatHashid/kalibrasi', body: data);
  }
}
