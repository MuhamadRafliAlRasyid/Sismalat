import 'api_base.dart';

class AlatService {
  final ApiBase _api;

  AlatService({required String baseUrl, required String token})
    : _api = ApiBase(baseUrl: baseUrl, token: token);

  Future<Map<String, dynamic>> getAlats({
    String? search,
    String? kategoriId,
    int page = 1,
    int perPage = 10,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (search != null) params['search'] = search;
    if (kategoriId != null) params['kategori_id'] = kategoriId;
    return await _api.get('alat', queryParams: params);
  }

  Future<Map<String, dynamic>> getAlat(String hashid) async {
    return await _api.get('alat/$hashid');
  }

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

  Future<Map<String, dynamic>> deleteAlat(String hashid) async {
    return await _api.delete('alat/$hashid');
  }

  Future<Map<String, dynamic>> getTrashed() async {
    return await _api.get('alat/trashed');
  }

  Future<Map<String, dynamic>> restoreAlat(String hashid) async {
    return await _api.post('alat/$hashid/restore');
  }

  Future<Map<String, dynamic>> forceDeleteAlat(String hashid) async {
    return await _api.delete('alat/$hashid/force-delete');
  }

  Future<Map<String, dynamic>> getExpiredAlerts() async {
    return await _api.get('alat/expired-alerts');
  }

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

  Future<Map<String, dynamic>> createKalibrasi(
    String alatHashid,
    Map<String, dynamic> data,
  ) async {
    return await _api.post('alat/$alatHashid/kalibrasi', body: data);
  }
}
