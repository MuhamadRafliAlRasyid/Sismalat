import 'package:flutter/material.dart';
import '../../services/auth_service.dart'; // Buat service ini nanti
import 'edit_profile_page.dart'; // Halaman tambah/edit user

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  List<dynamic> users = [];
  bool isLoading = true;
  String? searchQuery;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers({String? search}) async {
    setState(() => isLoading = true);

    final result = await AuthService.getAllUsers(search: search);

    if (result['status'] == true) {
      setState(() {
        users = result['data'] ?? [];
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal memuat data user'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => isLoading = false);
  }

  void _onSearch(String query) {
    setState(() => searchQuery = query);
    _loadUsers(search: query);
  }

  Future<void> _deleteUser(String hashid, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus User?'),
        content: Text('Yakin ingin menghapus user "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await AuthService.deleteUser(hashid);

    if (result['status'] == true) { 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
      _loadUsers(search: searchQuery);
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
      appBar: AppBar(
        title: const Text('Daftar User'),
        backgroundColor: const Color(0xFF001F3F),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              );
              if (result == true) _loadUsers(search: searchQuery);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari nama, email, atau bagian...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _onSearch,
            ),
          ),

          // List User
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : users.isEmpty
                ? const Center(child: Text('Belum ada data user'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              (user['name'] ?? 'U')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            user['name'] ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user['email'] ?? '-'),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    user['bagian']?['nama_bagian'] ?? '-',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: user['role'] == 'admin'
                                          ? Colors.purple[100]
                                          : Colors.blue[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      (user['role'] ?? '').toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: user['role'] == 'admin'
                                            ? Colors.purple[800]
                                            : Colors.blue[800],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EditProfilePage(userData: user),
                                    ),
                                  );
                                  if (result == true)
                                    _loadUsers(search: searchQuery);
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteUser(
                                  user['hashid'] ?? '',
                                  user['name'] ?? '',
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfilePage()),
          );
          if (result == true) _loadUsers(search: searchQuery);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
