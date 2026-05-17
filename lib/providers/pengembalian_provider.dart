import 'package:flutter/material.dart';
import '../services/pengembalian_alat_service.dart';

class PengembalianProvider extends ChangeNotifier {
  final PengembalianAlatService _service;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  String? _error;

  PengembalianProvider({required PengembalianAlatService service})
    : _service = service;

  List<Map<String, dynamic>> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAll({String? search, String? tanggal}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _service.getPengembalian(
        search: search,
        tanggal: tanggal,
      );
      final List data = res['data'] ?? [];
      _items = data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      _error = 'Gagal memuat data';
    }
    _isLoading = false;
    notifyListeners();
  }

  // create, update, delete tetap seperti semula (tidak diubah karena tidak membaca _items)
  Future<bool> create({
    required String pengambilanHashid,
    required int jumlah,
    String? keterangan,
    String? namaPeminjam,
    String? fotoPath,
  }) async {
    try {
      await _service.create(
        pengambilanHashid: pengambilanHashid,
        jumlah: jumlah,
        keterangan: keterangan,
        namaPeminjam: namaPeminjam,
        fotoPath: fotoPath,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(
    String hashid, {
    required int jumlah,
    String? keterangan,
    String? namaPeminjam,
    String? fotoPath,
  }) async {
    try {
      await _service.update(
        hashid,
        jumlah: jumlah,
        keterangan: keterangan,
        namaPeminjam: namaPeminjam,
        fotoPath: fotoPath,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(String hashid) async {
    try {
      await _service.delete(hashid);
      await fetchAll();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchByAlatId(String alatHashid) async {
  _isLoading = true;
  _error = null;
  notifyListeners();
  try {
    final res = await _service.getPengembalian(alatHashid: alatHashid);
    final List data = res['data'] ?? [];
    _items = data.map((e) => Map<String, dynamic>.from(e)).toList();
  } catch (_) {
    _error = 'Gagal memuat data';
  }
  _isLoading = false;
  notifyListeners();
}
}
