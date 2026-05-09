import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../config/api.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>?
  userData; // null = Tambah User, ada data = Edit Profil

  const EditProfilePage({super.key, this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  File? _selectedImage;
  String? _currentPhotoPath;

  // Hanya untuk Tambah User
  String? selectedRole = 'karyawan';
  int? selectedBagianId;

  final List<Map<String, dynamic>> bagianList = [
    {'id': 1, 'nama': 'Bagian Umum'},
    {'id': 2, 'nama': 'Bagian Keuangan'},
    {'id': 3, 'nama': 'Bagian Produksi'},
    {'id': 4, 'nama': 'Bagian Logistik'},
  ];

  bool get isEditMode => widget.userData != null;

  @override
  void initState() {
    super.initState();

    if (isEditMode && widget.userData != null) {
      final user = widget.userData!;
      _nameCtrl.text = user['name'] ?? '';
      _emailCtrl.text = user['email'] ?? '';
      _currentPhotoPath = user['profile_photo_path'];

      selectedRole = user['role'];
      selectedBagianId = user['bagian_id'];
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

    setState(() => isLoading = true);

    Map<String, dynamic> result;

    if (isEditMode && widget.userData != null) {
      final hashid =
          widget.userData!['hashid'] as String? ??
          widget.userData!['id']?.toString() ??
          '';

      final nameToSend = _nameCtrl.text.trim();

      print(
        '🔄 Mencoba UPDATE USER -> hashid: $hashid | name: "$nameToSend" | length: ${nameToSend.length}',
      );

      result = await AuthService.updateUser(
        hashid: hashid,
        name: _nameCtrl.text.trim(), // Pastikan ini tidak kosong
        email: null,
        role: null,
        bagianId: null,
        password: _passwordCtrl.text.trim().isNotEmpty
            ? _passwordCtrl.text.trim()
            : null,
        photo: _selectedImage,
      );
    } else {
      result = await AuthService.register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        role: selectedRole,
        bagianId: selectedBagianId,
      );
    }

    setState(() => isLoading = false);

    print(
      '📥 HASIL SAVE: status=${result['status']}, message=${result['message']}',
    );

    if (result['status'] == true && mounted) {
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
    } else if (mounted) {
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
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Profil' : 'Tambah User'),
        backgroundColor: const Color(0xFF001F3F),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Foto Profil
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 70,
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : (_currentPhotoPath != null
                                      ? NetworkImage(
                                          '${Api.baseUrl}/images/profile/$_currentPhotoPath',
                                        )
                                      : null),
                            child:
                                _selectedImage == null &&
                                    _currentPhotoPath == null
                                ? const Icon(
                                    Icons.person,
                                    size: 80,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.blue,
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ketuk untuk mengganti foto',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 30),

                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.trim().isEmpty ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    if (!isEditMode)
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value!.trim().isEmpty ? 'Email wajib diisi' : null,
                      ),
                    if (!isEditMode) const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: isEditMode
                            ? 'Password Baru (kosongkan jika tidak diubah)'
                            : 'Password',
                        border: const OutlineInputBorder(),
                      ),
                      validator: isEditMode
                          ? null
                          : (value) =>
                                value!.isEmpty ? 'Password wajib diisi' : null,
                    ),
                    const SizedBox(height: 24),

                    if (!isEditMode) ...[
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Admin'),
                          ),
                          DropdownMenuItem(
                            value: 'karyawan',
                            child: Text('Karyawan'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => selectedRole = value),
                        validator: (value) =>
                            value == null ? 'Pilih Role' : null,
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<int>(
                        value: selectedBagianId,
                        decoration: const InputDecoration(
                          labelText: 'Bagian',
                          border: OutlineInputBorder(),
                        ),
                        items: bagianList
                            .map(
                              (b) => DropdownMenuItem<int>(
                                value: b['id'] as int,
                                child: Text(b['nama']),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedBagianId = value),
                      ),
                    ],

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF001F3F),
                        ),
                        child: Text(
                          isEditMode ? 'Simpan Perubahan' : 'Tambah User',
                          style: const TextStyle(fontSize: 18),
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
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }
}
