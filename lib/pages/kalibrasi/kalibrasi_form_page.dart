// lib/pages/kalibrasi/kalibrasi_form_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/kalibrasi_provider.dart';

class KalibrasiFormPage extends StatefulWidget {
  final String? hashid;
  final String? alatHashid;
  const KalibrasiFormPage({super.key, this.hashid, this.alatHashid});

  @override
  State<KalibrasiFormPage> createState() => _KalibrasiFormPageState();
}

class _KalibrasiFormPageState extends State<KalibrasiFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _tglCtrl = TextEditingController();
  final _berlakuCtrl = TextEditingController();
  final _sertifikatCtrl = TextEditingController();
  final _ketCtrl = TextEditingController();
  bool _saving = false;
  late KalibrasiProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<KalibrasiProvider>();
    if (widget.hashid != null) {
      final existing = _provider.items.firstWhere(
        (item) => item['hashid'] == widget.hashid,
        orElse: () => <String, dynamic>{},
      );
      if (existing.isNotEmpty) {
        _tglCtrl.text = existing['tanggal_kalibrasi'] ?? '';
        _berlakuCtrl.text = existing['masa_berlaku_baru'] ?? '';
        _sertifikatCtrl.text = existing['no_sertifikat'] ?? '';
        _ketCtrl.text = existing['keterangan'] ?? '';
      }
    }
  }

  @override
  void dispose() {
    _tglCtrl.dispose();
    _berlakuCtrl.dispose();
    _sertifikatCtrl.dispose();
    _ketCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFD97706)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ctrl.text = picked.toString().split(' ')[0];
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = {
      'tanggal_kalibrasi': _tglCtrl.text.trim(),
      'masa_berlaku_baru': _berlakuCtrl.text.trim(),
      'no_sertifikat': _sertifikatCtrl.text.trim(),
      'keterangan': _ketCtrl.text.trim(),
    };

    bool ok;
    if (widget.hashid == null) {
      if (widget.alatHashid == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Alat tidak diketahui')));
        setState(() => _saving = false);
        return;
      }
      ok = await _provider.createForAlat(widget.alatHashid!, data);
    } else {
      ok = await _provider.updateKalibrasi(widget.hashid!, data);
    }

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.hashid == null
                ? 'Kalibrasi berhasil ditambahkan'
                : 'Kalibrasi berhasil diperbarui',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan kalibrasi'),
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
        title: Text(isEdit ? 'Edit Kalibrasi' : 'Tambah Kalibrasi'),
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
              _staggeredField(
                0,
                _buildDateField(
                  controller: _tglCtrl,
                  label: 'Tanggal Kalibrasi',
                  icon: Icons.calendar_today,
                ),
              ),
              _staggeredField(
                1,
                _buildDateField(
                  controller: _berlakuCtrl,
                  label: 'Masa Berlaku Baru',
                  icon: Icons.event,
                ),
              ),
              _staggeredField(
                2,
                _buildTextField(
                  controller: _sertifikatCtrl,
                  label: 'No Sertifikat',
                  icon: Icons.article,
                ),
              ),
              _staggeredField(
                3,
                _buildTextField(
                  controller: _ketCtrl,
                  label: 'Keterangan',
                  icon: Icons.description,
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: 24),
              _staggeredField(
                4,
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _saving
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(isEdit ? Icons.save : Icons.add),
                              const SizedBox(width: 8),
                              Text(
                                isEdit
                                    ? 'Simpan Perubahan'
                                    : 'Tambahkan Kalibrasi',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
      child: Padding(padding: const EdgeInsets.only(bottom: 16), child: child),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _pickDate(controller),
      validator: (v) => v!.trim().isEmpty ? '$label wajib diisi' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 22),
        suffixIcon: const Icon(Icons.date_range, color: Color(0xFFD97706)),
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
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 22),
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
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
    );
  }
}
