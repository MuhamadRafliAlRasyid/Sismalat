// lib/providers/pengambilan_provider.dart
import 'package:flutter/material.dart';
import '../models/alat_models.dart';
import '../services/pengambilan_alat_service.dart';
import '../services/api_base.dart';

class PengambilanProvider extends ChangeNotifier {
  final PengambilanAlatService _service;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  String? _error;

  PengambilanProvider({required PengambilanAlatService service})
    : _service = service;

  List<Map<String, dynamic>> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAll({String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _service.getPengambilan(search: search);
      final List data = res['data'] ?? [];
      _items = data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      _error = 'Gagal memuat data';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchByAlatId(String alatHashid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _service.getPengambilan(alatHashid: alatHashid);
      final List data = res['data'] ?? [];
      _items = data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      _error = 'Gagal memuat data';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> create({
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
    try {
      await _service.create(
        userId: userId,
        bagianId: bagianId,
        alatHashid: alatHashid,
        namaPeminjam: namaPeminjam,
        jumlah: jumlah,
        satuan: satuan,
        keperluan: keperluan,
        waktuPengambilan: waktuPengambilan,
        fotoPath: fotoPath,
      );
      // Tidak fetchAll() otomatis, biarkan halaman yang memanggil refresh sendiri jika perlu
      return true;
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
    required String keperluan,
    required String waktuPengambilan,
    String? fotoPath,
  }) async {
    try {
      await _service.update(
        hashid,
        bagianId: bagianId,
        alatHashid: alatHashid,
        namaPeminjam: namaPeminjam,
        jumlah: jumlah,
        satuan: satuan,
        keperluan: keperluan,
        waktuPengambilan: waktuPengambilan,
        fotoPath: fotoPath,
      );
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(String hashid) async {
    try {
      await _service.delete(hashid);
      await fetchAll();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }
}
