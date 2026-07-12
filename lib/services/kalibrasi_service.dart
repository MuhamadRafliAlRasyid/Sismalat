import 'api_base.dart';

class KalibrasiService {
  final ApiBase _api;

  KalibrasiService({required String baseUrl, required String token})
    : _api = ApiBase(baseUrl: baseUrl, token: token);

  /* ================= GET ALL KALIBRASI ================= */
  Future<Map<String, dynamic>> getKalibrasis({
    String? search,
    String? alatId,
    int page = 1,
    int perPage = 10,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (alatId != null && alatId.isNotEmpty) params['alat_id'] = alatId;

    print(
      '📡 [KalibrasiService] GET /kalibrasis?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}',
    );

    return await _api.get('kalibrasis', queryParams: params);
  }

  /* ================= GET KALIBRASI BY ALAT ================= */
  /// ✅ Method untuk fetch kalibrasi berdasarkan alat hashid
  /// Endpoint: GET /api/alats/{hashid}/kalibrasi
  Future<Map<String, dynamic>> getKalibrasiByAlat(String alatHashid) async {
    print('📡 [KalibrasiService] GET /alats/$alatHashid/kalibrasi');
    return await _api.get('alats/$alatHashid/kalibrasi');
  }

  /* ================= GET DETAIL KALIBRASI ================= */
  Future<Map<String, dynamic>> getKalibrasi(String hashid) async {
    print('📡 [KalibrasiService] GET /kalibrasis/$hashid');
    return await _api.get('kalibrasis/$hashid');
  }

  /* ================= CREATE KALIBRASI ================= */
  Future<Map<String, dynamic>> createKalibrasi(
    String alatHashid,
    Map<String, dynamic> data,
  ) async {
    print('📡 [KalibrasiService] POST /alats/$alatHashid/kalibrasi');
    return await _api.post('alats/$alatHashid/kalibrasi', body: data);
  }

  /* ================= UPDATE KALIBRASI ================= */
  Future<Map<String, dynamic>> updateKalibrasi(
    String hashid,
    Map<String, dynamic> data,
  ) async {
    print('📡 [KalibrasiService] PUT /kalibrasis/$hashid');
    return await _api.put('kalibrasis/$hashid', body: data);
  }

  /* ================= DELETE KALIBRASI ================= */
  Future<Map<String, dynamic>> deleteKalibrasi(String hashid) async {
    print('📡 [KalibrasiService] DELETE /kalibrasis/$hashid');
    return await _api.delete('kalibrasis/$hashid');
  }
}
