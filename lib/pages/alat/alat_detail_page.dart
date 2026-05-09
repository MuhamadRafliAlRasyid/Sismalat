import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ← wajib
import '../../services/alat_service.dart';

class AlatDetailPage extends StatelessWidget {
  final String hashid;

  const AlatDetailPage({
    super.key,
    required this.hashid,
  }); // perbaiki constructor

  @override
  Widget build(BuildContext context) {
    // ambil service dari provider
    final alatService = context.read<AlatService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Alat')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: alatService.getAlat(hashid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final alat = snapshot.data!['data'];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto besar
                if (alat['foto_url'] != null)
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            child: InteractiveViewer(
                              child: Image.network(alat['foto_url']),
                            ),
                          ),
                        );
                      },
                      child: Hero(
                        tag: 'foto_${alat['hashid']}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            alat['foto_url'],
                            height: 250,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                _buildInfoCard('Nama Alat', alat['nama_alat']),
                _buildInfoCard('Merk', alat['merk']),
                _buildInfoCard('Tipe', alat['tipe']),
                _buildInfoCard('Status', alat['status']),
                // QR Code
                if (alat['qr_code'] != null)
                  Center(
                    child: Image.network(
                      '${alatService.baseUrl}/storage/${alat['qr_code']}',
                      width: 150,
                    ),
                  ),
                const Divider(),
                Text(
                  'Riwayat Kalibrasi',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                FutureBuilder<Map<String, dynamic>>(
                  future: alatService.getKalibrasiByAlat(hashid),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snap.hasError) {
                      return const Text('Gagal memuat riwayat');
                    }
                    final list = snap.data!['data'] as List<dynamic>;
                    return Column(
                      children: list.map((k) {
                        return ListTile(
                          title: Text(k['tanggal_kalibrasi'] ?? ''),
                          subtitle: Text(
                            'Sertifikat: ${k['no_sertifikat'] ?? ''}',
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String label, String? value) {
    return Card(
      child: ListTile(
        title: Text(label, style: const TextStyle(color: Colors.grey)),
        trailing: Text(
          value ?? '-',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
