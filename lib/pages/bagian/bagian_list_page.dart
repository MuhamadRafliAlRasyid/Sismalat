import 'package:flutter/material.dart';
import '../../services/bagian_service.dart';
import 'bagian_form_page.dart';

class BagianListPage extends StatefulWidget {
  const BagianListPage({super.key});

  @override
  State<BagianListPage> createState() => _BagianListPageState();
}

class _BagianListPageState extends State<BagianListPage> {
  List<dynamic> bagianList = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBagian();
  }

  Future<void> _loadBagian() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await BagianService.getAll();

    if (result['status'] == true) {
      setState(() {
        bagianList = result['data'] ?? [];
      });
    } else {
      setState(() {
        errorMessage = result['message'] ?? 'Gagal memuat data bagian';
      });
    }

    setState(() => isLoading = false);
  }

  Future<void> _deleteBagian(String hashid, String nama) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Bagian?'),
        content: Text('Yakin ingin menghapus "$nama"?'),
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

    setState(() => isLoading = true);

    final result = await BagianService.delete(hashid);

    if (result['status'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bagian berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
      _loadBagian();
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
        title: const Text('Daftar Bagian'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadBagian),
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
                    onPressed: _loadBagian,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : bagianList.isEmpty
          ? const Center(child: Text('Belum ada data bagian'))
          : RefreshIndicator(
              onRefresh: _loadBagian,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: bagianList.length,
                itemBuilder: (context, index) {
                  final bagian = bagianList[index];
                  final hashid = bagian['hashid']?.toString() ?? '';

                  print("📦 Bagian item: $bagian");
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(bagian['nama'] ?? '-'),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BagianFormPage(hashid: hashid),
                                ),
                              );
                              if (result == true) _loadBagian();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _deleteBagian(hashid, bagian['nama'] ?? ''),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BagianFormPage()),
          );
          if (result == true) _loadBagian();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
