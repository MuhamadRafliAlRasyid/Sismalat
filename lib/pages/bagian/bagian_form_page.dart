import 'package:flutter/material.dart';
import '../../services/bagian_service.dart';

class BagianFormPage extends StatefulWidget {
  final String? hashid;
  const BagianFormPage({super.key, this.hashid});

  @override
  State<BagianFormPage> createState() => _BagianFormPageState();
}

class _BagianFormPageState extends State<BagianFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isEdit = false;

  final _namaBagianCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    isEdit = widget.hashid != null && widget.hashid!.isNotEmpty;
    if (isEdit) {
      _loadBagianDetail();
    }
  }

  Future<void> _loadBagianDetail() async {
    setState(() => isLoading = true);
    try {
      final result = await BagianService.getById(widget.hashid!);
      if (result['status'] == true && result['data'] != null) {
        _namaBagianCtrl.text = result['data']['nama'] ?? '';
      } else {
        _showError(result['message'] ?? 'Gagal memuat data');
      }
    } catch (e) {
      _showError("Terjadi kesalahan saat mengambil data");
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final data = {'nama': _namaBagianCtrl.text.trim()};

    try {
      Map<String, dynamic> result;
      if (isEdit) {
        result = await BagianService.update(widget.hashid!, data);
      } else {
        result = await BagianService.create(data);
      }

      if (result['status'] == true) {
        _showSuccess(
          isEdit ? 'Bagian berhasil diperbarui' : 'Bagian berhasil ditambahkan',
        );
        Navigator.pop(context, true);
      } else {
        _showError(result['message'] ?? 'Gagal menyimpan data');
      }
    } catch (e) {
      _showError("Terjadi kesalahan saat menyimpan");
    }

    if (mounted) setState(() => isLoading = false);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF9E7),
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Bagian' : 'Tambah Bagian'),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD97706)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _namaBagianCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nama Bagian',
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
                          borderSide: const BorderSide(
                            color: Color(0xFFFBBF24),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Nama bagian wajib diisi';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isEdit ? 'Simpan Perubahan' : 'Tambah Bagian',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _namaBagianCtrl.dispose();
    super.dispose();
  }
}
