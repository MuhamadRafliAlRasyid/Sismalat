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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Bagian?'),
        content: Text('Yakin ingin menghapus "$nama"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hapus'),
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
      backgroundColor: const Color(0xFFFEF9E7),
      appBar: AppBar(
        title: const Text('Daftar Bagian'),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadBagian,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD97706)),
            )
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
            )
          : bagianList.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.business, size: 72, color: Colors.amber.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada data bagian',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFFD97706),
              onRefresh: _loadBagian,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: bagianList.length,
                itemBuilder: (context, index) {
                  final bagian = bagianList[index];
                  final hashid = bagian['hashid']?.toString() ?? '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 1,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors.amber.shade100,
                        child: Icon(
                          Icons.business,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                      title: Text(
                        bagian['nama'] ?? '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Color(0xFFD97706),
                            ),
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
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
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
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        elevation: 4,
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
