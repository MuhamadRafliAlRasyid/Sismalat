// lib/pages/alat/alat_form_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/alat_provider.dart';
import 'package:image_picker/image_picker.dart';

class AlatFormPage extends StatefulWidget {
  final String? hashid;
  const AlatFormPage({Key? key, this.hashid}) : super(key: key);

  @override
  State<AlatFormPage> createState() => _AlatFormPageState();
}

class _AlatFormPageState extends State<AlatFormPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _kelasCtrl = TextEditingController();
  final _merkCtrl = TextEditingController();
  final _tipeCtrl = TextEditingController();
  final _noSeriCtrl = TextEditingController();
  final _noIdentitasCtrl = TextEditingController();
  final _kapasitasCtrl = TextEditingController();
  final _dayaBacaCtrl = TextEditingController();
  final _jumlahCtrl = TextEditingController();
  final _noSertifikatCtrl = TextEditingController();
  final _masaBerlakuCtrl = TextEditingController();

  final _imagePicker = ImagePicker();
  XFile? _imageFile;
  bool _saving = false;
  late AlatProvider _provider;

  // Animasi stagger untuk field
  late AnimationController _fieldAnimController;
  late Animation<double> _fieldFadeAnimation;

  @override
  void initState() {
    super.initState();
    _provider = context.read<AlatProvider>();
    _fieldAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fieldFadeAnimation = CurvedAnimation(
      parent: _fieldAnimController,
      curve: Curves.easeIn,
    );
    _fieldAnimController.forward();

    if (widget.hashid != null) {
      final existing = _provider.selectedAlat;
      if (existing != null) {
        _namaCtrl.text = existing.namaAlat;
        _kelasCtrl.text = existing.kelas ?? '';
        _merkCtrl.text = existing.merk;
        _tipeCtrl.text = existing.tipe ?? '';
        _noSeriCtrl.text = existing.noSeri ?? '';
        _noIdentitasCtrl.text = existing.noIdentitas ?? '';
        _kapasitasCtrl.text = existing.kapasitas ?? '';
        _dayaBacaCtrl.text = existing.dayaBaca ?? '';
        _jumlahCtrl.text = existing.jumlah.toString();
        _noSertifikatCtrl.text = existing.noSertifikat ?? '';
        _masaBerlakuCtrl.text = existing.masaBerlaku ?? '';
      }
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _kelasCtrl.dispose();
    _merkCtrl.dispose();
    _tipeCtrl.dispose();
    _noSeriCtrl.dispose();
    _noIdentitasCtrl.dispose();
    _kapasitasCtrl.dispose();
    _dayaBacaCtrl.dispose();
    _jumlahCtrl.dispose();
    _noSertifikatCtrl.dispose();
    _masaBerlakuCtrl.dispose();
    _fieldAnimController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = picked);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      _masaBerlakuCtrl.text = picked.toString().split(' ')[0];
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final fields = {
      'nama_alat': _namaCtrl.text.trim(),
      'kelas': _kelasCtrl.text.trim(),
      'merk': _merkCtrl.text.trim(),
      'tipe': _tipeCtrl.text.trim(),
      'no_seri': _noSeriCtrl.text.trim(),
      'no_identitas': _noIdentitasCtrl.text.trim(),
      'kapasitas': _kapasitasCtrl.text.trim(),
      'daya_baca': _dayaBacaCtrl.text.trim(),
      'jumlah': _jumlahCtrl.text.trim(),
      'no_sertifikat': _noSertifikatCtrl.text.trim(),
      'masa_berlaku': _masaBerlakuCtrl.text.trim(),
    };

    bool ok;
    if (widget.hashid == null) {
      ok = await _provider.create(fields, fotoPath: _imageFile?.path);
    } else {
      ok = await _provider.update(
        widget.hashid!,
        fields,
        fotoPath: _imageFile?.path,
      );
    }

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.hashid == null
                ? 'Alat berhasil ditambahkan'
                : 'Alat berhasil diperbarui',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan alat'),
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
        title: Text(isEdit ? 'Edit Alat' : 'Tambah Alat'),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fieldFadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _staggeredField(
                  0,
                  _buildTextField(
                    controller: _namaCtrl,
                    label: 'Nama Alat',
                    icon: Icons.build,
                    validator: (v) => v!.isEmpty ? 'Wajib' : null,
                  ),
                ),
                _staggeredField(
                  1,
                  _buildTextField(
                    controller: _merkCtrl,
                    label: 'Merk',
                    icon: Icons.branding_watermark,
                    validator: (v) => v!.isEmpty ? 'Wajib' : null,
                  ),
                ),
                _staggeredField(
                  2,
                  _buildTextField(
                    controller: _tipeCtrl,
                    label: 'Tipe',
                    icon: Icons.category,
                  ),
                ),
                _staggeredField(
                  3,
                  _buildTextField(
                    controller: _kelasCtrl,
                    label: 'Kelas',
                    icon: Icons.grade,
                  ),
                ),
                _staggeredField(
                  4,
                  _buildTextField(
                    controller: _noSeriCtrl,
                    label: 'No. Seri',
                    icon: Icons.tag,
                  ),
                ),
                _staggeredField(
                  5,
                  _buildTextField(
                    controller: _noIdentitasCtrl,
                    label: 'No. Identitas',
                    icon: Icons.fingerprint,
                  ),
                ),
                _staggeredField(
                  6,
                  _buildTextField(
                    controller: _kapasitasCtrl,
                    label: 'Kapasitas',
                    icon: Icons.tune,
                  ),
                ),
                _staggeredField(
                  7,
                  _buildTextField(
                    controller: _dayaBacaCtrl,
                    label: 'Daya Baca',
                    icon: Icons.visibility,
                  ),
                ),
                _staggeredField(
                  8,
                  _buildTextField(
                    controller: _jumlahCtrl,
                    label: 'Jumlah',
                    icon: Icons.inventory,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Wajib';
                      if (int.tryParse(v) == null) return 'Harus angka';
                      return null;
                    },
                  ),
                ),
                _staggeredField(
                  9,
                  _buildTextField(
                    controller: _noSertifikatCtrl,
                    label: 'No. Sertifikat',
                    icon: Icons.article,
                  ),
                ),
                _staggeredField(10, _buildDateField()),
                _staggeredField(11, _buildImagePicker()),
                const SizedBox(height: 30),
                _staggeredField(12, _buildSaveButton(isEdit)),
              ],
            ),
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
      child: Padding(padding: const EdgeInsets.only(bottom: 14), child: child),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 22) : null,
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

  Widget _buildDateField() {
    return TextFormField(
      controller: _masaBerlakuCtrl,
      readOnly: true,
      onTap: _pickDate,
      decoration: InputDecoration(
        labelText: 'Masa Berlaku',
        prefixIcon: const Icon(Icons.calendar_today, size: 22),
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

  Widget _buildImagePicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Foto Alat',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Pilih'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _imageFile != null
                    ? Text(_imageFile!.name, overflow: TextOverflow.ellipsis)
                    : const Text(
                        'Belum ada foto',
                        style: TextStyle(color: Colors.grey),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(bool isEdit) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: AnimatedSwitcher(
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
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isEdit ? Icons.save : Icons.add),
                    const SizedBox(width: 8),
                    Text(
                      isEdit ? 'Simpan Perubahan' : 'Tambahkan Alat',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
