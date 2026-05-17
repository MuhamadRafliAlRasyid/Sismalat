import 'package:flutter/material.dart';
import '../models/alat_models.dart';
import '../services/alat_service.dart';
import '../services/api_base.dart';

class AlatProvider extends ChangeNotifier {
  final AlatService _alatService;

  List<Alat> _alats = [];
  Alat? _selectedAlat;
  bool _isLoading = false;
  bool _isLoadingMore = false; // untuk infinite scroll
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true; // masih ada halaman berikutnya?

  AlatProvider({required AlatService alatService}) : _alatService = alatService;

  List<Alat> get alats => _alats;
  Alat? get selectedAlat => _selectedAlat;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> fetchAlats({
    bool reset = true,
    String? search,
    String? kategoriId,
  }) async {
    if (reset) {
      _alats.clear();
      _isLoading = true;
      _error = null;
    } else {
      // jika sudah loading semua, hentikan
      if (_isLoadingMore || !_hasMore) return;
      _isLoadingMore = true;
    }

    notifyListeners();

    try {
      // Panggil service tanpa parameter page/perPage
      final response = await _alatService.getAlats(
        search: search,
        kategoriId: kategoriId,
      );

      final List<dynamic>? rawList = response is List
          ? response
          : response['data']; // fallback jika backend masih mengirim { data: [...] }

      if (rawList == null) {
        _error = 'Format respons salah';
        return;
      }

      final List<Alat> newAlats = [];
      for (var json in rawList) {
        try {
          newAlats.add(Alat.fromJson(json));
        } catch (e) {
          debugPrint('❌ Error parsing alat: $e');
        }
      }

      // Karena semua data sudah diambil, tidak ada halaman berikutnya
      _alats = newAlats;
      _hasMore = false;
    } catch (e) {
      _error = 'Gagal memuat data';
    }

    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> fetchDetail(String hashid) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _alatService.getAlat(hashid);
      _selectedAlat = Alat.fromJson(response['data']);
    } on ApiException catch (e) {
      _error = e.message;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> create(Map<String, String> fields, {String? fotoPath}) async {
    try {
      await _alatService.createAlat(fields: fields, fotoPath: fotoPath);
      await fetchAlats();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(
    String hashid,
    Map<String, String> fields, {
    String? fotoPath,
  }) async {
    try {
      await _alatService.updateAlat(hashid, fields: fields, fotoPath: fotoPath);
      await fetchAlats();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(String hashid) async {
    try {
      await _alatService.deleteAlat(hashid);
      await fetchAlats();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }
}
