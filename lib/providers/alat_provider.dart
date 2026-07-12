import 'package:flutter/material.dart';
import '../services/alat_service.dart';

class AlatProvider extends ChangeNotifier {
  final AlatService _alatService;

  List<Map<String, dynamic>> _alats = [];
  Map<String, dynamic>? _selectedAlat;
  List<Map<String, dynamic>> _kategoris = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;
  bool _hasMore = true;

  AlatProvider({required AlatService alatService}) : _alatService = alatService;

  List<Map<String, dynamic>> get alats => _alats;
  Map<String, dynamic>? get selectedAlat => _selectedAlat;
  List<Map<String, dynamic>> get kategoris => _kategoris;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;

  /* ================= FETCH ALL ALATS ================= */
  Future<void> fetchAlats({
    bool refresh = false,
    String? search,
    String? kategoriId,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _alats = [];
    }

    _isLoading = _currentPage == 1;
    _error = null;
    notifyListeners();

    try {
      print('🔄 [AlatProvider] Fetching page $_currentPage...');

      final response = await _alatService.getAlats(
        search: search,
        kategoriId: kategoriId,
        page: _currentPage,
      );

      // ✅ DEBUG: Print response structure
      if (response['success'] == true && response['data'] != null) {
        print('📦 [AlatProvider] Data type: ${response['data'].runtimeType}');

        if (response['data'] is Map<String, dynamic>) {
          final dataMap = response['data'] as Map<String, dynamic>;
          if (dataMap['data'] is List) {
            final list = dataMap['data'] as List;
            print('📦 [AlatProvider] Items count: ${list.length}');
            if (list.isNotEmpty && list[0] is Map) {
              print(
                '📦 [AlatProvider] First item keys: ${(list[0] as Map).keys.toList()}',
              );
            }
          }
        }
      }

      if (response['success'] == true) {
        final responseData = response['data'];
        List dataList = [];

        if (responseData is Map<String, dynamic>) {
          // Format pagination Laravel: {data: [...], last_page: 5, ...}
          dataList = responseData['data'] as List? ?? [];
          _lastPage = responseData['last_page'] ?? 1;
        } else if (responseData is List) {
          // Format langsung list
          dataList = responseData;
          _lastPage = 1;
        }

        // ✅ Konversi aman ke List<Map<String, dynamic>>
        final convertedData = dataList.map((e) {
          if (e is Map<String, dynamic>) return e;
          if (e is Map) return Map<String, dynamic>.from(e);
          return <String, dynamic>{};
        }).toList();

        if (_currentPage == 1) {
          _alats = convertedData;
        } else {
          _alats.addAll(convertedData);
        }

        _hasMore = _currentPage < _lastPage;

        // Load kategoris jika ada di response (biasanya di halaman pertama)
        if (_currentPage == 1 && response.containsKey('kategoris')) {
          final katData = response['kategoris'];
          if (katData is List) {
            _kategoris = katData.map((e) {
              if (e is Map<String, dynamic>) return e;
              if (e is Map) return Map<String, dynamic>.from(e);
              return <String, dynamic>{};
            }).toList();
          }
        }

        print('✅ [AlatProvider] Success - ${_alats.length} alat loaded');
      } else {
        throw Exception(response['message'] ?? 'Gagal memuat data');
      }
    } catch (e, stackTrace) {
      print('❌ [AlatProvider] Error: $e');
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /* ================= LOAD MORE ================= */
  Future<void> loadMore({String? search, String? kategoriId}) async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    _currentPage++;
    notifyListeners();

    try {
      final response = await _alatService.getAlats(
        search: search,
        kategoriId: kategoriId,
        page: _currentPage,
      );

      if (response['success'] == true) {
        final responseData = response['data'];
        List dataList = [];

        if (responseData is Map<String, dynamic>) {
          dataList = responseData['data'] as List? ?? [];
          _lastPage = responseData['last_page'] ?? 1;
        } else if (responseData is List) {
          dataList = responseData;
        }

        final convertedData = dataList.map((e) {
          if (e is Map<String, dynamic>) return e;
          if (e is Map) return Map<String, dynamic>.from(e);
          return <String, dynamic>{};
        }).toList();

        _alats.addAll(convertedData);
        _hasMore = _currentPage < _lastPage;
      } else {
        _currentPage--; // Rollback jika gagal
      }
    } catch (e) {
      print('❌ [AlatProvider] Load more error: $e');
      _currentPage--; // Rollback jika error
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /* ================= GET CREATE DATA ================= */
  Future<Map<String, dynamic>?> getCreateData() async {
    try {
      final response = await _alatService.getCreateData();
      if (response['success'] == true) {
        final data = response['data'];
        if (data is Map<String, dynamic>) {
          if (data.containsKey('kategoris')) {
            final katData = data['kategoris'];
            if (katData is List) {
              _kategoris = katData.map((e) {
                if (e is Map<String, dynamic>) return e;
                if (e is Map) return Map<String, dynamic>.from(e);
                return <String, dynamic>{};
              }).toList();
              notifyListeners();
            }
          }
          return data;
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
    return null;
  }

  /* ================= CREATE ================= */
  Future<bool> create(Map<String, String> fields, {String? fotoPath}) async {
    try {
      final response = await _alatService.createAlat(
        fields: fields,
        fotoPath: fotoPath,
      );

      if (response['success'] == true) {
        await fetchAlats(refresh: true);
        return true;
      } else {
        _error = response['message'] ?? 'Gagal menyimpan data';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /* ================= GET EDIT DATA ================= */
  Future<Map<String, dynamic>?> getEditData(String hashid) async {
    try {
      print('🔄 [AlatProvider] Fetching edit data for hashid: $hashid');

      final response = await _alatService.getEditData(hashid);

      if (response['success'] == true) {
        final data = response['data'];

        if (data is Map<String, dynamic>) {
          // ✅ Load kategoris jika ada
          if (data.containsKey('kategoris')) {
            final katData = data['kategoris'];
            if (katData is List) {
              _kategoris = katData.map((e) {
                if (e is Map<String, dynamic>) return e;
                if (e is Map) return Map<String, dynamic>.from(e);
                return <String, dynamic>{};
              }).toList();
              notifyListeners();
            }
          }

          // ✅ Jika ada field 'alat', kembalikan data alat
          if (data.containsKey('alat')) {
            final alatData = data['alat'];
            return alatData is Map<String, dynamic>
                ? alatData
                : Map<String, dynamic>.from(alatData);
          }

          // ✅ Jika data langsung berisi data alat (tanpa wrapper)
          if (data.containsKey('nama_alat')) {
            return data;
          }

          return data;
        }
      } else {
        _error = response['message'] ?? 'Gagal memuat data edit';
        notifyListeners();
      }
    } catch (e) {
      print('❌ [AlatProvider] getEditData error: $e');
      _error = e.toString();
      notifyListeners();
    }
    return null;
  }

  /* ================= UPDATE ================= */
  Future<bool> update(
    String hashid,
    Map<String, String> fields, {
    String? fotoPath,
  }) async {
    try {
      final response = await _alatService.updateAlat(
        hashid,
        fields: fields,
        fotoPath: fotoPath,
      );

      if (response['success'] == true) {
        await fetchAlats(refresh: true);
        return true;
      } else {
        _error = response['message'] ?? 'Gagal memperbarui data';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /* ================= DELETE ================= */
  Future<bool> delete(String hashid) async {
    try {
      final response = await _alatService.deleteAlat(hashid);

      if (response['success'] == true) {
        _alats.removeWhere((item) => item['hashid'] == hashid);
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Gagal menghapus data';
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
