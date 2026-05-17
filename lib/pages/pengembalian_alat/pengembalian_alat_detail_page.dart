// lib/pages/pengembalian_alat/pengembalian_alat_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pengembalian_provider.dart';
import 'pengembalian_alat_form_page.dart';

class PengembalianAlatDetailPage extends StatefulWidget {
  final String hashid;
  const PengembalianAlatDetailPage({Key? key, required this.hashid})
    : super(key: key);

  @override
  State<PengembalianAlatDetailPage> createState() =>
      _PengembalianAlatDetailPageState();
}

class _PengembalianAlatDetailPageState
    extends State<PengembalianAlatDetailPage> {
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    final list = context.read<PengembalianProvider>().items;
    _data = list.firstWhere(
      (k) => k['hashid'] == widget.hashid,
      orElse: () => <String, dynamic>{},
    );
    if (_data!.isEmpty) _data = null;
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Pengembalian')),
        body: const Center(child: Text('Data tidak ditemukan')),
      );
    }

    final alatLabel = _alatLabel(data);
    final peminjam = _peminjam(data);
    final jumlah = '${data['jumlah'] ?? 0}';
    final tanggal = data['tanggal_pengembalian'] ?? '-';
    final keterangan = data['keterangan'] ?? '-';
    final String? fotoUrl = data['foto_url'] ?? data['foto']?.toString();
    final displayFotoUrl = _resolveUrl(fotoUrl);

    return Scaffold(
      backgroundColor: const Color(0xFFFEF9E7),
      appBar: AppBar(
        title: const Text('Bukti Pengembalian'),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              if (value == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PengembalianAlatFormPage(hashid: widget.hashid),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fadeInSection(
              0,
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('Alat', alatLabel, bold: true),
                      const Divider(height: 24),
                      _infoRow('Peminjam', peminjam),
                      const Divider(height: 24),
                      _infoRow('Jumlah Dikembalikan', '$jumlah unit'),
                      const Divider(height: 24),
                      _infoRow('Tanggal Pengembalian', tanggal),
                      if (keterangan.isNotEmpty && keterangan != '-') ...[
                        const Divider(height: 24),
                        _infoRow('Keterangan', keterangan),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _fadeInSection(
              1,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Foto Bukti',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (displayFotoUrl != null)
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => Dialog(
                            backgroundColor: Colors.transparent,
                            child: Stack(
                              children: [
                                InteractiveViewer(
                                  child: Image.network(
                                    displayFotoUrl,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => Navigator.pop(ctx),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Hero(
                        tag: 'bukti_pengembalian_${widget.hashid}',
                        child: Container(
                          width: double.infinity,
                          height: 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                            image: DecorationImage(
                              image: NetworkImage(displayFotoUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Ketuk untuk memperbesar',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tidak ada foto bukti',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _fadeInSection(
              2,
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PengembalianAlatFormPage(hashid: widget.hashid),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Pengembalian'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD97706),
                    side: const BorderSide(color: Color(0xFFD97706)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
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

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  String _alatLabel(Map<String, dynamic> item) {
    final pengambilan = item['pengambilan'];
    if (pengambilan == null) return '-';
    final alat = pengambilan['alat'];
    if (alat == null) return '-';
    return alat['nama_alat'] ?? alat['nama'] ?? '-';
  }

  String _peminjam(Map<String, dynamic> item) {
    if (item['nama_peminjam'] != null &&
        item['nama_peminjam'].toString().isNotEmpty) {
      return item['nama_peminjam'].toString();
    }
    final user = item['user'];
    if (user is Map && user['name'] != null) {
      return user['name'].toString();
    }
    return '-';
  }

  String? _resolveUrl(String? path) {
    if (path == null || path.toString().isEmpty) return null;
    if (path.startsWith('http')) return path;
    return 'http://192.168.1.9:8000/storage/$path';
  }
}
