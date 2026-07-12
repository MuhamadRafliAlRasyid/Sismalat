import 'api_base.dart';

class KategoriService {
  final ApiBase _api;

  KategoriService({required String baseUrl, required String token})
    : _api = ApiBase(baseUrl: baseUrl, token: token);

  Future<Map<String, dynamic>> getKategoris({
    String? search,
    int page = 1,
    int perPage = 10,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (search != null) params['search'] = search;

    print(
      '📡 [KategoriService] GET /kategoris?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}',
    );

    final response = await _api.get(
      'kategoris',
      queryParams: params,
    ); // ✅ PAKAI PLURAL

    print('📡 [KategoriService] Response success: ${response['success']}');
    return response;
  }

  Future<Map<String, dynamic>> getKategori(String hashid) async {
    return await _api.get('kategoris/$hashid'); // ✅ PAKAI PLURAL
  }

  Future<Map<String, dynamic>> createKategori(Map<String, dynamic> data) async {
    return await _api.post('kategoris', body: data); // ✅ PAKAI PLURAL
  }

  Future<Map<String, dynamic>> updateKategori(
    String hashid,
    Map<String, dynamic> data,
  ) async {
    return await _api.put('kategoris/$hashid', body: data); // ✅ PAKAI PLURAL
  }

  Future<Map<String, dynamic>> deleteKategori(String hashid) async {
    return await _api.delete('kategoris/$hashid'); // ✅ PAKAI PLURAL
  }
}
