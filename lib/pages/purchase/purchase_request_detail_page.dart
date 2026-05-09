import 'package:flutter/material.dart';
import '../../services/purchase_request_service.dart';

class PurchaseRequestDetailPage extends StatefulWidget {
  final String hashid;

  const PurchaseRequestDetailPage({super.key, required this.hashid});

  @override
  State<PurchaseRequestDetailPage> createState() =>
      _PurchaseRequestDetailPageState();
}

class _PurchaseRequestDetailPageState extends State<PurchaseRequestDetailPage> {
  Map<String, dynamic>? data;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => isLoading = true);

    final result = await PurchaseRequestService.getById(widget.hashid);

    if (result['status'] == true && result['data'] != null) {
      setState(() {
        data = result['data'];
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal memuat data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) setState(() => isLoading = false);
  }

  // ==================== APPROVE ====================
  Future<void> _approve() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setujui PO?'),
        content: const Text('Status akan berubah menjadi "PO".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Setujui'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);
    final res = await PurchaseRequestService.approve(widget.hashid);
    setState(() => isLoading = false);

    if (res['status'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhasil disetujui menjadi PO'),
          backgroundColor: Colors.green,
        ),
      );
      _loadDetail(); // Refresh data
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal menyetujui'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==================== REJECT ====================
  Future<void> _reject() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Request?'),
        content: const Text('Status akan menjadi "Rejected".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Tolak'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);
    final res = await PurchaseRequestService.reject(
      widget.hashid,
      'Ditolak oleh admin',
    );
    setState(() => isLoading = false);

    if (res['status'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request berhasil ditolak'),
          backgroundColor: Colors.red,
        ),
      );
      _loadDetail();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal menolak'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==================== COMPLETE ====================
  Future<void> _complete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selesaikan PO?'),
        content: const Text(
          'Stok akan ditambahkan secara otomatis dan status menjadi "Completed".\n\n'
          'Pastikan sparepart terkait sudah benar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
            ),
            child: const Text('Ya, Selesaikan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);
    final res = await PurchaseRequestService.complete(widget.hashid);
    setState(() => isLoading = false);

    if (res['status'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'PO telah selesai'),
          backgroundColor: Colors.orange[700],
        ),
      );
      _loadDetail(); // Refresh halaman
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal menyelesaikan PO'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Purchase Request'),
        backgroundColor: const Color(0xFF001F3F),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : data == null
          ? const Center(child: Text('Data tidak ditemukan'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data!['nama_part'] ?? '-',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _infoRow('Part Number', data!['part_number'] ?? '-'),
                          _infoRow(
                            'Quantity',
                            '${data!['quantity'] ?? 0} ${data!['satuan'] ?? ''}',
                          ),
                          _infoRow('PIC', data!['pic'] ?? '-'),
                          _infoRow('Untuk Apa', data!['untuk_apa'] ?? '-'),
                          _infoRow(
                            'Link Website',
                            data!['link_website'] ?? '-',
                          ),
                          _infoRow(
                            'Status',
                            data!['status'] ?? 'PR',
                            isStatus: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  if (data!['status'] == 'PR')
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _approve,
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _reject,
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (data!['status'] == 'PO')
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _complete,
                        icon: const Icon(Icons.task_alt),
                        label: const Text('Tandai Selesai (Complete)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _infoRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isStatus ? FontWeight.bold : FontWeight.w600,
                color: isStatus
                    ? (value == 'Completed' ? Colors.green : Colors.orange)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
