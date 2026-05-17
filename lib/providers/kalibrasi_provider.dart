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

  Future<void> fetchAll({String? search, String? alatId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _service.getKalibrasis(search: search, alatId: alatId);
      final List data = res['data'] ?? [];
      _items = data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      _error = 'Gagal memuat data';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createForAlat(
    String alatHashid,
    Map<String, dynamic> data,
  ) async {
    try {
      await _service.createKalibrasi(alatHashid, data);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateKalibrasi(String hashid, Map<String, dynamic> data) async {
    try {
      await _service.updateKalibrasi(hashid, data);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteKalibrasi(String hashid) async {
    try {
      await _service.deleteKalibrasi(hashid);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
