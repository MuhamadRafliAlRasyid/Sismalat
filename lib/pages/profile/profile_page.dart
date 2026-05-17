// lib/pages/profile/profile_page.dart
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
      setState(() => userData = result['user']);
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
    final photoPath =
        userData?['profile_photo_path'] ?? userData?['profile_photo_url'];
    final imageUrl = photoPath != null && photoPath.toString().isNotEmpty
        ? (photoPath.toString().startsWith('http')
              ? photoPath.toString()
              : '${Apiimg.baseUrl}/images/profile/$photoPath') // ✅ pakai Apiimg
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFFEF9E7),
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? _buildShimmerLoading()
          : userData == null
          ? const Center(child: Text('Gagal memuat profil'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _fadeInSection(0, _buildAvatar(imageUrl)),
                  const SizedBox(height: 20),
                  _fadeInSection(1, _buildNameRole()),
                  const SizedBox(height: 32),
                  _fadeInSection(2, _buildInfoCard()),
                  const SizedBox(height: 24),
                  _fadeInSection(3, _buildEditButton()),
                  const SizedBox(height: 12),
                  _fadeInSection(4, _buildLogoutButton()),
                ],
              ),
            ),
    );
  }

  Widget _fadeInSection(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 80)),
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

  Widget _buildAvatar(String? imageUrl) {
    return Hero(
      tag: 'profileAvatar',
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 70,
            backgroundColor: Colors.amber.shade100,
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
            child: imageUrl == null
                ? Text(
                    (userData!['name'] ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 50, color: Colors.white),
                  )
                : null,
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFFD97706),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameRole() {
    return Column(
      children: [
        Text(
          userData!['name'] ?? '-',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          userData!['email'] ?? '-',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: (userData!['role'] ?? '') == 'admin'
                ? const Color(0xFFFEF3C7)
                : Colors.amber.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD97706).withOpacity(0.3)),
          ),
          child: Text(
            (userData!['role'] ?? 'karyawan').toUpperCase(),
            style: const TextStyle(
              color: Color(0xFFD97706),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _profileTile(Icons.person, 'Nama', userData!['name'] ?? '-'),
            const Divider(),
            _profileTile(
              Icons.email_outlined,
              'Email',
              userData!['email'] ?? '-',
            ),
            if (userData!['bagian'] != null) ...[
              const Divider(),
              _profileTile(
                Icons.business_outlined,
                'Bagian',
                userData!['bagian']['nama'] ??
                    userData!['bagian']['nama_bagian'] ??
                    '-',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _profileTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD97706), size: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditProfilePage(userData: userData),
            ),
          );
          if (result == true && mounted) _loadProfile();
        },
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Edit Profil'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD97706),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Keluar?'),
              content: const Text('Anda akan keluar dari akun ini.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Keluar'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await AuthService.logout();
            if (mounted)
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
          }
        },
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text('Keluar', style: TextStyle(color: Colors.red)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          CircleAvatar(radius: 70, backgroundColor: Colors.grey.shade300),
          const SizedBox(height: 20),
          Container(width: 150, height: 20, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Container(width: 100, height: 16, color: Colors.grey.shade200),
          const SizedBox(height: 40),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.grey.shade300),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 14,
                            color: Colors.grey.shade200,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
