// lib/pages/alat/alat_list_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/provider/alat_provider.dart'; // perbaikan path
import 'alat_detail_page.dart';
import 'alat_form_page.dart';

class AlatListPage extends StatefulWidget {
  const AlatListPage({super.key}); // tambahkan key

  @override
  State<AlatListPage> createState() => _AlatListPageState();
}

class _AlatListPageState extends State<AlatListPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedKategori;

  @override
  void initState() {
    super.initState();
    // Panggil setelah frame pertama agar context tersedia
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlatProvider>().fetchAlats(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<AlatProvider>();
      if (!provider.isLoading && provider.hasMore) {
        provider.fetchAlats();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Alat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => Navigator.pushNamed(context, '/alat/trashed'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AlatFormPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: Column(
        children: [
          // Search & Filter
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari nama, merk...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (value) {
                      context.read<AlatProvider>().setSearch(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String?>(
                  value: _selectedKategori,
                  hint: const Text('Kategori'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Semua')),
                    // isi dengan data kategori dari provider lain
                  ],
                  onChanged: (val) {
                    setState(() => _selectedKategori = val);
                    context.read<AlatProvider>().setKategori(val);
                  },
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: Consumer<AlatProvider>(
              builder: (context, provider, child) {
                // jika provider null (tidak terdaftar) tampilkan loading
                if (provider == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error: ${provider.errorMessage}'),
                    ),
                  );
                }
                if (provider.alats.isEmpty && !provider.isLoading) {
                  return const Center(child: Text('Tidak ada data alat'));
                }
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: provider.alats.length + (provider.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == provider.alats.length) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final alat = provider.alats[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: alat['foto_thumb'] != null
                              ? NetworkImage(alat['foto_thumb'])
                              : null,
                          child: alat['foto_thumb'] == null
                              ? const Icon(Icons.build)
                              : null,
                        ),
                        title: Text(alat['nama_alat'] ?? ''),
                        subtitle: Text(
                          '${alat['merk'] ?? ''} - ${alat['tipe'] ?? ''}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AlatDetailPage(
                                    hashid: alat['hashid'] ?? '',
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AlatFormPage(
                                    hashid: alat['hashid'] ?? '',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
