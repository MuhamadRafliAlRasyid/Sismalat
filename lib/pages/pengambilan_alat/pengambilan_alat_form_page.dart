import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ TAMBAHKAN IMPORT INI
import '../../providers/pengambilan_provider.dart';
import '../../services/auth_service.dart';
import 'package:image_picker/image_picker.dart';

class PengambilanAlatFormPage extends StatefulWidget {
  final String? hashid;
  final String? alatHashid;

  const PengambilanAlatFormPage({super.key, this.hashid, this.alatHashid});

  @override
  State<PengambilanAlatFormPage> createState() =>
      _PengambilanAlatFormPageState();
}

class _PengambilanAlatFormPageState extends State<PengambilanAlatFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _jumlahCtrl = TextEditingController();
  final _satuanCtrl = TextEditingController();
  final _lamaPinjamCtrl = TextEditingController();
  final _keperluanCtrl = TextEditingController();
  final _waktuCtrl = TextEditingController();
  final _imagePicker = ImagePicker();

  XFile? _imageFile;
  bool _saving = false;
  bool _loadingData = false;

  String? _selectedAlatHashid;
  List<Map<String, dynamic>> _alatOptions = [];
  int? _userId;
  int? _bagianId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loadingData = true);

    final provider = context.read<PengambilanProvider>();

    // ✅ DEBUG: Cek apakah data user tersedia
    _userId = await AuthService.getUserId();
    _bagianId = await AuthService.getBagianId();

    print('🔍 [Form] User ID: $_userId');
    print('🔍 [Form] Bagian ID: $_bagianId');

    // ✅ FALLBACK: Jika data null, coba ambil dari profil terbaru
    if (_userId == null || _bagianId == null) {
      print('⚠️ [Form] Data user null, mencoba refresh profil...');
      final profileRes = await AuthService.getProfile();
      if (profileRes['status'] == true && profileRes['user'] != null) {
        final user = profileRes['user'];
        _userId = user['id'];
        _bagianId = user['bagian_id'];

        // Simpan ulang ke preferences agar下次 tidak null
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', _userId?.toString() ?? '');
        await prefs.setString('bagian_id', _bagianId?.toString() ?? '');

        print('✅ [Form] Profil berhasil di-refresh. User ID: $_userId');
      }
    }

    if (widget.hashid != null) {
      // Edit mode - load existing data
      final editData = await provider.getEditData(widget.hashid!);
      if (editData != null && mounted) {
        final pengambilan = editData['pengambilan'];
        final alatsGrouped = editData['alatsGrouped'] ?? [];

        _alatOptions = _flattenAlats(alatsGrouped);

        if (pengambilan != null) {
          _namaCtrl.text = pengambilan['nama_peminjam'] ?? '';
          _jumlahCtrl.text = pengambilan['jumlah']?.toString() ?? '';
          _satuanCtrl.text = pengambilan['satuan'] ?? '';
          _lamaPinjamCtrl.text = pengambilan['lama_pinjam']?.toString() ?? '';
          _keperluanCtrl.text = pengambilan['keperluan'] ?? '';
          _waktuCtrl.text = pengambilan['waktu_pengambilan'] ?? '';
          _selectedAlatHashid = pengambilan['alat']?['hashid'];
        }
      }
    } else {
      // Create mode - load form data
      final createData = await provider.getCreateData();
      if (createData != null && mounted) {
        final alatsGrouped = createData['alatsGrouped'] ?? [];
        _alatOptions = _flattenAlats(alatsGrouped);

        if (widget.alatHashid != null) {
          _selectedAlatHashid = widget.alatHashid;
        }
      }
    }

    if (mounted) setState(() => _loadingData = false);
  }

  // ✅ HANYA SATU METHOD _SAVE YANG BENAR
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAlatHashid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih alat terlebih dahulu')),
      );
      return;
    }

    // ✅ VALIDASI LEBIH DETAIL
    if (_userId == null || _bagianId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sesi berakhir atau data pengguna tidak valid. Silakan login ulang.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      // Opsional: Arahkan ke halaman login
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage()));
      return;
    }

    setState(() => _saving = true);

    final provider = context.read<PengambilanProvider>();
    bool success;

    try {
      if (widget.hashid == null) {
        // Create
        success = await provider.create(
          userId: _userId!,
          bagianId: _bagianId!,
          alatHashid: _selectedAlatHashid!,
          namaPeminjam: _namaCtrl.text.trim(),
          jumlah: int.tryParse(_jumlahCtrl.text) ?? 0,
          satuan: _satuanCtrl.text.trim(),
          lamaPinjam: int.tryParse(_lamaPinjamCtrl.text) ?? 0,
          keperluan: _keperluanCtrl.text.trim(),
          waktuPengambilan: _waktuCtrl.text,
          fotoPath: _imageFile?.path,
        );
      } else {
        // Update
        success = await provider.update(
          widget.hashid!,
          bagianId: _bagianId!,
          alatHashid: _selectedAlatHashid!,
          namaPeminjam: _namaCtrl.text.trim(),
          jumlah: int.tryParse(_jumlahCtrl.text) ?? 0,
          satuan: _satuanCtrl.text.trim(),
          lamaPinjam: int.tryParse(_lamaPinjamCtrl.text) ?? 0,
          keperluan: _keperluanCtrl.text.trim(),
          waktuPengambilan: _waktuCtrl.text,
          fotoPath: _imageFile?.path,
        );
      }
    } catch (e) {
      success = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) {
      setState(() => _saving = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.hashid == null
                  ? 'Pengambilan berhasil ditambahkan'
                  : 'Pengambilan berhasil diperbarui',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Gagal menyimpan data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _flattenAlats(List<dynamic> grouped) {
    final result = <Map<String, dynamic>>[];
    for (var group in grouped) {
      final items = group['items'] ?? [];
      for (var item in items) {
        result.add({
          'hashid': item['hashid'],
          'nama_alat': item['nama_alat'],
          'jumlah': item['jumlah'],
          'merk': item['merk'],
          'tipe': item['tipe'],
        });
      }
    }
    return result;
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // ✅ Kompres gambar untuk upload lebih cepat
      maxWidth: 1200,
    );
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
        "${combined.hour.toString().padLeft(2, '0')}:${combined.minute.toString().padLeft(2, '0')}:00";
    _waktuCtrl.text = formatted;
    setState(() {});
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _jumlahCtrl.dispose();
    _satuanCtrl.dispose();
    _lamaPinjamCtrl.dispose();
    _keperluanCtrl.dispose();
    _waktuCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: _loadingData
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD97706)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isScanMode && _alatOptions.isNotEmpty)
                      _staggeredField(0, _buildReadonlyAlatField())
                    else
                      _staggeredField(0, _buildDropdownAlat()),
                    _staggeredField(
                      1,
                      _buildTextField(
                        controller: _namaCtrl,
                        label: 'Nama Peminjam',
                        hint: 'Masukkan nama peminjam',
                        maxLength: 255, // ✅ Match dengan Laravel
                      ),
                    ),
                    _staggeredField(
                      2,
                      _buildTextField(
                        controller: _jumlahCtrl,
                        label: 'Jumlah',
                        hint: 'Minimal 1',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Wajib diisi';
                          }
                          final num = int.tryParse(v);
                          if (num == null) return 'Harus angka';
                          if (num < 1)
                            return 'Minimal 1'; // ✅ Match dengan Laravel
                          return null;
                        },
                      ),
                    ),
                    _staggeredField(
                      3,
                      _buildTextField(
                        controller: _satuanCtrl,
                        label: 'Satuan',
                        hint: 'Contoh: unit, buah, set',
                        maxLength: 20, // ✅ Match dengan Laravel
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Wajib diisi';
                          }
                          if (v.length > 20) return 'Maksimal 20 karakter';
                          return null;
                        },
                      ),
                    ),
                    _staggeredField(
                      4,
                      _buildTextField(
                        controller: _lamaPinjamCtrl,
                        label: 'Lama Pinjam (Hari)',
                        hint: 'Minimal 1 hari',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Wajib diisi';
                          }
                          final num = int.tryParse(v);
                          if (num == null) return 'Harus angka';
                          if (num < 1)
                            return 'Minimal 1 hari'; // ✅ Match dengan Laravel
                          return null;
                        },
                      ),
                    ),
                    _staggeredField(
                      5,
                      _buildTextField(
                        controller: _keperluanCtrl,
                        label: 'Keperluan',
                        hint: 'Jelaskan keperluan peminjaman',
                        maxLines: 3,
                        maxLength: 255, // ✅ Match dengan Laravel
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Wajib diisi';
                          }
                          if (v.length > 255) return 'Maksimal 255 karakter';
                          return null;
                        },
                      ),
                    ),
                    _staggeredField(
                      6,
                      _buildDateTimeField(
                        controller: _waktuCtrl,
                        label: 'Waktu Pengambilan',
                        onTap: _pickDateTime,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ),
                    _staggeredField(7, _buildImagePickerField()),
                    const SizedBox(height: 30),
                    _staggeredField(8, _buildSaveButton(isEdit)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '', // ✅ Sembunyikan counter text
        hintStyle: TextStyle(color: Colors.grey.shade400),
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
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
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

  Widget _buildReadonlyAlatField() {
    final selectedAlat = _alatOptions.firstWhere(
      (a) => a['hashid'] == widget.alatHashid,
      orElse: () => _alatOptions.first,
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
                  '${selectedAlat['nama_alat']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Stok: ${selectedAlat['jumlah']}',
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

  Widget _buildDropdownAlat() {
    return DropdownButtonFormField<String>(
      value: _selectedAlatHashid,
      decoration: InputDecoration(
        labelText: 'Pilih Alat',
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
      ),
      items: _alatOptions.map((alat) {
        return DropdownMenuItem<String>(
          value: alat['hashid'],
          child: Text(
            '${alat['nama_alat']} (Stok: ${alat['jumlah']})',
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
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
            'Foto Bukti (Opsional)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Format: JPG, PNG, WEBP • Max: 2MB',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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
                  label: const Text('Pilih Foto'),
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
                    ? Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _imageFile!.path.split('/').last,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => _imageFile = null),
                          ),
                        ],
                      )
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
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isEdit ? Icons.save : Icons.add, size: 22),
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
}
