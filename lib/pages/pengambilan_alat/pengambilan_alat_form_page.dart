// lib/pages/pengambilan_alat/pengambilan_alat_form_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pengambilan_provider.dart';
import '../../providers/alat_provider.dart';
import '../../services/auth_service.dart';
import '../../models/alat_models.dart'; // ✅ TAMBAH IMPORT INI
import 'package:image_picker/image_picker.dart';

class PengambilanAlatFormPage extends StatefulWidget {
  final String? hashid;
  final String? alatHashid;
  const PengambilanAlatFormPage({Key? key, this.hashid, this.alatHashid})
    : super(key: key);

  @override
  State<PengambilanAlatFormPage> createState() =>
      _PengambilanAlatFormPageState();
}

class _PengambilanAlatFormPageState extends State<PengambilanAlatFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _jumlahCtrl = TextEditingController();
  final _satuanCtrl = TextEditingController();
  final _keperluanCtrl = TextEditingController();
  final _waktuCtrl = TextEditingController();
  final _imagePicker = ImagePicker();
  XFile? _imageFile;
  bool _saving = false;

  late PengambilanProvider _pengambilanProvider;
  late AlatProvider _alatProvider;
  String? _selectedAlatHashid;

  @override
  void initState() {
    super.initState();
    _pengambilanProvider = context.read<PengambilanProvider>();
    _alatProvider = context.read<AlatProvider>();
    if (_alatProvider.alats.isEmpty) _alatProvider.fetchAlats();

    if (widget.hashid != null) {
      final data = _pengambilanProvider.items.firstWhere(
        (e) => e['hashid'] == widget.hashid,
      );
      _namaCtrl.text = data['nama_peminjam'] ?? '';
      _jumlahCtrl.text = data['jumlah']?.toString() ?? '';
      _satuanCtrl.text = data['satuan'] ?? '';
      _keperluanCtrl.text = data['keperluan'] ?? '';
      _waktuCtrl.text = data['waktu_pengambilan'] ?? '';
      final alatMap = data['alat'] as Map<String, dynamic>?;
      _selectedAlatHashid = alatMap?['hashid'];
    } else if (widget.alatHashid != null) {
      _selectedAlatHashid = widget.alatHashid;
    }
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = picked);
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFD97706)),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFD97706)),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    final combined = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    final formatted =
        "${combined.year}-${combined.month.toString().padLeft(2, '0')}-${combined.day.toString().padLeft(2, '0')} "
        "${combined.hour.toString().padLeft(2, '0')}:${combined.minute.toString().padLeft(2, '0')}";
    _waktuCtrl.text = formatted;
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAlatHashid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih alat')));
      return;
    }

    final userId = await AuthService.getUserId();
    final bagianId = await AuthService.getBagianId();

    if (userId == null || bagianId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data pengguna tidak lengkap')),
      );
      return;
    }

    setState(() => _saving = true);

    bool ok;
    if (widget.hashid == null) {
      ok = await _pengambilanProvider.create(
        userId: userId,
        bagianId: bagianId,
        alatHashid: _selectedAlatHashid!,
        namaPeminjam: _namaCtrl.text,
        jumlah: int.tryParse(_jumlahCtrl.text) ?? 0,
        satuan: _satuanCtrl.text,
        keperluan: _keperluanCtrl.text,
        waktuPengambilan: _waktuCtrl.text,
        fotoPath: _imageFile?.path,
      );
    } else {
      ok = await _pengambilanProvider.update(
        widget.hashid!,
        bagianId: bagianId,
        alatHashid: _selectedAlatHashid!,
        namaPeminjam: _namaCtrl.text,
        jumlah: int.tryParse(_jumlahCtrl.text) ?? 0,
        satuan: _satuanCtrl.text,
        keperluan: _keperluanCtrl.text,
        waktuPengambilan: _waktuCtrl.text,
        fotoPath: _imageFile?.path,
      );
    }

    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengambilan berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_pengambilanProvider.error ?? 'Gagal menyimpan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final List<Alat> alatList = _alatProvider.alats; // sudah bertipe List<Alat>
    final isEdit = widget.hashid != null;
    final isScanMode = widget.alatHashid != null && !isEdit;

    return Scaffold(
      backgroundColor: const Color(0xFFFEF9E7),
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Pengambilan' : 'Tambah Pengambilan'),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isScanMode && alatList.isNotEmpty)
                _staggeredField(0, _buildReadonlyAlatField(alatList))
              else if (isScanMode && alatList.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                _staggeredField(0, _buildDropdownAlat(alatList)),
              _staggeredField(
                1,
                _buildTextField(controller: _namaCtrl, label: 'Nama Peminjam'),
              ),
              _staggeredField(
                2,
                _buildTextField(
                  controller: _jumlahCtrl,
                  label: 'Jumlah',
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Wajib' : null,
                ),
              ),
              _staggeredField(
                3,
                _buildTextField(
                  controller: _satuanCtrl,
                  label: 'Satuan',
                  validator: (v) => v!.isEmpty ? 'Wajib' : null,
                ),
              ),
              _staggeredField(
                4,
                _buildTextField(
                  controller: _keperluanCtrl,
                  label: 'Keperluan',
                  validator: (v) => v!.isEmpty ? 'Wajib' : null,
                ),
              ),
              _staggeredField(
                5,
                _buildDateTimeField(
                  controller: _waktuCtrl,
                  label: 'Waktu Pengambilan',
                  onTap: _pickDateTime,
                  validator: (v) => v!.isEmpty ? 'Wajib' : null,
                ),
              ),
              _staggeredField(6, _buildImagePickerField()),
              const SizedBox(height: 30),
              _staggeredField(7, _buildSaveButton(isEdit)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
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

  Widget _buildReadonlyAlatField(List<Alat> alatList) {
    final selectedAlat = alatList.firstWhere(
      (a) => a.hashid == widget.alatHashid,
      orElse: () => alatList.first,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFBBF24), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code, color: Color(0xFFD97706)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${selectedAlat.namaAlat}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Stok: ${selectedAlat.jumlah}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
    );
  }

  Widget _buildDropdownAlat(List<Alat> alatList) {
    return DropdownButtonFormField<String>(
      value: _selectedAlatHashid,
      decoration: const InputDecoration(
        labelText: 'Alat',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide.none,
        ),
      ),
      items: alatList
          .map(
            (a) => DropdownMenuItem<String>(
              value: a.hashid,
              child: Text('${a.namaAlat} (Stok: ${a.jumlah})'),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _selectedAlatHashid = v),
      validator: (v) => v == null ? 'Pilih alat' : null,
    );
  }

  Widget _buildImagePickerField() {
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
                  icon: const Icon(Icons.photo_camera, size: 20),
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
    return AnimatedSwitcher(
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
          : SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
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
                      isEdit ? 'Simpan Perubahan' : 'Tambahkan Pengambilan',
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
