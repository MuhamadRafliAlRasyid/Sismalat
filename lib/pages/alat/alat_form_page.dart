// lib/pages/alat/alat_form_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart'; // ← tambahkan
import '../../services/alat_service.dart'; // perbaiki path

class AlatFormPage extends StatefulWidget {
  final String? hashid;
  const AlatFormPage({super.key, this.hashid}); // tambahkan key

  @override
  State<AlatFormPage> createState() => _AlatFormPageState();
}

class _AlatFormPageState extends State<AlatFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _merkController = TextEditingController();
  final _tipeController = TextEditingController();
  final _noSeriController = TextEditingController(); // contoh tambahan
  final _kapasitasController = TextEditingController(); // contoh tambahan
  File? _fotoFile;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.hashid != null) {
      _loadAlatData();
    }
  }

  void _loadAlatData() async {
    // Gunakan context.read, sekarang provider sudah tersedia
    final alatService = context.read<AlatService>();
    final response = await alatService.getAlat(widget.hashid!);
    final data = response['data'];
    _namaController.text = data['nama_alat'] ?? '';
    _merkController.text = data['merk'] ?? '';
    _tipeController.text = data['tipe'] ?? '';
    _noSeriController.text = data['no_seri'] ?? '';
    _kapasitasController.text = data['kapasitas'] ?? '';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _fotoFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final alatService = context.read<AlatService>();
    // Gunakan Map<String, String> sesuai method service
    final Map<String, String> fields = {
      'nama_alat': _namaController.text,
      'merk': _merkController.text,
      'tipe': _tipeController.text,
      'no_seri': _noSeriController.text,
      'kapasitas': _kapasitasController.text,
      // ... tambahkan field lain sesuai kebutuhan
    };

    try {
      if (widget.hashid == null) {
        await alatService.createAlat(fields: fields, fotoPath: _fotoFile?.path);
      } else {
        await alatService.updateAlat(
          widget.hashid!,
          fields: fields,
          fotoPath: _fotoFile?.path,
        );
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hashid == null ? 'Tambah Alat' : 'Edit Alat'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Alat'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _merkController,
                decoration: const InputDecoration(labelText: 'Merk'),
              ),
              TextFormField(
                controller: _tipeController,
                decoration: const InputDecoration(labelText: 'Tipe'),
              ),
              TextFormField(
                controller: _noSeriController,
                decoration: const InputDecoration(labelText: 'No Seri'),
              ),
              TextFormField(
                controller: _kapasitasController,
                decoration: const InputDecoration(labelText: 'Kapasitas'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Pilih Foto'),
                  ),
                  if (_fotoFile != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Image.file(_fotoFile!, height: 80),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _merkController.dispose();
    _tipeController.dispose();
    _noSeriController.dispose();
    _kapasitasController.dispose();
    super.dispose();
  }
}
