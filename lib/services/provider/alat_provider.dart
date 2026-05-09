// lib/services/alat_provider.dart
import 'package:flutter/foundation.dart';
import '../alat_service.dart';

class AlatProvider extends ChangeNotifier {
  final AlatService service;
  AlatProvider({required this.service});

  List<dynamic> _alats = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _searchQuery;
  String? _kategoriId;

  List<dynamic> get alats => _alats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  Future<void> fetchAlats({bool refresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _alats = [];
    }
    notifyListeners();

    try {
      final response = await service.getAlats(
        search: _searchQuery,
        kategoriId: _kategoriId,
        perPage: 10, // bisa disesuaikan
        page: _currentPage, // ← sekarang aman
      );
      final data = response['data'] as List<dynamic>;
      final meta = response['meta'];
      _alats.addAll(data);
      _currentPage++;
      _hasMore = meta['current_page'] < meta['last_page'];
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearch(String query) {
    _searchQuery = query;
    fetchAlats(refresh: true);
  }

  void setKategori(String? id) {
    _kategoriId = id;
    fetchAlats(refresh: true);
  }

  void clearFilters() {
    _searchQuery = null;
    _kategoriId = null;
    fetchAlats(refresh: true);
  }
}
