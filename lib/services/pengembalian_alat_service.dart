import 'api_base.dart';

class PengembalianAlatService {
  final ApiBase _api;

  PengembalianAlatService({required String baseUrl, required String token})
    : _api = ApiBase(baseUrl: baseUrl, token: token);

  /* ================= GET ALL ================= */
  Future<Map<String, dynamic>> getPengembalian({
    String? search,
    String? tanggal,
    int page = 1,
    int perPage = 10,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (tanggal != null && tanggal.isNotEmpty) params['tanggal'] = tanggal;

    print(
      '📡 [PengembalianService] GET /pengembalian_alat?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}',
    );

    return await _api.get('pengembalian_alat', queryParams: params);
  }

  /* ================= GET BY ALAT ================= */
  Future<Map<String, dynamic>> getPengembalianByAlat(
    String alatHashid, {
    int page = 1,
    int perPage = 50,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    print(
      '📡 [PengembalianService] GET /pengembalian_alat/by-alat/$alatHashid',
    );

    return await _api.get(
      'pengembalian_alat/by-alat/$alatHashid',
      queryParams: params,
    );
  }

  /* ================= GET DETAIL ================= */
  Future<Map<String, dynamic>> getDetail(String hashid) async {
    print('📡 [PengembalianService] GET /pengembalian_alat/$hashid');
    return await _api.get('pengembalian_alat/$hashid');
  }

  /* ================= GET CREATE DATA ================= */
  Future<Map<String, dynamic>> getCreateData(String pengambilanHashid) async {
    print(
      '📡 [PengembalianService] GET /pengembalian_alat/create/$pengambilanHashid',
    );
    return await _api.get('pengembalian_alat/create/$pengambilanHashid');
  }

  /* ================= GET EDIT DATA ================= */
  Future<Map<String, dynamic>> getEditData(String hashid) async {
    print('📡 [PengembalianService] GET /pengembalian_alat/$hashid/edit');
    return await _api.get('pengembalian_alat/$hashid/edit');
  }

  /* ================= CREATE ================= */
  Future<Map<String, dynamic>> create(
    String pengambilanHashid, {
    required String tanggalPengembalian,
    String? keterangan,
    String? fotoPath,
  }) async {
    final fields = <String, String>{
      'tanggal_pengembalian': tanggalPengembalian,
    };
    if (keterangan != null && keterangan.isNotEmpty) {
      fields['keterangan'] = keterangan;
    }

    final endpoint = 'pengembalian_alat/$pengambilanHashid';

    print('📡 [PengembalianService] POST /$endpoint');
    print('📦 Fields: $fields');
    print('📷 Has foto: ${fotoPath != null}');

    if (fotoPath != null) {
      return await _api.multipartPost(
        endpoint,
        fields: fields,
        files: {'foto': fotoPath},
      );
    }
    return await _api.post(endpoint, body: fields);
  }

  /* ================= UPDATE ================= */
  Future<Map<String, dynamic>> update(
    String hashid, {
    required String tanggalPengembalian,
    String? keterangan,
    String? fotoPath,
  }) async {
    final fields = <String, String>{
      'tanggal_pengembalian': tanggalPengembalian,
    };
    if (keterangan != null && keterangan.isNotEmpty) {
      fields['keterangan'] = keterangan;
    }

    final endpoint = 'pengembalian_alat/$hashid';

    print('📡 [PengembalianService] PUT /$endpoint');
    print('📦 Fields: $fields');
    print('📷 Has foto: ${fotoPath != null}');

    if (fotoPath != null) {
      return await _api.multipartPut(
        endpoint,
        fields: fields,
        files: {'foto': fotoPath},
      );
    }
    return await _api.put(endpoint, body: fields);
  }

  /* ================= DELETE ================= */
  Future<Map<String, dynamic>> delete(String hashid) async {
    print('📡 [PengembalianService] DELETE /pengembalian_alat/$hashid');
    return await _api.delete('pengembalian_alat/$hashid');
  }
}
