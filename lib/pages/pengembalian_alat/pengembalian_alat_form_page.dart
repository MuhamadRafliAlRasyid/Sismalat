import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/pengembalian_provider.dart';
import '../../config/api.dart';

class PengembalianAlatFormPage extends StatefulWidget {
  final String? hashid; // Untuk edit mode
  final String? pengambilanHashid; // Untuk create mode (dari list pengambilan)

  const PengembalianAlatFormPage({
    super.key,
    this.hashid,
    this.pengambilanHashid,
  });

  @override
  State<PengembalianAlatFormPage> createState() =>
      _PengembalianAlatFormPageState();
}

class _PengembalianAlatFormPageState extends State<PengembalianAlatFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _tanggalCtrl = TextEditingController();
  final _keteranganCtrl = TextEditingController();
  final _imagePicker = ImagePicker();

  XFile? _imageFile;
  bool _saving = false;
  bool _loadingData = false;
  bool _isTerlambat = false;

  // Data dari backend
  Map<String, dynamic>? _pengambilanData;
  Map<String, dynamic>? _pengembalianData; // Untuk edit mode
  int _jumlahSisa = 0;
  int _jumlahSudahKembali = 0;
  String? _existingFotoUrl; // Foto yang sudah ada saat edit

  @override
  void initState() {
    super.initState();
    // Set default tanggal hari ini
    final now = DateTime.now();
    _tanggalCtrl.text =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loadingData = true);

    final provider = context.read<PengembalianProvider>();

    try {
      if (widget.hashid != null) {
        // ========== EDIT MODE ==========
        final editData = await provider.getEditData(widget.hashid!);
        if (editData != null && mounted) {
          // Backend return: { success: true, data: { pengembalian object } }
          _pengembalianData = editData;
          _pengambilanData = editData['pengambilan'];

          // Set form values dari data yang sudah ada
          if (_pengembalianData != null) {
            _tanggalCtrl.text = _parseDate(
              _pengembalianData!['tanggal_pengembalian'],
            );
            _keteranganCtrl.text = _pengembalianData!['keterangan'] ?? '';

            // Cek apakah ada foto lama
            if (_pengembalianData!['foto'] != null &&
                _pengembalianData!['foto'].toString().isNotEmpty) {
              _existingFotoUrl = _getPhotoUrl(_pengembalianData!['foto']);
            }
          }

          // Hitung sisa pinjaman
          _calculateSisa();
        }
      } else if (widget.pengambilanHashid != null) {
        // ========== CREATE MODE ==========
        final createData = await provider.getCreateData(
          widget.pengambilanHashid!,
        );
        if (createData != null && mounted) {
          // Backend return: { success: true, data: { pengambilan object } }
          _pengambilanData = createData;
          _calculateSisa();
        }
      }

      // Cek apakah terlambat
      if (_pengambilanData != null && mounted) {
        final jatuhTempo = _pengambilanData!['tanggal_jatuh_tempo'];
        if (jatuhTempo != null) {
          try {
            final jatuhTempoDate = DateTime.parse(jatuhTempo);
            _isTerlambat = jatuhTempoDate.isBefore(DateTime.now());
          } catch (_) {}
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) setState(() => _loadingData = false);
  }

  void _calculateSisa() {
    if (_pengambilanData == null) return;

    final totalPinjam = (_pengambilanData!['jumlah'] ?? 0) as int;

    // Hitung total yang sudah dikembalikan
    if (widget.hashid != null && _pengembalianData != null) {
      // Edit mode: kurangi jumlah yang sedang diedit
      final pengembalians = _pengambilanData!['pengembalians'] as List? ?? [];
      _jumlahSudahKembali = 0;
      for (var item in pengembalians) {
        if (item['hashid'] != widget.hashid) {
          _jumlahSudahKembali += (item['jumlah'] ?? 0) as int;
        }
      }
    } else {
      // Create mode: hitung semua yang sudah dikembalikan
      final pengembalians = _pengambilanData!['pengembalians'] as List? ?? [];
      _jumlahSudahKembali = 0;
      for (var item in pengembalians) {
        _jumlahSudahKembali += (item['jumlah'] ?? 0) as int;
      }
    }

    _jumlahSisa = totalPinjam - _jumlahSudahKembali;
  }

  String _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      // Handle format "2024-01-15" atau "2024-01-15 10:30:00"
      final parts = dateStr.split(' ');
      return parts[0]; // Ambil bagian tanggal saja
    } catch (_) {
      return dateStr;
    }
  }

  String? _getPhotoUrl(dynamic photoPath) {
    if (photoPath == null) return null;
    String photoStr = photoPath.toString().trim();
    if (photoStr.isEmpty) return null;

    // Jika sudah full URL
    if (photoStr.startsWith('http://') || photoStr.startsWith('https://')) {
      try {
        final uri = Uri.parse(photoStr);
        if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
          return '${Apiimg.baseUrl}${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
        }
      } catch (_) {}
      return photoStr;
    }

    // Path relatif: gabungkan dengan baseUrl
    if (photoStr.startsWith('/')) {
      photoStr = photoStr.substring(1);
    }
    return '${Apiimg.baseUrl}/$photoStr';
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked != null) {
      setState(() {
        _imageFile = picked;
        _existingFotoUrl = null; // Reset existing foto jika pilih baru
      });
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      // Jangan reset _existingFotoUrl jika di edit mode dan belum upload baru
    });
  }

  Future<void> _pickDate() async {
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

    final formatted =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    _tanggalCtrl.text = formatted;

    // Cek ulang status terlambat berdasarkan tanggal yang dipilih
    if (_pengambilanData != null) {
      final jatuhTempo = _pengambilanData!['tanggal_jatuh_tempo'];
      if (jatuhTempo != null) {
        try {
          final jatuhTempoDate = DateTime.parse(jatuhTempo);
          setState(() {
            _isTerlambat = date.isAfter(jatuhTempoDate);
          });
        } catch (_) {}
      }
    }

    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validasi khusus jika terlambat
    if (_isTerlambat) {
      if (_keteranganCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Keterangan wajib diisi karena pengembalian terlambat',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_keteranganCtrl.text.trim().length < 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Keterangan minimal 10 karakter'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Cek foto: jika edit mode dan sudah ada foto lama, tidak wajib upload baru
      final hasFoto =
          _imageFile != null ||
          (_existingFotoUrl != null && _existingFotoUrl!.isNotEmpty);
      if (!hasFoto) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Foto bukti wajib diupload karena pengembalian terlambat',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _saving = true);

    final provider = context.read<PengembalianProvider>();
    bool success;

    try {
      if (widget.hashid == null) {
        // CREATE MODE
        success = await provider.create(
          widget.pengambilanHashid!,
          tanggalPengembalian: _tanggalCtrl.text,
          keterangan: _keteranganCtrl.text.trim().isEmpty
              ? null
              : _keteranganCtrl.text.trim(),
          fotoPath: _imageFile?.path,
        );
      } else {
        // UPDATE MODE
        success = await provider.update(
          widget.hashid!,
          tanggalPengembalian: _tanggalCtrl.text,
          keterangan: _keteranganCtrl.text.trim().isEmpty
              ? null
              : _keteranganCtrl.text.trim(),
          fotoPath: _imageFile?.path,
        );
      }

      if (mounted) {
        setState(() => _saving = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.hashid == null
                    ? 'Pengembalian berhasil dicatat'
                    : 'Pengembalian berhasil diperbarui',
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
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _tanggalCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.hashid != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFEF9E7),
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Pengembalian' : 'Catat Pengembalian'),
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
          : _pengambilanData == null
          ? const Center(child: Text('Data pengambilan tidak ditemukan'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _staggeredField(0, _buildInfoCard()),
                    const SizedBox(height: 16),
                    if (_isTerlambat)
                      _staggeredField(1, _buildTerlambatWarning()),
                    const SizedBox(height: 16),
                    _staggeredField(
                      2,
                      _buildDateField(
                        controller: _tanggalCtrl,
                        label: 'Tanggal Pengembalian',
                        onTap: _pickDate,
                        validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ),
                    _staggeredField(
                      3,
                      _buildTextField(
                        controller: _keteranganCtrl,
                        label: 'Keterangan',
                        hint: _isTerlambat
                            ? 'Wajib diisi (min. 10 karakter)'
                            : 'Opsional - kondisi alat, catatan, dll',
                        maxLines: 4,
                        validator: _isTerlambat
                            ? (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Keterangan wajib diisi';
                                }
                                if (v.trim().length < 10) {
                                  return 'Minimal 10 karakter';
                                }
                                return null;
                              }
                            : null,
                      ),
                    ),
                    _staggeredField(4, _buildImagePickerField()),
                    const SizedBox(height: 30),
                    _staggeredField(5, _buildSaveButton(isEdit)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    final alat = _pengambilanData!['alat'] ?? {};
    final user = _pengambilanData!['user'] ?? {};
    final totalPinjam = _pengambilanData!['jumlah'] ?? 0;
    final jatuhTempo = _pengambilanData!['tanggal_jatuh_tempo'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isTerlambat ? Colors.red.shade300 : const Color(0xFFFBBF24),
          width: 1.5,
        ),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Detail Pengambilan',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              if (_isTerlambat)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, size: 14, color: Colors.red),
                      SizedBox(width: 4),
                      Text(
                        'TERLAMBAT',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Divider(height: 24),

          // Info Alat
          _infoRowWithIcon(
            icon: Icons.build,
            label: 'Alat',
            value: alat['nama_alat'] ?? '-',
            subtitle:
                '${alat['merk'] ?? ''} ${alat['tipe'] ?? ''}'.trim().isEmpty
                ? null
                : '${alat['merk'] ?? ''} ${alat['tipe'] ?? ''}'.trim(),
          ),
          const SizedBox(height: 12),

          // Info Peminjam
          _infoRowWithIcon(
            icon: Icons.person,
            label: 'Peminjam',
            value: user['name'] ?? '-',
            subtitle: user['email'],
          ),
          const SizedBox(height: 12),

          // Info Jumlah
          _infoRowWithIcon(
            icon: Icons.inventory_2,
            label: 'Total Dipinjam',
            value: '$totalPinjam',
            valueColor: const Color(0xFF1E293B),
          ),
          const SizedBox(height: 8),
          _infoRowWithIcon(
            icon: Icons.check_circle_outline,
            label: 'Sudah Dikembalikan',
            value: '$_jumlahSudahKembali',
            valueColor: Colors.green,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade100, Colors.orange.shade100],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD97706).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.assignment_return,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Sisa yang Harus Dikembalikan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
                Text(
                  '$_jumlahSisa',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Info Jatuh Tempo
          if (jatuhTempo != null)
            _infoRowWithIcon(
              icon: Icons.event_busy,
              label: 'Jatuh Tempo',
              value: _formatDate(jatuhTempo),
              valueColor: _isTerlambat ? Colors.red : null,
            ),
        ],
      ),
    );
  }

  Widget _buildTerlambatWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade50, Colors.orange.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengembalian Terlambat!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keterangan dan foto bukti WAJIB diisi untuk pengembalian yang melewati tenggat waktu.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRowWithIcon({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFFD97706)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? const Color(0xFF1E293B),
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _isTerlambat && label == 'Keterangan'
                ? Colors.red.shade300
                : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _isTerlambat && label == 'Keterangan'
                ? Colors.red
                : const Color(0xFFFBBF24),
            width: 2,
          ),
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

  Widget _buildDateField({
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
        suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFFD97706)),
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

  Widget _buildImagePickerField() {
    final hasFoto =
        _imageFile != null ||
        (_existingFotoUrl != null && _existingFotoUrl!.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isTerlambat && !hasFoto
              ? Colors.red.shade300
              : Colors.grey.shade200,
          width: _isTerlambat && !hasFoto ? 1.5 : 1,
        ),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.photo_camera,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Foto Bukti Pengembalian',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              if (_isTerlambat)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: const Text(
                    'WAJIB',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Opsional',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Format: JPG, PNG, WEBP • Max: 2MB',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 12),

          // Preview foto yang dipilih atau existing
          if (_imageFile != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Image.file(
                    File(_imageFile!.path),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _removeImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _imageFile!.path.split('/').last,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ] else if (_existingFotoUrl != null) ...[
            // Foto yang sudah ada saat edit mode
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _existingFotoUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, size: 48),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text('Foto sudah ada', style: TextStyle(fontSize: 12)),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _existingFotoUrl = null;
                    });
                  },
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Hapus'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Tombol pilih foto
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library, size: 20),
              label: Text(
                _imageFile != null || _existingFotoUrl != null
                    ? 'Ganti Foto'
                    : 'Pilih Foto',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
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
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: Icon(isEdit ? Icons.save : Icons.check_circle, size: 22),
                label: Text(
                  isEdit ? 'Simpan Perubahan' : 'Catat Pengembalian',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: Colors.amber.withOpacity(0.4),
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

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr.split(' ')[0]);
      final months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
