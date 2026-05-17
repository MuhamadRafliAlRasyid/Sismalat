import 'api_base.dart';

class KalibrasiService {
  final ApiBase _api;

  KalibrasiService({required String baseUrl, required String token})
    : _api = ApiBase(baseUrl: baseUrl, token: token);

  Future<Map<String, dynamic>> getKalibrasis({
    String? search,
    String? alatId,
    int perPage = 10,
  }) async {
    final params = <String, String>{};
    if (search != null) params['search'] = search;
    if (alatId != null) params['alat_id'] = alatId;
    params['per_page'] = perPage.toString();
    return await _api.get('kalibrasi', queryParams: params);
  }

  Future<Map<String, dynamic>> getKalibrasi(String hashid) async {
    return await _api.get('kalibrasi/$hashid');
  }

  Future<Map<String, dynamic>> createKalibrasi(
    String alatHashid,
    Map<String, dynamic> data,
  ) async {
    return await _api.post('alat/$alatHashid/kalibrasi', body: data);
  }

  Future<Map<String, dynamic>> updateKalibrasi(
    String hashid,
    Map<String, dynamic> data,
  ) async {
    return await _api.put('kalibrasi/$hashid', body: data);
  }

  Future<Map<String, dynamic>> deleteKalibrasi(String hashid) async {
    return await _api.delete('kalibrasi/$hashid');
  }
}
