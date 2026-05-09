import 'package:flutter/material.dart';
import '../../services/barang_service.dart';
import '../../config/api.dart';

class BarangDetailPage extends StatefulWidget {
  final String hashid;

  const BarangDetailPage({super.key, required this.hashid});

  @override
  State<BarangDetailPage> createState() => _BarangDetailPageState();
}

class _BarangDetailPageState extends State<BarangDetailPage> {
  Map<String, dynamic>? barang;
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

    final result = await BarangService.getById(widget.hashid);

    if (result['status'] == true && result['data'] != null) {
      setState(() {
        barang = result['data'];
      });
    } else {
      setState(() {
        errorMessage = result['message'] ?? 'Gagal memuat data barang';
      });
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Barang'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDetail),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? _buildErrorState()
          : barang == null
          ? const Center(child: Text('Data tidak ditemukan'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
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
                            barang!['nama_part'] ?? '-',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(height: 30),
                          _infoRow(
                            Icons.category,
                            'Model',
                            barang!['model'] ?? '-',
                          ),
                          _infoRow(
                            Icons.branding_watermark,
                            'Merk',
                            barang!['merk'] ?? '-',
                          ),
                          _infoRow(
                            Icons.confirmation_number,
                            'RUK No',
                            barang!['ruk_no'] ?? '-',
                          ),
                          _infoRow(
                            Icons.business,
                            'Supplier',
                            barang!['supplier'] ?? '-',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Stok
                  Row(
                    children: [
                      Expanded(
                        child: _stockCard(
                          'Stok Baru',
                          barang!['jumlah_baru']?.toString() ?? '0',
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _stockCard(
                          'Stok Bekas',
                          barang!['jumlah_bekas']?.toString() ?? '0',
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Info Lainnya
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _infoRow(
                            Icons.attach_money,
                            'Patokan Harga',
                            'Rp ${barang!['patokan_harga'] ?? 0}',
                          ),
                          _infoRow(
                            Icons.calendar_today,
                            'Purchase Date',
                            barang!['purchase_date']?.toString().split(
                                  'T',
                                )[0] ??
                                '-',
                          ),
                          _infoRow(
                            Icons.local_shipping,
                            'Delivery Date',
                            barang!['delivery_date']?.toString().split(
                                  'T',
                                )[0] ??
                                '-',
                          ),
                          _infoRow(
                            Icons.confirmation_number,
                            'PO Number',
                            barang!['po_number'] ?? '-',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // QR Code
                  if (barang!['qr_code'] != null &&
                      barang!['qr_code'].toString().isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'QR Code',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Image.network(
                                "${Apiimg.baseUrl}/storage/${barang!['qr_code']}",
                                height: 240,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Column(
                                  children: [
                                    Icon(
                                      Icons.qr_code_2,
                                      size: 140,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 12),
                                    Text('QR Code tidak dapat dimuat'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'QR Code belum di-generate',
                          style: TextStyle(color: Colors.grey),
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

  Widget _stockCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.inventory_2, size: 40, color: color),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 14)),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
    );
  }
}
