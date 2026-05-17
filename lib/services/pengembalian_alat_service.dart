import 'api_base.dart';

class PengembalianAlatService {
  final ApiBase _api;

  PengembalianAlatService({required String baseUrl, required String token})
    : _api = ApiBase(baseUrl: baseUrl, token: token);

  Future<Map<String, dynamic>> getPengembalian({
    String? search,
    String? tanggal,
    String? alatHashid,
    int perPage = 10,
  }) async {
    final params = <String, String>{};
    if (search != null) params['search'] = search;
    if (tanggal != null) params['tanggal'] = tanggal;
    if (alatHashid != null) params['alat_id'] = alatHashid;
    params['per_page'] = perPage.toString();
    return await _api.get('pengembalian_alat', queryParams: params);
  }

  Future<Map<String, dynamic>> getDetail(String hashid) async {
    return await _api.get('pengembalian_alat/$hashid');
  }

  Future<Map<String, dynamic>> create({
    required String pengambilanHashid,
    required int jumlah,
    String? keterangan,
    String? namaPeminjam,
    String? fotoPath,
  }) async {
    final fields = <String, String>{'jumlah': jumlah.toString()};
    if (keterangan != null) fields['keterangan'] = keterangan;
    if (namaPeminjam != null) fields['nama_peminjam'] = namaPeminjam;

    final endpoint = 'pengembalian_alat/$pengambilanHashid';
    if (fotoPath != null) {
      return await _api.multipartPost(
        endpoint,
        fields: fields,
        files: {'foto': fotoPath},
      );
    }
    return await _api.post(endpoint, body: fields);
  }

  Future<Map<String, dynamic>> update(
    String hashid, {
    required int jumlah,
    String? keterangan,
    String? namaPeminjam,
    String? fotoPath,
  }) async {
    final fields = <String, String>{'jumlah': jumlah.toString()};
    if (keterangan != null) fields['keterangan'] = keterangan;
    if (namaPeminjam != null) fields['nama_peminjam'] = namaPeminjam;

    final endpoint = 'pengembalian_alat/$hashid';
    if (fotoPath != null) {
      return await _api.multipartPut(
        endpoint,
        fields: fields,
        files: {'foto': fotoPath},
      );
    }
    return await _api.put(endpoint, body: fields);
  }

  Future<Map<String, dynamic>> delete(String hashid) async {
    return await _api.delete('pengembalian_alat/$hashid');
  }
}
