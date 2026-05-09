import 'package:flutter/material.dart';
import '../../services/pengambilan_alat_service.dart';

class PengambilanAlatListPage extends StatefulWidget {
  const PengambilanAlatListPage({super.key});

  @override
  State<PengambilanAlatListPage> createState() =>
      _PengambilanAlatListPageState();
}

class _PengambilanAlatListPageState extends State<PengambilanAlatListPage> {
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
    final result = await PengambilanAlatService.getAll(search: search);
    if (result['status'] == true) {
      setState(() => list = result['data'] ?? []);
    } else {
      setState(() => errorMessage = result['message'] ?? 'Gagal memuat data');
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengambilan Alat')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : ListView.builder(
              itemCount: list.length,
              itemBuilder: (ctx, i) {
                final d = list[i];
                return ListTile(
                  title: Text(d['alat']?['nama_alat'] ?? '-'),
                  subtitle: Text('${d['jumlah']} ${d['satuan']}'),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/pengambilan-alat/detail',
                    arguments: d['hashid'],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/pengambilan-alat/form');
          _loadData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
