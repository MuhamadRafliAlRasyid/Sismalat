import 'package:flutter/material.dart';
import '../../services/barang_service.dart';

class TrashedBarangPage extends StatefulWidget {
  const TrashedBarangPage({super.key});

  @override
  State<TrashedBarangPage> createState() => _TrashedBarangPageState();
}

class _TrashedBarangPageState extends State<TrashedBarangPage> {
  List<dynamic> trashedList = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTrashed();
  }

  Future<void> _loadTrashed() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await BarangService.getTrashed();

    if (result['status'] == true) {
      setState(() {
        trashedList = result['data'] ?? [];
      });
      print('✅ Trashed loaded successfully: ${trashedList.length} items');
      if (trashedList.isNotEmpty) {
        print('Sample trashed item: ${trashedList.first}');
      }
    } else {
      setState(() {
        errorMessage = result['message'] ?? 'Gagal memuat data barang terhapus';
      });
      print('❌ Trashed error: ${result['message']}');
    }

    setState(() => isLoading = false);
  }

  Future<void> _restoreBarang(String hashid, String namaPart) async {
    if (hashid.isEmpty) {
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
      builder: (ctx) => AlertDialog(
        title: const Text('Kembalikan Barang?'),
        content: Text('Yakin ingin mengembalikan "$namaPart"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Kembalikan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await BarangService.restore(hashid);

    if (result['status'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Barang berhasil dikembalikan'),
          backgroundColor: Colors.green,
        ),
      );
      _loadTrashed();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal mengembalikan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _forceDelete(String hashid, String namaPart) async {
    if (hashid.isEmpty) {
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
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Permanen?'),
        content: Text(
          'Yakin ingin menghapus "$namaPart" secara permanen?\n\nData ini tidak dapat dikembalikan!',
          style: const TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await BarangService.forceDelete(hashid);

    if (result['status'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Barang dihapus permanen'),
          backgroundColor: Colors.green,
        ),
      );
      _loadTrashed();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal menghapus permanen'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barang Terhapus'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTrashed),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadTrashed,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : trashedList.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Tidak ada barang terhapus',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadTrashed,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: trashedList.length,
                itemBuilder: (context, index) {
                  final item = trashedList[index];
                  final hashid = item['hashid']?.toString() ?? '';
                  final namaPart = item['nama_part'] ?? 'Barang Tidak Dikenal';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      title: Text(
                        namaPart,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        "${item['model'] ?? '-'} • ${item['merk'] ?? '-'}",
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            onPressed: hashid.isNotEmpty
                                ? () => _restoreBarang(hashid, namaPart)
                                : null,
                            icon: const Icon(
                              Icons.restore,
                              color: Colors.green,
                            ),
                            label: const Text(
                              'Kembalikan',
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_forever,
                              color: Colors.red,
                            ),
                            onPressed: hashid.isNotEmpty
                                ? () => _forceDelete(hashid, namaPart)
                                : null,
                            tooltip: 'Hapus Permanen',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
