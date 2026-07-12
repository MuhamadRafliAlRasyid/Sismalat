// lib/pages/profile/edit_profile_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../config/api.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  /// ✅ TAMBAHAN: Flag untuk membedakan edit profil sendiri vs edit user lain
  final bool isOwnProfile;

  const EditProfilePage({super.key, this.userData, this.isOwnProfile = false});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  File? _selectedImage;
  String? _currentPhotoPath;

  String? selectedRole = 'karyawan';
  int? selectedBagianId;

  final List<Map<String, dynamic>> bagianList = [
    {'id': 1, 'nama': 'Bagian Umum'},
    {'id': 2, 'nama': 'Bagian Keuangan'},
    {'id': 3, 'nama': 'Bagian Produksi'},
    {'id': 4, 'nama': 'Bagian Logistik'},
  ];

  bool get isEditMode => widget.userData != null;

  /// ✅ Apakah user mengedit profilnya sendiri?
  bool get isEditingOwnProfile => widget.isOwnProfile && isEditMode;

  @override
  void initState() {
    super.initState();
    if (isEditMode && widget.userData != null) {
      final user = widget.userData!;
      _nameCtrl.text = user['name'] ?? '';
      _emailCtrl.text = user['email'] ?? '';
      _currentPhotoPath =
          user['profile_photo_path'] ?? user['profile_photo_url'];
      selectedRole = user['role'] ?? 'karyawan';

      // ✅ Parse bagian_id dengan aman
      final bagianId = user['bagian_id'];
      if (bagianId != null) {
        selectedBagianId = bagianId is int
            ? bagianId
            : int.tryParse(bagianId.toString());
      }
    } else {
      selectedRole = 'karyawan';
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memilih foto: $e')));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ Validasi konfirmasi password jika diisi
    if (_passwordCtrl.text.trim().isNotEmpty &&
        _passwordCtrl.text != _confirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password dan konfirmasi password tidak sama'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    Map<String, dynamic> result;

    if (isEditingOwnProfile) {
      // ✅ CASE 1: Edit profil sendiri (user biasa)
      print('📝 [EditProfile] Editing own profile');
      result = await AuthService.updateProfile(
        name: _nameCtrl.text.trim(),
        password: _passwordCtrl.text.trim().isNotEmpty
            ? _passwordCtrl.text.trim()
            : null,
        photo: _selectedImage,
      );
    } else if (isEditMode && widget.userData != null) {
      // ✅ CASE 2: Admin edit user lain
      print('📝 [EditProfile] Admin editing user: ${widget.userData!['id']}');
      final hashid =
          widget.userData!['hashid']?.toString() ??
          widget.userData!['id']?.toString() ??
          '';

      if (hashid.isEmpty) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID user tidak ditemukan'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      result = await AuthService.updateUser(
        hashid: hashid,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(), // ✅ KIRIM EMAIL
        role: selectedRole, // ✅ KIRIM ROLE
        bagianId: selectedBagianId, // ✅ KIRIM BAGIAN_ID
        password: _passwordCtrl.text.trim().isNotEmpty
            ? _passwordCtrl.text.trim()
            : null,
        photo: _selectedImage,
      );
    } else {
      // ✅ CASE 3: Admin tambah user baru
      print('📝 [EditProfile] Adding new user');
      result = await AuthService.register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        role: selectedRole,
        bagianId: selectedBagianId,
      );
    }

    setState(() => isLoading = false);

    if (!mounted) return;

    if (result['status'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode
                ? 'Profil berhasil diperbarui'
                : 'User berhasil ditambahkan',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal menyimpan data'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF9E7),
      appBar: AppBar(
        title: Text(_getTitle()),
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
                    _staggeredField(0, _buildAvatarPicker()),
                    const SizedBox(height: 30),
                    _staggeredField(
                      1,
                      _buildTextField(
                        controller: _nameCtrl,
                        label: 'Nama Lengkap',
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Nama wajib diisi' : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ✅ Email: Tampilkan tapi readonly saat edit profil sendiri
                    _staggeredField(
                      2,
                      _buildTextField(
                        controller: _emailCtrl,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        readOnly:
                            isEditingOwnProfile, // ✅ Readonly untuk profil sendiri
                        validator: (v) {
                          if (v!.trim().isEmpty) return 'Email wajib diisi';
                          if (!v.contains('@')) return 'Email tidak valid';
                          return null;
                        },
                        helperText: isEditingOwnProfile
                            ? 'Email tidak dapat diubah'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _staggeredField(3, _buildPasswordField()),
                    const SizedBox(height: 16),

                    // ✅ Konfirmasi password (jika diisi)
                    if (_passwordCtrl.text.trim().isNotEmpty || !isEditMode)
                      _staggeredField(4, _buildConfirmPasswordField()),

                    // ✅ Role & Bagian (hanya untuk admin edit user lain atau tambah user)
                    if (!isEditingOwnProfile) ...[
                      const SizedBox(height: 16),
                      _staggeredField(5, _buildDropdownRole()),
                      const SizedBox(height: 16),
                      _staggeredField(6, _buildDropdownBagian()),
                    ],
                    const SizedBox(height: 40),
                    _staggeredField(7, _buildSaveButton()),
                  ],
                ),
              ),
            ),
    );
  }

  String _getTitle() {
    if (isEditingOwnProfile) return 'Edit Profil';
    if (isEditMode) return 'Edit User';
    return 'Tambah User';
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
      child: child,
    );
  }

  Widget _buildAvatarPicker() {
    final String? imageUrl =
        _currentPhotoPath != null && _currentPhotoPath!.isNotEmpty
        ? (_currentPhotoPath!.startsWith('http')
              ? _currentPhotoPath
              : '${Apiimg.baseUrl}/images/profile/$_currentPhotoPath')
        : null;

    return GestureDetector(
      onTap: _pickImage,
      child: Hero(
        tag: 'profileAvatar',
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 70,
              backgroundColor: Colors.amber.shade100,
              backgroundImage: _selectedImage != null
                  ? FileImage(_selectedImage!)
                  : (imageUrl != null ? NetworkImage(imageUrl) : null),
              child: _selectedImage == null && imageUrl == null
                  ? const Icon(Icons.person, size: 80, color: Colors.grey)
                  : null,
            ),
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFD97706),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
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

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordCtrl,
      obscureText: true,
      decoration: InputDecoration(
        labelText: isEditMode
            ? 'Password Baru (kosongkan jika tidak diubah)'
            : 'Password',
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
      validator: isEditMode
          ? null
          : (v) {
              if (v == null || v.isEmpty) return 'Password wajib diisi';
              if (v.length < 6) return 'Password minimal 6 karakter';
              return null;
            },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordCtrl,
      obscureText: true,
      decoration: InputDecoration(
        labelText: 'Konfirmasi Password',
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
      validator: (v) {
        if (_passwordCtrl.text.trim().isNotEmpty) {
          if (v != _passwordCtrl.text) return 'Password tidak sama';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownRole() {
    return DropdownButtonFormField<String>(
      value: selectedRole,
      decoration: InputDecoration(
        labelText: 'Role',
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
      items: const [
        DropdownMenuItem(value: 'admin', child: Text('Admin')),
        DropdownMenuItem(value: 'karyawan', child: Text('Karyawan')),
      ],
      onChanged: (value) => setState(() => selectedRole = value),
      validator: (value) => value == null ? 'Pilih Role' : null,
    );
  }

  Widget _buildDropdownBagian() {
    return DropdownButtonFormField<int?>(
      value: selectedBagianId,
      decoration: InputDecoration(
        labelText: 'Bagian',
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
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('- Pilih Bagian -'),
        ),
        ...bagianList.map(
          (b) => DropdownMenuItem<int?>(
            value: b['id'] as int,
            child: Text(b['nama'] as String),
          ),
        ),
      ],
      onChanged: (value) => setState(() => selectedBagianId = value),
    );
  }

  Widget _buildSaveButton() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isLoading
          ? const Center(
              key: ValueKey('loading'),
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
              key: const ValueKey('button'),
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  isEditMode ? 'Simpan Perubahan' : 'Tambah User',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }
}
