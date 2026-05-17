import 'package:flutter/material.dart';
import '../models/alat_models.dart';
import '../services/kategori_service.dart';
import '../services/api_base.dart';

class KategoriProvider extends ChangeNotifier {
  final KategoriService _service;
  List<Kategori> _kategoris = [];
  bool _isLoading = false;
  String? _error;

  KategoriProvider({required KategoriService service}) : _service = service;

  List<Kategori> get kategoris => _kategoris;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchKategoris({String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _service.getKategoris(search: search);
      _kategoris = (res['data'] as List)
          .map((e) => Kategori.fromJson(e))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Gagal memuat kategori';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> create(Map<String, dynamic> data) async {
    try {
      await _service.createKategori(data);
      await fetchKategoris();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(String hashid, Map<String, dynamic> data) async {
    try {
      await _service.updateKategori(hashid, data);
      await fetchKategoris();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(String hashid) async {
    try {
      await _service.deleteKategori(hashid);
      await fetchKategoris();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }
}
