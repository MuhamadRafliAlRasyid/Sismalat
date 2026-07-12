import 'package:flutter/material.dart';
import '../services/pengembalian_alat_service.dart';
import '../services/api_base.dart';

class PengembalianProvider extends ChangeNotifier {
  final PengembalianAlatService _service;

  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;
  bool _hasMore = true;

  PengembalianProvider({required PengembalianAlatService service})
    : _service = service;

  List<Map<String, dynamic>> get items => _items;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;

  /* ================= FETCH ALL ================= */
  Future<void> fetchAll({
    String? search,
    String? tanggal,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _items = [];
    }

    _isLoading = _currentPage == 1;
    _error = null;
    notifyListeners();

    try {
      print('🔄 [PengembalianProvider] Fetching page $_currentPage...');

      final res = await _service.getPengembalian(
        search: search,
        tanggal: tanggal,
        page: _currentPage,
      );

      print('📦 [PengembalianProvider] Response keys: ${res.keys.toList()}');
      print('📦 [PengembalianProvider] Success: ${res['success']}');

      if (res['success'] == true) {
        final paginationData = res['data'];
        final List data = paginationData['data'] ?? [];

        print('📦 [PengembalianProvider] Items in page: ${data.length}');

        if (_currentPage == 1) {
          _items = data.map((e) => Map<String, dynamic>.from(e)).toList();
        } else {
          _items.addAll(data.map((e) => Map<String, dynamic>.from(e)));
        }

        _lastPage = paginationData['last_page'] ?? 1;
        _hasMore = _currentPage < _lastPage;

        print('✅ [PengembalianProvider] Total items: ${_items.length}');
        print('✅ [PengembalianProvider] Has more: $_hasMore');
      } else {
        throw Exception(res['message'] ?? 'Gagal memuat data');
      }
    } catch (e) {
      print('❌ [PengembalianProvider] Error: $e');
      _error = e.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  /* ================= LOAD MORE ================= */
  Future<void> loadMore({String? search, String? tanggal}) async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    _currentPage++;
    notifyListeners();

    try {
      print('🔄 [PengembalianProvider] Loading more page $_currentPage...');

      final res = await _service.getPengembalian(
        search: search,
        tanggal: tanggal,
        page: _currentPage,
      );

      if (res['success'] == true) {
        final paginationData = res['data'];
        final List data = paginationData['data'] ?? [];
        _items.addAll(data.map((e) => Map<String, dynamic>.from(e)));

        _lastPage = paginationData['last_page'] ?? 1;
        _hasMore = _currentPage < _lastPage;

        print(
          '✅ [PengembalianProvider] Total items after load more: ${_items.length}',
        );
      } else {
        _currentPage--;
      }
    } catch (e) {
      print('❌ [PengembalianProvider] Load more error: $e');
      _currentPage--;
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  /* ================= FETCH BY ALAT ID ================= */
  Future<void> fetchByAlatId(String alatHashid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 [PengembalianProvider] Fetching by alat: $alatHashid');

      final res = await _service.getPengembalianByAlat(alatHashid);

      print('📦 [PengembalianProvider] Response keys: ${res.keys.toList()}');

      if (res['success'] == true) {
        final paginationData = res['data'];
        final List data = paginationData is List
            ? paginationData
            : (paginationData['data'] ?? []);

        _items = data.map((e) => Map<String, dynamic>.from(e)).toList();

        print('✅ [PengembalianProvider] Total items: ${_items.length}');
      } else {
        throw Exception(res['message'] ?? 'Gagal memuat data');
      }
    } catch (e) {
      print('❌ [PengembalianProvider] Error: $e');
      _error = e.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  /* ================= GET CREATE DATA ================= */
  Future<Map<String, dynamic>?> getCreateData(String pengambilanHashid) async {
    try {
      print(
        '🔄 [PengembalianProvider] Getting create data for: $pengambilanHashid',
      );

      final res = await _service.getCreateData(pengambilanHashid);
      if (res['success'] == true) {
        return res['data'];
      } else {
        _error = res['message'] ?? 'Gagal memuat data';
        notifyListeners();
      }
    } catch (e) {
      print('❌ [PengembalianProvider] Error: $e');
      _error = e.toString();
      notifyListeners();
    }
    return null;
  }

  /* ================= GET EDIT DATA ================= */
  Future<Map<String, dynamic>?> getEditData(String hashid) async {
    try {
      print('🔄 [PengembalianProvider] Getting edit data for: $hashid');

      final res = await _service.getEditData(hashid);
      if (res['success'] == true) {
        return res['data'];
      } else {
        _error = res['message'] ?? 'Gagal memuat data';
        notifyListeners();
      }
    } catch (e) {
      print('❌ [PengembalianProvider] Error: $e');
      _error = e.toString();
      notifyListeners();
    }
    return null;
  }

  /* ================= CREATE ================= */
  Future<bool> create(
    String pengambilanHashid, {
    required String tanggalPengembalian,
    String? keterangan,
    String? fotoPath,
  }) async {
    try {
      print('💾 [PengembalianProvider] Creating pengembalian...');

      final res = await _service.create(
        pengambilanHashid,
        tanggalPengembalian: tanggalPengembalian,
        keterangan: keterangan,
        fotoPath: fotoPath,
      );

      if (res['success'] == true) {
        print('✅ [PengembalianProvider] Created successfully');
        return true;
      } else {
        _error = res['message'] ?? 'Gagal menyimpan data';
        print('❌ [PengembalianProvider] Error: $_error');
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _error = e.message;
      print('❌ [PengembalianProvider] ApiException: ${e.message}');
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      print('❌ [PengembalianProvider] Error: $e');
      notifyListeners();
      return false;
    }
  }

  /* ================= UPDATE ================= */
  Future<bool> update(
    String hashid, {
    required String tanggalPengembalian,
    String? keterangan,
    String? fotoPath,
  }) async {
    try {
      print('💾 [PengembalianProvider] Updating pengembalian: $hashid');

      final res = await _service.update(
        hashid,
        tanggalPengembalian: tanggalPengembalian,
        keterangan: keterangan,
        fotoPath: fotoPath,
      );

      if (res['success'] == true) {
        print('✅ [PengembalianProvider] Updated successfully');
        return true;
      } else {
        _error = res['message'] ?? 'Gagal memperbarui data';
        print('❌ [PengembalianProvider] Error: $_error');
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _error = e.message;
      print('❌ [PengembalianProvider] ApiException: ${e.message}');
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      print('❌ [PengembalianProvider] Error: $e');
      notifyListeners();
      return false;
    }
  }

  /* ================= DELETE ================= */
  Future<bool> delete(String hashid) async {
    try {
      print('🗑️ [PengembalianProvider] Deleting pengembalian: $hashid');

      final res = await _service.delete(hashid);
      if (res['success'] == true) {
        _items.removeWhere((item) => item['hashid'] == hashid);
        print('✅ [PengembalianProvider] Deleted successfully');
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Gagal menghapus data';
        print('❌ [PengembalianProvider] Error: $_error');
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _error = e.message;
      print('❌ [PengembalianProvider] ApiException: ${e.message}');
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      print('❌ [PengembalianProvider] Error: $e');
      notifyListeners();
      return false;
    }
  }

  /* ================= CLEAR ERROR ================= */
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
