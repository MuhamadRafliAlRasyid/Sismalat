// lib/pages/kalibrasi/kalibrasi_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/kalibrasi_provider.dart';
import 'kalibrasi_form_page.dart';

class KalibrasiDetailPage extends StatefulWidget {
  final String hashid;
  const KalibrasiDetailPage({super.key, required this.hashid});

  @override
  State<KalibrasiDetailPage> createState() => _KalibrasiDetailPageState();
}

class _KalibrasiDetailPageState extends State<KalibrasiDetailPage> {
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    final items = context.read<KalibrasiProvider>().items;
    _data = items.firstWhere(
      (m) => m['hashid'] == widget.hashid,
      orElse: () => <String, dynamic>{},
    );
    if (_data!.isEmpty) _data = null;
  }

  @override
  Widget build(BuildContext context) {
    final map = _data;
    if (map == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Kalibrasi')),
        body: const Center(child: Text('Data tidak ditemukan')),
      );
    }

    final namaAlat = map['alat']?['nama'] ?? '-';
    final gambar = map['alat']?['foto_thumb'] ?? map['alat']?['foto_url'];

    return Scaffold(
      backgroundColor: const Color(0xFFFEF9E7),
      appBar: AppBar(
        title: const Text('Detail Kalibrasi'),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (gambar != null)
              _fadeInSection(
                0,
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    gambar,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, size: 48),
                    ),
                  ),
                ),
              ),
            if (gambar != null) const SizedBox(height: 16),
            _fadeInSection(
              1,
              _infoCard([
                _infoRow('Alat', namaAlat, bold: true),
                _infoRow('No Sertifikat', map['no_sertifikat'] ?? '-'),
                _infoRow('Tanggal Kalibrasi', map['tanggal_kalibrasi'] ?? '-'),
                _infoRow(
                  'Masa Berlaku Baru',
                  map['masa_berlaku_baru'] ?? '-',
                  valueColor: Colors.green.shade700,
                ),
                _infoRow('Keterangan', map['keterangan'] ?? '-'),
              ]),
            ),
            const SizedBox(height: 20),
            _fadeInSection(
              2,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              KalibrasiFormPage(hashid: widget.hashid),
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD97706),
                        side: const BorderSide(color: Color(0xFFD97706)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmDelete(context, widget.hashid),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Hapus'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fadeInSection(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 80)),
      builder: (context, value, widget) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: widget,
          ),
        );
      },
      child: child,
    );
  }

  Widget _infoCard(List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.amber.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );

  Widget _infoRow(
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
              color: valueColor ?? const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    ),
  );

  void _confirmDelete(BuildContext context, String hashid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Kalibrasi?'),
        content: const Text('Data ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<KalibrasiProvider>().deleteKalibrasi(hashid);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
