import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../config/api.dart';
import 'edit_profile_page.dart';
import '../auth/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);

    final result = await AuthService.getProfile();

    if (result['status'] == true && result['user'] != null) {
      final user = result['user'];
      setState(() {
        userData = user;
      });

      print('✅ Profile loaded: $user');
      print('🖼️ Profile Photo Path: ${user['profile_photo_path']}');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal memuat profil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final photoPath = userData?['profile_photo_path'];

    // Path gambar yang BENAR
    final imageUrl = photoPath != null && photoPath.toString().isNotEmpty
        ? '${Apiimg.baseUrl}/images/profile/$photoPath' // ← Pakai Api.baseUrl
        : null;

    print('🖼️ Final Image URL: $imageUrl');

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
          ? const Center(child: Text('Gagal memuat profil'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Foto Profil
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: imageUrl != null
                        ? NetworkImage(imageUrl)
                        : null,
                    child: imageUrl == null
                        ? Text(
                            (userData!['name'] ?? 'U')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 50,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),

                  Text(
                    userData!['name'] ?? '-',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userData!['email'] ?? '-',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),

                  Chip(
                    label: Text(
                      (userData!['role'] ?? '').toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.blue,
                  ),

                  const SizedBox(height: 40),

                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Edit Profil'),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfilePage(userData: userData),
                        ),
                      );
                      if (result == true && mounted) {
                        _loadProfile();
                      }
                    },
                  ),

                  const Divider(),

                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Keluar',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      await AuthService.logout();
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
