import 'package:flutter/material.dart';
import '../../config/api.dart';
import '../../services/auth_service.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({String? search}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔄 [UserListPage] Loading users...');

      final result = await AuthService.getAllUsers(search: search);

      print('📦 [UserListPage] Response keys: ${result.keys.toList()}');
      print('📦 [UserListPage] Success: ${result['success']}');

      if (result['success'] == true) {
        final data = result['data'];

        if (data is List) {
          setState(() {
            _users = data;
          });
          print('✅ [UserListPage] Total users loaded: ${_users.length}');
        } else {
          throw Exception('Format data tidak valid: ${data.runtimeType}');
        }
      } else {
        throw Exception(result['message'] ?? 'Gagal memuat data user');
      }
    } catch (e) {
      print('❌ [UserListPage] Error: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _deleteUser(String hashid, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus User?'),
        content: Text('Yakin ingin menghapus user "$userName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await AuthService.deleteUser(hashid);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
      _loadUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal menghapus'),
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
        title: const Text(
          'Daftar User',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadUsers(search: _searchCtrl.text),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? _buildShimmerList()
                : _errorMessage != null
                ? _buildError()
                : _users.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    color: const Color(0xFFD97706),
                    onRefresh: () => _loadUsers(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return _UserCard(
                          user: user,
                          onDelete: () => _deleteUser(
                            user['hashid']?.toString() ?? '',
                            user['name'] ?? 'User',
                          ),
                          onEdit: () async {
                            final result = await Navigator.pushNamed(
                              context,
                              '/user/form',
                              arguments: user['hashid']?.toString(),
                            );
                            if (result == true) _loadUsers();
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/user/form');
          if (result == true) _loadUsers();
        },
        backgroundColor: const Color(0xFFD97706),
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah User'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Cari user...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFD97706)),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchCtrl.clear();
                    _loadUsers();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
        ),
        onSubmitted: (v) => _loadUsers(search: v),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          title: Container(
            height: 16,
            width: double.infinity,
            color: Colors.grey.shade200,
          ),
          subtitle: Container(
            height: 12,
            width: 120,
            color: Colors.grey.shade200,
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Gagal memuat data',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _loadUsers(),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 72, color: Colors.amber.shade200),
          const SizedBox(height: 12),
          Text(
            'Belum ada user',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// ================== USER CARD ==================
class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _UserCard({
    required this.user,
    required this.onDelete,
    required this.onEdit,
  });

  /// ✅ Helper untuk mendapatkan URL foto profile yang benar
  /// Prioritas:
  /// 1. URL eksternal (Google, ui-avatars) → return langsung
  /// 2. Path relatif → gabungkan dengan /images/profile/
  /// 3. URL localhost yang rusak → extract URL asli
  String? _getPhotoUrl(dynamic photoPath) {
    if (photoPath == null) return null;

    final photoStr = photoPath.toString().trim();
    if (photoStr.isEmpty) return null;

    // 1. ✅ Jika URL eksternal (Google, ui-avatars, dll), return langsung
    if (photoStr.startsWith('https://') &&
        (photoStr.contains('googleusercontent') ||
            photoStr.contains('ui-avatars') ||
            photoStr.contains('google.com') ||
            photoStr.contains('lh3.') ||
            photoStr.contains('gstatic'))) {
      return photoStr;
    }

    // 2. ✅ Jika URL localhost yang rusak (prefix ganda)
    // Contoh: http://127.0.0.1:8000/storage/https://lh3.googleusercontent.com/...
    if (photoStr.contains('/storage/https://') ||
        photoStr.contains('/storage/http://')) {
      // Extract URL asli setelah /storage/
      final match = RegExp(r'/storage/(https?://.+)$').firstMatch(photoStr);
      if (match != null) {
        return match.group(1);
      }
    }

    // 3. ✅ Jika sudah URL localhost/127.0.0.1 yang valid, extract path-nya
    if (photoStr.startsWith('http://127.0.0.1') ||
        photoStr.startsWith('http://localhost')) {
      // Extract bagian setelah /images/profile/ atau /storage/
      if (photoStr.contains('/images/profile/')) {
        final afterPath = photoStr.split('/images/profile/').last;
        return '${Apiimg.baseUrl}/images/profile/$afterPath';
      }
      if (photoStr.contains('/storage/')) {
        final afterPath = photoStr.split('/storage/').last;
        // Jika path yang diekstrak adalah URL eksternal, return langsung
        if (afterPath.startsWith('http://') ||
            afterPath.startsWith('https://')) {
          return afterPath;
        }
        return '${Apiimg.baseUrl}/storage/$afterPath';
      }
    }

    // 4. ✅ Jika sudah URL http/https yang valid, return langsung
    if (photoStr.startsWith('http://') || photoStr.startsWith('https://')) {
      return photoStr;
    }

    // 5. ✅ Jika path relatif, gabungkan dengan /images/profile/
    // Karena foto profile disimpan di public/images/profile/
    String cleanPath = photoStr;

    // Hapus prefix 'images/profile/' atau 'storage/' jika ada
    if (cleanPath.startsWith('images/profile/')) {
      cleanPath = cleanPath.substring('images/profile/'.length);
    } else if (cleanPath.startsWith('storage/')) {
      cleanPath = cleanPath.substring('storage/'.length);
    }

    return '${Apiimg.baseUrl}/images/profile/$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    final name = user['name'] ?? 'Tanpa Nama';
    final email = user['email'] ?? '-';
    final role = user['role'] ?? 'karyawan';
    final bagian = user['bagian']?['nama'] ?? '-';

    final photoPath = user['profile_photo_url'] ?? user['profile_photo_path'];
    final imageUrl = _getPhotoUrl(photoPath);

    // Debug
    print('🖼️ [UserCard] name=$name');
    print('   📥 photoPath: $photoPath');
    print('   🖼️ imageUrl: $imageUrl');

    Color roleColor;
    switch (role.toString().toLowerCase()) {
      case 'super':
        roleColor = Colors.purple;
        break;
      case 'admin':
        roleColor = Colors.blue;
        break;
      default:
        roleColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildAvatar(imageUrl, name),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            role.toString().toUpperCase(),
                            style: TextStyle(
                              color: roleColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (bagian != '-')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              bagian,
                              style: const TextStyle(
                                color: Color(0xFFD97706),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20, color: Color(0xFFD97706)),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? imageUrl, String name) {
    // Jika tidak ada URL, tampilkan inisial
    if (imageUrl == null || imageUrl.isEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: Colors.amber.shade100,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD97706),
          ),
        ),
      );
    }

    // ✅ Tampilkan foto dengan error handling
    return ClipOval(
      child: Image.network(
        imageUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          print('❌ [Avatar] Gagal load: $imageUrl');
          return Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD97706),
                ),
              ),
            ),
          );
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD97706)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
