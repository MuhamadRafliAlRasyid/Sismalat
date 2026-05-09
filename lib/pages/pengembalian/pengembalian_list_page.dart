import 'package:flutter/material.dart';
import '../../services/pengembalian_service.dart';
import 'pengembalian_form_page.dart';
import 'pengembalian_detail_page.dart';

class PengembalianListPage extends StatefulWidget {
  const PengembalianListPage({super.key});

  @override
  State<PengembalianListPage> createState() => _PengembalianListPageState();
}

class _PengembalianListPageState extends State<PengembalianListPage> {
  List<dynamic> list = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPengembalian();
  }

  Future<void> _loadPengembalian() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await PengembalianService.getAll();

    if (result['status'] == true) {
      setState(() {
        list = result['data'] ?? [];
      });
    } else {
      setState(() {
        errorMessage = result['message'] ?? 'Gagal memuat data pengembalian';
      });
    }

    setState(() => isLoading = false);
  }

  Future<void> _deletePengembalian(String hashid, String namaSparepart) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pengembalian?'),
        content: Text('Yakin ingin menghapus pengembalian "$namaSparepart"?'),
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

    final result = await PengembalianService.delete(hashid);

    if (result['status'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengembalian berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
      _loadPengembalian();
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
        title: const Text('Daftar Pengembalian'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPengembalian,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadPengembalian,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : list.isEmpty
          ? const Center(child: Text('Belum ada data pengembalian'))
          : RefreshIndicator(
              onRefresh: _loadPengembalian,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
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
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        namaSparepart,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("User: ${item['user']?['name'] ?? '-'}"),
                          Text(
                            "Jumlah Dikembalikan: ${item['jumlah_dikembalikan'] ?? 0}",
                          ),
                          Text(
                            "Kondisi: ${item['kondisi']?.toUpperCase() ?? '-'}",
                          ),
                          if (item['alasan'] != null &&
                              item['alasan'].toString().isNotEmpty)
                            Text("Alasan: ${item['alasan']}"),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () async {
                              final result = await Navigator.pushNamed(
                                context,
                                '/pengembalian/form',
                                arguments:
                                    hashid, // ← Kirim langsung String hashid
                              );
                              if (result == true) _loadPengembalian();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _deletePengembalian(hashid, namaSparepart),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/pengembalian/detail',
                          arguments: hashid,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            '/pengembalian/form',
          );
          if (result == true) _loadPengembalian();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
