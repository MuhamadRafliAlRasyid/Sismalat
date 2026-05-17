// lib/pages/pengembalian_alat/pengembalian_alat_form_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/pengembalian_provider.dart';
import '../../providers/pengambilan_provider.dart'; // 🆕 untuk ambil daftar pengambilan
import '../../services/auth_service.dart'; // 🆕 untuk userId & role

class PengembalianAlatFormPage extends StatefulWidget {
  final String? hashid; // mode edit
  final String? pengambilanHashid; // langsung dari pengambilan tertentu
  const PengembalianAlatFormPage({
    Key? key,
    this.hashid,
    this.pengambilanHashid,
  }) : super(key: key);

  @override
  State<PengembalianAlatFormPage> createState() =>
      _PengembalianAlatFormPageState();
}

class _PengembalianAlatFormPageState extends State<PengembalianAlatFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahCtrl = TextEditingController();
  final _ketCtrl = TextEditingController();
  final _imagePicker = ImagePicker();
  XFile? _imageFile;
  bool _saving = false;
  bool _isEdit = false;
  Map<String, dynamic>? _pengambilanData;

  // daftar pengambilan yang bisa dipilih
  List<Map<String, dynamic>> _pengambilanList = [];
  bool _loadingPengambilan = false;
  String? _selectedPengambilanHashid;

  int? _userId;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.hashid != null && widget.hashid!.isNotEmpty;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadUserIdentity();
      await _loadPengambilanList();
      if (_isEdit) {
        await _loadExistingData();
      } else if (widget.pengambilanHashid != null) {
        // langsung pilih pengambilan yang diberikan
        _selectedPengambilanHashid = widget.pengambilanHashid;
        final selected = _pengambilanList.firstWhere(
          (e) => e['hashid'] == widget.pengambilanHashid,
          orElse: () => <String, dynamic>{},
        );
        if (selected.isNotEmpty) {
          setState(() => _pengambilanData = selected);
        }
      }
    });
  }

  Future<void> _loadUserIdentity() async {
    final userId = await AuthService.getUserId();
    final profile = await AuthService.getProfile();
    final role = profile['user']?['role'] ?? 'karyawan';
    setState(() {
      _userId = userId;
      _isAdmin = role == 'admin';
    });
  }

  Future<void> _loadPengambilanList() async {
    setState(() => _loadingPengambilan = true);
    final provider = context.read<PengambilanProvider>();
    await provider.fetchAll(); // ambil semua data pengambilan

    List<Map<String, dynamic>> filtered = List.from(provider.items);

    // Jika bukan admin, hanya tampilkan milik user ini
    if (!_isAdmin && _userId != null) {
      filtered = filtered.where((item) {
        final uid = item['user_id'];
        return uid != null && uid.toString() == _userId.toString();
      }).toList();
    }

    // Hanya yang berstatus "dipinjam"
    filtered = filtered.where((item) {
      final status = (item['status'] ?? '').toString().toLowerCase();
      return status == 'dipinjam';
    }).toList();

    setState(() {
      _pengambilanList = filtered;
      _loadingPengambilan = false;
    });
  }

  Future<void> _loadExistingData() async {
    final provider = context.read<PengembalianProvider>();
    final existing = provider.items.firstWhere(
      (e) => e['hashid'] == widget.hashid,
      orElse: () => <String, dynamic>{},
    );
    if (existing.isNotEmpty) {
      _jumlahCtrl.text = existing['jumlah']?.toString() ?? '';
      _ketCtrl.text = existing['keterangan'] ?? '';
      final pengambilan = existing['pengambilan'] as Map<String, dynamic>?;
      if (pengambilan != null) {
        setState(() {
          _pengambilanData = pengambilan;
          _selectedPengambilanHashid = pengambilan['hashid'];
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = picked);
  }

  void _onPengambilanChanged(String? hashid) {
    if (hashid == null) return;
    final selected = _pengambilanList.firstWhere(
      (e) => e['hashid'] == hashid,
      orElse: () => <String, dynamic>{},
    );
    setState(() {
      _selectedPengambilanHashid = hashid;
      _pengambilanData = selected.isNotEmpty ? selected : null;
      _jumlahCtrl.text = ''; // reset jumlah
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<PengembalianProvider>();
    setState(() => _saving = true);
    bool ok;
    if (_isEdit) {
      ok = await provider.update(
        widget.hashid!,
        jumlah: int.tryParse(_jumlahCtrl.text.trim()) ?? 0,
        keterangan: _ketCtrl.text.trim(),
        fotoPath: _imageFile?.path,
      );
    } else {
      if (_selectedPengambilanHashid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih pengambilan'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _saving = false);
        return;
      }
      ok = await provider.create(
        pengambilanHashid: _selectedPengambilanHashid!,
        jumlah: int.tryParse(_jumlahCtrl.text.trim()) ?? 0,
        keterangan: _ketCtrl.text.trim(),
        fotoPath: _imageFile?.path,
      );
    }

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? 'Pengembalian diperbarui' : 'Pengembalian berhasil',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF9E7),
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Pengembalian' : 'Tambah Pengembalian'),
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
              // Dropdown pilih pengambilan (hanya saat tambah, bukan edit)
              if (!_isEdit && !_loadingPengambilan)
                _staggeredField(0, _buildPengambilanDropdown()),
              if (_loadingPengambilan)
                const Center(child: CircularProgressIndicator()),
              // Info pengambilan yang dipilih
              if (_pengambilanData != null)
                _staggeredField(
                  1,
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alat: ${_pengambilanData!['alat']?['nama_alat'] ?? _pengambilanData!['alat']?['nama'] ?? '-'}',
                        ),
                        Text(
                          'Peminjam: ${_pengambilanData!['nama_peminjam'] ?? _pengambilanData!['user']?['name'] ?? '-'}',
                        ),
                        Text(
                          'Jumlah diambil: ${_pengambilanData!['jumlah'] ?? 0}',
                        ),
                      ],
                    ),
                  ),
                ),
              if (_isEdit && _pengambilanData == null)
                const Center(child: Text('Data tidak ditemukan')),
              const SizedBox(height: 16),
              _staggeredField(
                2,
                _buildTextField(
                  controller: _jumlahCtrl,
                  label: 'Jumlah Dikembalikan',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Wajib diisi';
                    final val = int.tryParse(v);
                    if (val == null || val < 1) return 'Tidak valid';
                    if (_pengambilanData != null) {
                      final max = _pengambilanData!['jumlah'] ?? 0;
                      if (val > max) return 'Maksimal $max';
                    }
                    return null;
                  },
                ),
              ),
              _staggeredField(
                3,
                _buildTextField(
                  controller: _ketCtrl,
                  label: 'Keterangan',
                  maxLines: 2,
                ),
              ),
              _staggeredField(
                4,
                Container(
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
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        height: 42,
                        child: ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo_camera, size: 18),
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
                            ? Text(
                                _imageFile!.name,
                                overflow: TextOverflow.ellipsis,
                              )
                            : const Text(
                                'Belum ada foto',
                                style: TextStyle(color: Colors.grey),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _staggeredField(
                5,
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
                            child: Text(
                              _isEdit
                                  ? 'Simpan Perubahan'
                                  : 'Catat Pengembalian',
                              style: const TextStyle(fontSize: 16),
                            ),
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

  Widget _buildPengambilanDropdown() {
    if (_pengambilanList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('Tidak ada pengambilan yang dapat dikembalikan'),
      );
    }
    return DropdownButtonFormField<String>(
      value: _selectedPengambilanHashid,
      decoration: const InputDecoration(
        labelText: 'Pengambilan Alat',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide.none,
        ),
      ),
      items: _pengambilanList.map((item) {
        final alatNama =
            item['alat']?['nama_alat'] ?? item['alat']?['nama'] ?? '-';
        final peminjam = item['nama_peminjam'] ?? item['user']?['name'] ?? '-';
        final tanggal = item['waktu_pengambilan'] ?? '';
        return DropdownMenuItem<String>(
          value: item['hashid'],
          child: Text(
            '$alatNama ($peminjam) - $tanggal',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _onPengambilanChanged,
      validator: (v) => v == null ? 'Pilih pengambilan' : null,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
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
