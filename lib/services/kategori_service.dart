import 'api_base.dart';

class KategoriService {
  final ApiBase _api;

  KategoriService({required String baseUrl, required String token})
    : _api = ApiBase(baseUrl: baseUrl, token: token);

  /// Daftar kategori
  Future<Map<String, dynamic>> getKategoris({
    String? search,
    int perPage = 10,
  }) async {
    final params = <String, String>{};
    if (search != null) params['search'] = search;
    params['per_page'] = perPage.toString();

    return await _api.get('kategori', queryParams: params);
  }

  /// Detail kategori
  Future<Map<String, dynamic>> getKategori(String hashid) async {
    return await _api.get('kategori/$hashid');
  }

  /// Buat kategori baru
  Future<Map<String, dynamic>> createKategori(Map<String, dynamic> data) async {
    return await _api.post('kategori', body: data);
  }

  /// Update kategori
  Future<Map<String, dynamic>> updateKategori(
    String hashid,
    Map<String, dynamic> data,
  ) async {
    return await _api.put('kategori/$hashid', body: data);
  }

  /// Hapus kategori
  Future<Map<String, dynamic>> deleteKategori(String hashid) async {
    return await _api.delete('kategori/$hashid');
  }
}
