// lib/services/pengambilan_alat_service.dart
import 'api_base.dart';

class PengambilanAlatService {
  final ApiBase _api;

  PengambilanAlatService({required String baseUrl, required String token})
    : _api = ApiBase(baseUrl: baseUrl, token: token);

  Future<Map<String, dynamic>> getDetail(String hashid) async {
    return await _api.get('pengambilan_alat/$hashid');
  }

  Future<Map<String, dynamic>> getPengambilan({
    String? search,
    String? alatHashid,
    int perPage = 10,
  }) async {
    final params = <String, String>{};
    if (search != null) params['search'] = search;
    if (alatHashid != null) params['alat_id'] = alatHashid;
    params['per_page'] = perPage.toString();
    return await _api.get('pengambilan_alat', queryParams: params);
  }

  Future<Map<String, dynamic>> create({
    required int userId,
    required int bagianId,
    required String alatHashid,
    String? namaPeminjam,
    required int jumlah,
    required String satuan,
    required String keperluan,
    required String waktuPengambilan,
    String? fotoPath,
  }) async {
    final fields = <String, String>{
      'user_id': userId.toString(),
      'bagian_id': bagianId.toString(),
      'alat_id': alatHashid,
      'jumlah': jumlah.toString(),
      'satuan': satuan,
      'keperluan': keperluan,
      'waktu_pengambilan': waktuPengambilan,
    };
    if (namaPeminjam != null) fields['nama_peminjam'] = namaPeminjam;

    if (fotoPath != null) {
      return await _api.multipartPost(
        'pengambilan_alat',
        fields: fields,
        files: {'foto': fotoPath},
      );
    }
    return await _api.post('pengambilan_alat', body: fields);
  }

  Future<Map<String, dynamic>> update(
    String hashid, {
    required int bagianId,
    required String alatHashid,
    String? namaPeminjam,
    required int jumlah,
    required String satuan,
    required String keperluan,
    required String waktuPengambilan,
    String? fotoPath,
  }) async {
    final fields = <String, String>{
      'bagian_id': bagianId.toString(),
      'alat_id': alatHashid,
      'jumlah': jumlah.toString(),
      'satuan': satuan,
      'keperluan': keperluan,
      'waktu_pengambilan': waktuPengambilan,
    };
    if (namaPeminjam != null) fields['nama_peminjam'] = namaPeminjam;

    final endpoint = 'pengambilan_alat/$hashid';
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
    return await _api.delete('pengambilan_alat/$hashid');
  }
}
