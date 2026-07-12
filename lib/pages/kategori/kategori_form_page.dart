import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/kategori_provider.dart';
import '../../../services/kategori_service.dart';

class KategoriFormPage extends StatefulWidget {
  final String? hashid;

  const KategoriFormPage({super.key, this.hashid});

  @override
  State<KategoriFormPage> createState() => _KategoriFormPageState();
}

class _KategoriFormPageState extends State<KategoriFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _ketCtrl = TextEditingController();

  bool _saving = false;
  bool _loadingData = false;
  String? _errorMessage;

  late KategoriProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<KategoriProvider>();

    if (widget.hashid != null) {
      _loadEditData();
    }
  }

  Future<void> _loadEditData() async {
    setState(() {
      _loadingData = true;
      _errorMessage = null;
    });

    try {
      print('🔍 [KategoriFormPage] Loading data for hashid: ${widget.hashid}');

      // Coba cari di provider dulu
      Map<String, dynamic>? existing;

      if (_provider.kategoris.isNotEmpty) {
        try {
          existing = _provider.kategoris.firstWhere(
            (k) => k['hashid'] == widget.hashid,
          );
          print('✅ [KategoriFormPage] Found in provider');
        } catch (_) {
          print(
            '⚠️ [KategoriFormPage] Not found in provider, fetching from API...',
          );
        }
      }

      // Jika tidak ada di provider, fetch dari API
      if (existing == null) {
        final service = context.read<KategoriService>();
        final response = await service.getKategori(widget.hashid!);

        if (response['success'] == true) {
          existing = Map<String, dynamic>.from(response['data']);
          print('✅ [KategoriFormPage] Fetched from API');
        } else {
          throw Exception(response['message'] ?? 'Data tidak ditemukan');
        }
      }

      // Isi form dengan data
      if (mounted && existing != null) {
        _namaCtrl.text = existing['nama'] ?? '';
        _ketCtrl.text = existing['keterangan'] ?? '';

        print('✅ [KategoriFormPage] Form filled: ${existing['nama']}');
      }
    } catch (e) {
      print('❌ [KategoriFormPage] Error loading data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat data: $e';
        });
      }
    }

    if (mounted) {
      setState(() => _loadingData = false);
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _ketCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final data = {
      'nama': _namaCtrl.text.trim(),
      'keterangan': _ketCtrl.text.trim(),
    };

    print('💾 [KategoriFormPage] Saving: $data');

    bool ok;
    if (widget.hashid == null) {
      ok = await _provider.create(data);
    } else {
      ok = await _provider.update(widget.hashid!, data);
    }

    if (mounted) {
      setState(() => _saving = false);

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.hashid == null
                  ? 'Kategori berhasil ditambahkan'
                  : 'Kategori berhasil diperbarui',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_provider.error ?? 'Gagal menyimpan kategori'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.hashid != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFEF9E7),
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Kategori' : 'Tambah Kategori'),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loadingData
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD97706)),
              ),
            )
          : _errorMessage != null
          ? _buildErrorState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Nama Kategori
                    _staggeredField(
                      0,
                      TextFormField(
                        controller: _namaCtrl,
                        validator: (v) => v!.trim().isEmpty
                            ? 'Nama kategori wajib diisi'
                            : null,
                        style: const TextStyle(fontSize: 15),
                        decoration: _inputDecoration(
                          labelText: 'Nama Kategori',
                          hintText: 'Masukkan nama kategori',
                          icon: Icons.category,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Keterangan
                    _staggeredField(
                      1,
                      TextFormField(
                        controller: _ketCtrl,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 15),
                        decoration: _inputDecoration(
                          labelText: 'Keterangan',
                          hintText: 'Opsional - deskripsi kategori',
                          icon: Icons.description,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Tombol Simpan
                    _staggeredField(2, _buildSaveButton(isEdit)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadEditData,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isEdit) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD97706),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: _saving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isEdit ? Icons.save : Icons.add, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    isEdit ? 'Simpan Perubahan' : 'Tambahkan Kategori',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: Icon(icon, size: 22, color: const Color(0xFFD97706)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFBBF24), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  Widget _staggeredField(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 60)),
      builder: (context, value, widget) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: widget,
          ),
        );
      },
      child: Padding(padding: const EdgeInsets.only(bottom: 14), child: child),
    );
  }
}
