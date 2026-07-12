// lib/providers/pengambilan_provider.dart
import 'package:flutter/material.dart';
import '../services/pengambilan_alat_service.dart';
import '../services/api_base.dart';

class PengambilanProvider extends ChangeNotifier {
  final PengambilanAlatService _service;
  
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;
  bool _hasMore = true;

  PengambilanProvider({required PengambilanAlatService service})
    : _service = service;

  List<Map<String, dynamic>> get items => _items;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;

  Future<void> fetchAll({String? search, bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _items = [];
    }

    _isLoading = _currentPage == 1;
    _error = null;
    notifyListeners();

    try {
      final res = await _service.getPengambilan(
        search: search,
        page: _currentPage,
      );
      
      if (res['success'] == true) {
        final paginationData = res['data'];
        final List data = paginationData['data'] ?? [];
        
        if (_currentPage == 1) {
          _items = data.map((e) => Map<String, dynamic>.from(e)).toList();
        } else {
          _items.addAll(data.map((e) => Map<String, dynamic>.from(e)));
        }
        
        _lastPage = paginationData['last_page'] ?? 1;
        _hasMore = _currentPage < _lastPage;
      } else {
        throw Exception(res['message'] ?? 'Gagal memuat data');
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore({String? search}) async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    _currentPage++;
    notifyListeners();

    try {
      final res = await _service.getPengambilan(
        search: search,
        page: _currentPage,
      );
      
      if (res['success'] == true) {
        final paginationData = res['data'];
        final List data = paginationData['data'] ?? [];
        _items.addAll(data.map((e) => Map<String, dynamic>.from(e)));
        
        _lastPage = paginationData['last_page'] ?? 1;
        _hasMore = _currentPage < _lastPage;
      }
    } catch (e) {
      _currentPage--;
    }
    
    _isLoadingMore = false;
    notifyListeners();
  }

  // ✨ TAMBAHKAN METHOD INI
  Future<void> fetchByAlatId(String alatHashid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _service.getPengambilan(alatHashid: alatHashid);
      
      if (res['success'] == true) {
        final paginationData = res['data'];
        final List data = paginationData['data'] ?? [];
        _items = data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        throw Exception(res['message'] ?? 'Gagal memuat data');
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getCreateData() async {
    try {
      final res = await _service.getCreateData();
      if (res['success'] == true) {
        return res['data'];
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
    return null;
  }

  Future<Map<String, dynamic>?> getEditData(String hashid) async {
    try {
      final res = await _service.getEditData(hashid);
      if (res['success'] == true) {
        return res['data'];
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
    return null;
  }

  Future<bool> create({
    required int userId,
    required int bagianId,
    required String alatHashid,
    String? namaPeminjam,
    required int jumlah,
    required String satuan,
    required int lamaPinjam,
    required String keperluan,
    required String waktuPengambilan,
    String? fotoPath,
  }) async {
    try {
      final res = await _service.create(
        userId: userId,
        bagianId: bagianId,
        alatHashid: alatHashid,
        namaPeminjam: namaPeminjam,
        jumlah: jumlah,
        satuan: satuan,
        lamaPinjam: lamaPinjam,
        keperluan: keperluan,
        waktuPengambilan: waktuPengambilan,
        fotoPath: fotoPath,
      );
      
      if (res['success'] == true) {
        return true;
      } else {
        _error = res['message'] ?? 'Gagal menyimpan data';
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(
    String hashid, {
    required int bagianId,
    required String alatHashid,
    String? namaPeminjam,
    required int jumlah,
    required String satuan,
    required int lamaPinjam,
    required String keperluan,
    required String waktuPengambilan,
    String? fotoPath,
  }) async {
    try {
      final res = await _service.update(
        hashid,
        bagianId: bagianId,
        alatHashid: alatHashid,
        namaPeminjam: namaPeminjam,
        jumlah: jumlah,
        satuan: satuan,
        lamaPinjam: lamaPinjam,
        keperluan: keperluan,
        waktuPengambilan: waktuPengambilan,
        fotoPath: fotoPath,
      );
      
      if (res['success'] == true) {
        return true;
      } else {
        _error = res['message'] ?? 'Gagal memperbarui data';
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(String hashid) async {
    try {
      final res = await _service.delete(hashid);
      if (res['success'] == true) {
        _items.removeWhere((item) => item['hashid'] == hashid);
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Gagal menghapus data';
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}