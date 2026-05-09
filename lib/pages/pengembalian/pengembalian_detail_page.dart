import 'package:flutter/material.dart';
import '../../services/pengembalian_service.dart';

class PengembalianDetailPage extends StatefulWidget {
  final String hashid;

  const PengembalianDetailPage({super.key, required this.hashid});

  @override
  State<PengembalianDetailPage> createState() => _PengembalianDetailPageState();
}

class _PengembalianDetailPageState extends State<PengembalianDetailPage> {
  bool isLoading = true;
  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final result = await PengembalianService.getById(widget.hashid);

    if (result['status'] == true) {
      setState(() {
        data = result['data'];
      });
    }

    setState(() => isLoading = false);
  }

  Widget _item(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label)),
          const Text(": "),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final item = data ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text("Detail Pengembalian")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _item("Nama Sparepart", item['sparepart']?['nama_part'] ?? '-'),
                _item("User", item['user']?['name'] ?? '-'),
                _item("Bagian", item['bagian']?['nama'] ?? '-'),

                const Divider(),

                _item(
                  "Jumlah Diambil",
                  "${item['pengambilan']?['jumlah'] ?? 0}",
                ),
                _item(
                  "Jumlah Dikembalikan",
                  "${item['jumlah_dikembalikan'] ?? 0}",
                ),

                const Divider(),

                _item("Kondisi", item['kondisi'] ?? '-'),
                _item("Alasan", item['alasan'] ?? '-'),
                _item(
                  "Tanggal",
                  item['created_at']?.toString().substring(0, 10) ?? '-',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
