import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/kategori_provider.dart';

class KategoriFormPage extends StatefulWidget {
  final String? hashid;
  const KategoriFormPage({Key? key, this.hashid}) : super(key: key);

  @override
  State<KategoriFormPage> createState() => _KategoriFormPageState();
}

class _KategoriFormPageState extends State<KategoriFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _ketCtrl = TextEditingController();
  bool _saving = false;
  late KategoriProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<KategoriProvider>();
    if (widget.hashid != null) {
      final existing = _provider.kategoris.firstWhere(
        (k) => k.hashid == widget.hashid,
      );
      _namaCtrl.text = existing.nama;
      _ketCtrl.text = existing.keterangan ?? '';
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

    bool ok;
    if (widget.hashid == null) {
      ok = await _provider.create(data);
    } else {
      ok = await _provider.update(widget.hashid!, data);
    }

    if (ok && mounted) {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan kategori'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _saving = false);
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nama Kategori
              TextFormField(
                controller: _namaCtrl,
                validator: (v) =>
                    v!.trim().isEmpty ? 'Nama kategori wajib diisi' : null,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Nama Kategori',
                  hintText: 'Masukkan nama kategori',
                  prefixIcon: const Icon(Icons.category, size: 22),
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
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Colors.redAccent,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Keterangan
              TextFormField(
                controller: _ketCtrl,
                maxLines: 2,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Keterangan',
                  hintText: 'Opsional',
                  prefixIcon: const Icon(Icons.description, size: 22),
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
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Tombol Simpan
              SizedBox(
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
                    shadowColor: Colors.amber.withOpacity(0.4),
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
                            Icon(isEdit ? Icons.save : Icons.add),
                            const SizedBox(width: 8),
                            Text(
                              isEdit
                                  ? 'Simpan Perubahan'
                                  : 'Tambahkan Kategori',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
