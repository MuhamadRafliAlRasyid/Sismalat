import 'package:flutter/material.dart';
import '../../services/pengambilan_service.dart';
import 'pengambilan_form_page.dart'; // jika ada form edit

class PengambilanListPage extends StatefulWidget {
  const PengambilanListPage({super.key});

  @override
  State<PengambilanListPage> createState() => _PengambilanListPageState();
}

class _PengambilanListPageState extends State<PengambilanListPage> {
  List<dynamic> list = [];
  bool isLoading = true;
  String? errorMessage;
  String? searchQuery;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({String? search}) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      searchQuery = search;
    });

    final result = await PengambilanService.getAll(search: search);

    if (result['status'] == true) {
      setState(() {
        list = result['data'] ?? [];
      });
    } else {
      setState(() {
        errorMessage = result['message'] ?? 'Gagal memuat data pengambilan';
      });
    }

    setState(() => isLoading = false);
  }

  Future<void> _deletePengambilan(String hashid, String namaSparepart) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengambilan'),
        content: Text('Yakin ingin menghapus pengambilan "$namaSparepart"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await PengambilanService.delete(hashid);

    if (result['status'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengambilan berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData(search: searchQuery);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Gagal menghapus')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Pengambilan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadData(search: searchQuery),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari sparepart atau keperluan...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                Future.delayed(const Duration(milliseconds: 600), () {
                  if (mounted) _loadData(search: value.trim());
                });
              },
            ),
          ),

          // List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _loadData(search: searchQuery),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
                : list.isEmpty
                ? const Center(child: Text('Belum ada data pengambilan'))
                : RefreshIndicator(
                    onRefresh: () => _loadData(search: searchQuery),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final item = list[index];
                        final hashid = item['hashid']?.toString() ?? '';
                        final namaSparepart =
                            item['sparepart']?['nama_part'] ??
                            item['nama_part'] ??
                            '-';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              namaSparepart,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("User: ${item['user']?['name'] ?? '-'}"),
                                Text(
                                  "Jumlah: ${item['jumlah']} ${item['satuan'] ?? ''}",
                                ),
                                Text("Keperluan: ${item['keperluan'] ?? '-'}"),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  Navigator.pushNamed(
                                    context,
                                    '/pengambilan/form',
                                    arguments: hashid,
                                  );
                                } else if (value == 'delete') {
                                  _deletePengambilan(hashid, namaSparepart);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Hapus',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/pengambilan/detail',
                              arguments: hashid,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            '/pengambilan/form',
          );
          if (result == true) _loadData(search: searchQuery);
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Pengambilan'),
      ),
    );
  }
}
