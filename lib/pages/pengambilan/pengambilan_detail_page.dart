// lib/pages/pengambilan/pengambilan_detail_page.dart
import 'package:flutter/material.dart';
import '../../services/pengambilan_service.dart';

class PengambilanDetailPage extends StatefulWidget {
  final String hashid;

  const PengambilanDetailPage({super.key, required this.hashid});

  @override
  State<PengambilanDetailPage> createState() => _PengambilanDetailPageState();
}

class _PengambilanDetailPageState extends State<PengambilanDetailPage> {
  Map<String, dynamic>? data;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final result = await PengambilanService.getById(widget.hashid);

    if (result['status'] == true) {
      setState(() => data = result['data']);
    } else {
      setState(() => errorMessage = result['message'] ?? 'Gagal memuat data');
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengambilan'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDetail),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(errorMessage, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadDetail,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : data == null
          ? const Center(child: Text('Data tidak ditemukan'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data!['sparepart']?['nama_part'] ??
                                'Pengambilan Sparepart',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(height: 30),
                          _infoRow(
                            Icons.person,
                            'User',
                            data!['user']?['name'] ?? '-',
                          ),
                          _infoRow(
                            Icons.business,
                            'Bagian',
                            data!['bagian']?['nama'] ?? '-',
                          ),
                          _infoRow(
                            Icons.inventory_2,
                            'Sparepart',
                            data!['sparepart']?['nama_part'] ?? '-',
                          ),
                          _infoRow(
                            Icons.format_list_numbered,
                            'Jumlah',
                            '${data!['jumlah']} ${data!['satuan'] ?? ''}',
                          ),
                          _infoRow(
                            Icons.label,
                            'Jenis',
                            data!['part_type'] == 'baru'
                                ? 'Part Baru'
                                : 'Part Bekas',
                          ),
                          _infoRow(
                            Icons.note,
                            'Keperluan',
                            data!['keperluan'] ?? '-',
                          ),
                          _infoRow(
                            Icons.calendar_today,
                            'Waktu Pengambilan',
                            data!['waktu_pengambilan'] ?? '-',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.grey[700]),
          const SizedBox(width: 16),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
