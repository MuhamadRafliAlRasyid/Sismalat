import 'package:flutter/material.dart';
import '../../services/pengambilan_alat_service.dart';

class PengambilanAlatDetailPage extends StatelessWidget {
  final String hashid;
  const PengambilanAlatDetailPage({super.key, required this.hashid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pengambilan')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: PengambilanAlatService.getById(hashid),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data?['data'];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Alat: ${data?['alat']?['nama_alat'] ?? '-'}'),
              Text('Jumlah: ${data?['jumlah']} ${data?['satuan']}'),
              Text('Keperluan: ${data?['keperluan'] ?? '-'}'),
              Text('Status: ${data?['status'] ?? '-'}'),
            ],
          );
        },
      ),
    );
  }
}
