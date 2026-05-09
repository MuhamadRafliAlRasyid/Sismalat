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
        final data = result['data'];

        _namaBagianCtrl.text = data['nama'] ?? '';

        print("✅ Bagian loaded: ${data['nama']}");
      } else {
        _showError(result['message'] ?? 'Gagal memuat data');
      }
    } catch (e) {
      print("❌ ERROR load bagian: $e");
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
      print("❌ ERROR save bagian: $e");
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
      appBar: AppBar(title: Text(isEdit ? 'Edit Bagian' : 'Tambah Bagian')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _namaBagianCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Bagian',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama bagian wajib diisi';
                        }
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
                          backgroundColor: const Color(0xFF001F3F),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                isEdit ? 'Simpan Perubahan' : 'Tambah Bagian',
                                style: const TextStyle(fontSize: 16),
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
