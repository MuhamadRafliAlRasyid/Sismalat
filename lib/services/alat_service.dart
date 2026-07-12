// lib/services/alat_service.dart
import 'api_base.dart';

class AlatService {
  final ApiBase _api;

  AlatService({required String baseUrl, required String token})
    : _api = ApiBase(baseUrl: baseUrl, token: token);

  Future<Map<String, dynamic>> getAlats({
    String? search,
    String? kategoriId,
    int page = 1,
    int perPage = 12,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (kategoriId != null) params['kategori_id'] = kategoriId;

    return await _api.get('alats', queryParams: params);
  }

  Future<Map<String, dynamic>> getAlat(String hashid) async {
    return await _api.get('alats/$hashid');
  }

  Future<Map<String, dynamic>> getCreateData() async {
    return await _api.get('alats/create');
  }

  Future<Map<String, dynamic>> getEditData(String hashid) async {
    return await _api.get('alats/$hashid/edit');
  }

  Future<Map<String, dynamic>> createAlat({
    required Map<String, String> fields,
    String? fotoPath,
  }) async {
    if (fotoPath != null) {
      return await _api.multipartPost(
        'alats',
        fields: fields,
        files: {'foto': fotoPath},
      );
    }
    return await _api.post('alats', body: fields);
  }

  Future<Map<String, dynamic>> updateAlat(
    String hashid, {
    required Map<String, String> fields,
    String? fotoPath,
  }) async {
    final endpoint = 'alats/$hashid';
    if (fotoPath != null) {
      return await _api.multipartPut(
        endpoint,
        fields: fields,
        files: {'foto': fotoPath},
      );
    }
    return await _api.put(endpoint, body: fields);
  }

  Future<Map<String, dynamic>> deleteAlat(String hashid) async {
    return await _api.delete('alats/$hashid');
  }

  Future<Map<String, dynamic>> getTrashed({int page = 1}) async {
    final params = {'page': page.toString()};
    return await _api.get('alats/trashed', queryParams: params);
  }

  Future<Map<String, dynamic>> restoreAlat(String hashid) async {
    return await _api.post('alats/$hashid/restore');
  }

  Future<Map<String, dynamic>> forceDeleteAlat(String hashid) async {
    return await _api.delete('alats/$hashid/force-delete');
  }

  Future<Map<String, dynamic>> getRiwayat(String hashid) async {
    return await _api.get('alats/$hashid/riwayat');
  }

  Future<Map<String, dynamic>> getDaftarRiwayat({
    String? search,
    String? status,
    int page = 1,
  }) async {
    final params = <String, String>{'page': page.toString()};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (status != null) params['status'] = status;

    return await _api.get('alats/daftar-riwayat', queryParams: params);
  }
}
