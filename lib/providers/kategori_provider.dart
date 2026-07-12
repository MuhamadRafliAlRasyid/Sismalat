import 'package:flutter/material.dart';
import '../services/kategori_service.dart';

class KategoriProvider extends ChangeNotifier {
  final KategoriService _service;

  List<Map<String, dynamic>> _kategoris = [];
  bool _isLoading = false;
  String? _error;

  KategoriProvider({required KategoriService service}) : _service = service;

  List<Map<String, dynamic>> get kategoris => _kategoris;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchKategoris({String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 [KategoriProvider] Fetching kategoris...');

      final res = await _service.getKategoris(search: search);

      print('📦 [KategoriProvider] Response keys: ${res.keys.toList()}');

      if (res['success'] == true) {
        // ✅ PERBAIKAN: Parse pagination object
        final paginationData = res['data'];
        final List data = paginationData is List
            ? paginationData
            : (paginationData['data'] ?? []);

        print('📦 [KategoriProvider] Total kategoris: ${data.length}');

        _kategoris = data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        throw Exception(res['message'] ?? 'Gagal memuat kategori');
      }
    } catch (e) {
      print('❌ [KategoriProvider] Error: $e');
      _error = 'Gagal memuat kategori: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> create(Map<String, dynamic> data) async {
    try {
      final res = await _service.createKategori(data);
      if (res['success'] == true) {
        await fetchKategoris();
        return true;
      } else {
        _error = res['message'] ?? 'Gagal menyimpan';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(String hashid, Map<String, dynamic> data) async {
    try {
      final res = await _service.updateKategori(hashid, data);
      if (res['success'] == true) {
        await fetchKategoris();
        return true;
      } else {
        _error = res['message'] ?? 'Gagal update';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(String hashid) async {
    try {
      final res = await _service.deleteKategori(hashid);
      if (res['success'] == true) {
        await fetchKategoris();
        return true;
      } else {
        _error = res['message'] ?? 'Gagal hapus';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
