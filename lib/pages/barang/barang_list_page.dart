import 'package:flutter/material.dart';
import '../../services/barang_service.dart';

class BarangListPage extends StatefulWidget {
  const BarangListPage({super.key});

  @override
  State<BarangListPage> createState() => _BarangListPageState();
}

class _BarangListPageState extends State<BarangListPage> {
  List<dynamic> barangList = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMoreData = true;

  int currentPage = 1;
  String? searchQuery;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadBarang();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoadingMore &&
          hasMoreData) {
        _loadMoreBarang();
      }
    });
  }

  Future<void> _loadBarang({String? search}) async {
    setState(() {
      isLoading = true;
      currentPage = 1;
      searchQuery = search;
      barangList.clear();
    });

    final result = await BarangService.getAll(search: search, page: 1);

    if (result['status'] == true) {
      final items = result['data'] ?? [];
      setState(() {
        barangList = items;
        hasMoreData =
            (result['meta']?['current_page'] ?? 1) <
            (result['meta']?['last_page'] ?? 1);
      });

      // Debug: cek apakah hashid ada di data
      if (items.isNotEmpty) {
        print('DEBUG - Sample item hashid: ${items.first['hashid']}');
        print('DEBUG - Sample full item: ${items.first}');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Gagal memuat data')),
      );
    }

    setState(() => isLoading = false);
  }

  Future<void> _loadMoreBarang() async {
    if (isLoadingMore || !hasMoreData) return;

    setState(() => isLoadingMore = true);
    currentPage++;

    final result = await BarangService.getAll(
      search: searchQuery,
      page: currentPage,
    );

    if (result['status'] == true) {
      setState(() {
        barangList.addAll(result['data'] ?? []);
        hasMoreData =
            (result['meta']?['current_page'] ?? 1) <
            (result['meta']?['last_page'] ?? 1);
      });
    }

    setState(() => isLoadingMore = false);
  }

  Future<void> _deleteBarang(String? hashid, String namaPart) async {
    if (hashid == null || hashid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hash ID tidak ditemukan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Yakin ingin menghapus "$namaPart"?'),
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

    final result = await BarangService.delete(hashid);

    if (result['status'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$namaPart berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
      _loadBarang(search: searchQuery);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Gagal menghapus')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Barang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadBarang(search: searchQuery),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Barang Terhapus',
            onPressed: () => Navigator.pushNamed(context, '/barang/trashed'),
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
                hintText: 'Cari nama part, model, atau merk...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                Future.delayed(const Duration(milliseconds: 600), () {
                  if (mounted) _loadBarang(search: value.trim());
                });
              },
            ),
          ),

          // List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : barangList.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Tidak ada data barang',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _loadBarang(search: searchQuery),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: barangList.length + (isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == barangList.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final barang = barangList[index];
                        final hashid = barang['hashid']?.toString() ?? '';
                        final namaPart = barang['nama_part'] ?? '-';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            title: Text(
                              namaPart,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              "${barang['model'] ?? '-'} • ${barang['merk'] ?? '-'}",
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Baru: ${barang['jumlah_baru'] ?? 0}",
                                      style: const TextStyle(
                                        color: Colors.blue,
                                      ),
                                    ),
                                    Text(
                                      "Bekas: ${barang['jumlah_bekas'] ?? 0}",
                                      style: const TextStyle(
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      Navigator.pushNamed(
                                        context,
                                        '/barang/form',
                                        arguments: hashid,
                                      );
                                    } else if (value == 'delete') {
                                      _deleteBarang(hashid, namaPart);
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
                              ],
                            ),
                            onTap: () {
                              if (hashid.isNotEmpty) {
                                Navigator.pushNamed(
                                  context,
                                  '/barang/detail',
                                  arguments: hashid,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Hash ID tidak ditemukan'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
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
          final result = await Navigator.pushNamed(context, '/barang/form');
          if (result == true) _loadBarang(search: searchQuery);
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Barang'),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
