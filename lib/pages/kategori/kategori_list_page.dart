import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/kategori_provider.dart';
import 'kategori_form_page.dart';

class KategoriListPage extends StatefulWidget {
  const KategoriListPage({Key? key}) : super(key: key);

  @override
  State<KategoriListPage> createState() => _KategoriListPageState();
}

class _KategoriListPageState extends State<KategoriListPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KategoriProvider>().fetchKategoris();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KategoriProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFEF9E7), // latar krem
      appBar: AppBar(
        title: const Text(
          'Kategori Alat',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            tooltip: 'Tambah Kategori',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KategoriFormPage()),
              );
              provider.fetchKategoris();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar modern
          Container(
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
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari kategori...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Icon(
                    Icons.search_rounded,
                    color: const Color(0xFFD97706),
                  ),
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchCtrl.clear();
                          provider.fetchKategoris();
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
              onChanged: (_) => setState(() {}),
              onSubmitted: (v) => provider.fetchKategoris(search: v),
            ),
          ),
          // Konten Utama
          Expanded(
            child: provider.isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Color(0xFFD97706),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Memuat kategori...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : provider.error != null
                ? _buildErrorState(provider)
                : provider.kategoris.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    color: const Color(0xFFD97706),
                    onRefresh: () => provider.fetchKategoris(),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      itemCount: provider.kategoris.length,
                      itemBuilder: (ctx, i) {
                        final kat = provider.kategoris[i];
                        return _buildKategoriCard(kat);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Kartu Kategori
  Widget _buildKategoriCard(dynamic kat) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shadowColor: Colors.amber.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          // Bisa langsung edit
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => KategoriFormPage(hashid: kat.hashid),
            ),
          ).then((_) => context.read<KategoriProvider>().fetchKategoris());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ikon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.category,
                  color: Color(0xFFD97706),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Informasi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kat.nama ?? 'Tanpa Nama',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (kat.keterangan != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          kat.keterangan!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Kolom aksi
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tombol edit kecil
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                KategoriFormPage(hashid: kat.hashid),
                          ),
                        ).then(
                          (_) =>
                              context.read<KategoriProvider>().fetchKategoris(),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 22,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ),
                  ),
                  // Tombol hapus
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _confirmDelete(kat.hashid, kat.nama),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.delete_outline,
                          size: 22,
                          color: Colors.redAccent,
                        ),
                      ),
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

  // State error
  Widget _buildErrorState(KategoriProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              provider.error ?? 'Gagal memuat data',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => provider.fetchKategoris(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // State kosong
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category_outlined,
              size: 72,
              color: Colors.amber.shade200,
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada kategori',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tambahkan kategori dengan tombol +',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  // Konfirmasi hapus
  void _confirmDelete(String hashid, String nama) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Kategori?'),
        content: Text('Kategori "$nama" akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<KategoriProvider>().delete(hashid);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
