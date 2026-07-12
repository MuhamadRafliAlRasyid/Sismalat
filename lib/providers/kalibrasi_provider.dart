import 'package:flutter/material.dart';
import '../services/kalibrasi_service.dart';

class KalibrasiProvider extends ChangeNotifier {
  final KalibrasiService _service;

  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  String? _error;

  KalibrasiProvider({required KalibrasiService service}) : _service = service;

  List<Map<String, dynamic>> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /* ================= FETCH ALL KALIBRASI ================= */
  Future<void> fetchAll({String? search, String? alatId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 [KalibrasiProvider] Fetching all kalibrasi...');

      final res = await _service.getKalibrasis(search: search, alatId: alatId);

      print('📦 [KalibrasiProvider] Response keys: ${res.keys.toList()}');
      print('📦 [KalibrasiProvider] Success: ${res['success']}');

      if (res['success'] == true) {
        final paginationData = res['data'];
        final List data = paginationData is List
            ? paginationData
            : (paginationData['data'] ?? []);

        print('📦 [KalibrasiProvider] Total items: ${data.length}');

        _items = data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        throw Exception(res['message'] ?? 'Gagal memuat data');
      }
    } catch (e) {
      print('❌ [KalibrasiProvider] Error: $e');
      _error = 'Gagal memuat data: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /* ================= FETCH BY ALAT ID ================= */
  /// ✅ Method baru untuk fetch kalibrasi berdasarkan alat hashid
  Future<void> fetchByAlatId(String alatHashid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 [KalibrasiProvider] Fetching kalibrasi by alat: $alatHashid');

      final res = await _service.getKalibrasiByAlat(alatHashid);

      print('📦 [KalibrasiProvider] Response keys: ${res.keys.toList()}');
      print('📦 [KalibrasiProvider] Success: ${res['success']}');

      if (res['success'] == true) {
        final paginationData = res['data'];
        final List data = paginationData is List
            ? paginationData
            : (paginationData['data'] ?? []);

        print('📦 [KalibrasiProvider] Total items: ${data.length}');

        _items = data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        throw Exception(res['message'] ?? 'Gagal memuat data');
      }
    } catch (e) {
      print('❌ [KalibrasiProvider] Error: $e');
      _error = 'Gagal memuat data: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /* ================= CREATE KALIBRASI ================= */
  Future<bool> createForAlat(
    String alatHashid,
    Map<String, dynamic> data,
  ) async {
    try {
      print('💾 [KalibrasiProvider] Creating kalibrasi for alat: $alatHashid');

      final res = await _service.createKalibrasi(alatHashid, data);

      if (res['success'] == true) {
        await fetchAll();
        return true;
      } else {
        _error = res['message'] ?? 'Gagal menyimpan';
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ [KalibrasiProvider] Create error: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /* ================= UPDATE KALIBRASI ================= */
  Future<bool> updateKalibrasi(String hashid, Map<String, dynamic> data) async {
    try {
      print('💾 [KalibrasiProvider] Updating kalibrasi: $hashid');

      final res = await _service.updateKalibrasi(hashid, data);

      if (res['success'] == true) {
        await fetchAll();
        return true;
      } else {
        _error = res['message'] ?? 'Gagal update';
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ [KalibrasiProvider] Update error: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /* ================= DELETE KALIBRASI ================= */
  Future<bool> deleteKalibrasi(String hashid) async {
    try {
      print('🗑️ [KalibrasiProvider] Deleting kalibrasi: $hashid');

      final res = await _service.deleteKalibrasi(hashid);

      if (res['success'] == true) {
        await fetchAll();
        return true;
      } else {
        _error = res['message'] ?? 'Gagal hapus';
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ [KalibrasiProvider] Delete error: $e');
      _error = e.toString();
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
