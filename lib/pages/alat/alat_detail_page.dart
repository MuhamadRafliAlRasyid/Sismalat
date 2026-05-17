// lib/pages/alat/alat_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/alat_provider.dart';
import '../../models/alat_models.dart';
import 'alat_form_page.dart';
import 'riwayat_alat_page.dart';

class AlatDetailPage extends StatefulWidget {
  final String hashid;
  const AlatDetailPage({Key? key, required this.hashid}) : super(key: key);

  @override
  State<AlatDetailPage> createState() => _AlatDetailPageState();
}

class _AlatDetailPageState extends State<AlatDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlatProvider>().fetchDetail(widget.hashid);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlatProvider>();
    final alat = provider.selectedAlat;

    return Scaffold(
      backgroundColor: const Color(0xFFFEF9E7),
      appBar: AppBar(
        title: Text(alat?.namaAlat ?? 'Detail Alat'),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (alat != null)
            PopupMenuButton<String>(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (value) async {
                if (value == 'edit') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AlatFormPage(hashid: alat.hashid),
                    ),
                  );
                  provider.fetchDetail(widget.hashid);
                } else if (value == 'delete') {
                  _confirmDelete(alat);
                }
              },
              itemBuilder: (_) => const [
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
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Hapus', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: alat == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD97706)),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (alat.fotoUrl != null)
                      _fadeInSection(0, _buildFoto(alat)),
                    const SizedBox(height: 20),
                    _fadeInSection(
                      1,
                      _sectionCard([
                        _infoRow('Nama Alat', alat.namaAlat, bold: true),
                        _infoRow('Merk', alat.merk),
                        if (alat.tipe != null && alat.tipe!.isNotEmpty)
                          _infoRow('Tipe', alat.tipe!),
                        if (alat.kelas != null && alat.kelas!.isNotEmpty)
                          _infoRow('Kelas', alat.kelas!),
                        if (alat.noSeri != null && alat.noSeri!.isNotEmpty)
                          _infoRow('No. Seri', alat.noSeri!),
                        if (alat.noIdentitas != null &&
                            alat.noIdentitas!.isNotEmpty)
                          _infoRow('No. Identitas', alat.noIdentitas!),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    if ((alat.kapasitas != null &&
                            alat.kapasitas!.isNotEmpty) ||
                        (alat.dayaBaca != null && alat.dayaBaca!.isNotEmpty))
                      _fadeInSection(
                        2,
                        _sectionCard([
                          if (alat.kapasitas != null &&
                              alat.kapasitas!.isNotEmpty)
                            _infoRow('Kapasitas', alat.kapasitas!),
                          if (alat.dayaBaca != null &&
                              alat.dayaBaca!.isNotEmpty)
                            _infoRow('Daya Baca', alat.dayaBaca!),
                        ]),
                      ),
                    const SizedBox(height: 14),
                    _fadeInSection(
                      3,
                      _sectionCard([
                        _infoRow('Jumlah / Stok', '${alat.jumlah}'),
                        if (alat.noSertifikat != null &&
                            alat.noSertifikat!.isNotEmpty)
                          _infoRow('No. Sertifikat', alat.noSertifikat!),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    _fadeInSection(
                      4,
                      _sectionCard([
                        _infoRow(
                          'Status',
                          alat.status ?? '-',
                          valueColor: _statusColor(alat.status),
                        ),
                        if (alat.masaBerlaku != null &&
                            alat.masaBerlaku!.isNotEmpty)
                          _infoRow('Masa Berlaku', alat.masaBerlaku!),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    if (alat.kategori != null)
                      _fadeInSection(
                        5,
                        _sectionCard([
                          _infoRow('Kategori', alat.kategori!.nama),
                        ]),
                      ),
                    const SizedBox(height: 14),
                    if (alat.qrCodeUrl != null)
                      _fadeInSection(
                        6,
                        _sectionCard([
                          const Text(
                            'QR Code Alat',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.8, end: 1.0),
                              duration: const Duration(milliseconds: 600),
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: child,
                                );
                              },
                              child: Image.network(
                                alat.qrCodeUrl!,
                                height: 160,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.qr_code, size: 80),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    const SizedBox(height: 14),
                    if (alat.kalibrasis != null && alat.kalibrasis!.isNotEmpty)
                      _fadeInSection(
                        7,
                        _sectionCard([
                          const Text(
                            'Riwayat Kalibrasi',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...alat.kalibrasis!.map((k) => _kalibrasiCard(k)),
                        ]),
                      ),
                    const SizedBox(height: 20),
                    _fadeInSection(8, _buildRiwayatButton(alat)),
                    const SizedBox(height: 20),
                    _fadeInSection(9, _buildActionButtons(alat)),
                  ],
                ),
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

  Widget _buildFoto(dynamic alat) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          alat.fotoUrl!,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 120,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, size: 48),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard(List<Widget> children) {
    return Container(
      width: double.infinity,
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
  }

  Widget _infoRow(
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
  }

  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'ok':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _kalibrasiCard(dynamic k) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: const Color(0xFFFEF3C7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tanggal: ${k.tanggalKalibrasi ?? "-"}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (k.noSertifikat != null)
              Text(
                'Sertifikat: ${k.noSertifikat}',
                style: TextStyle(color: Colors.grey[600]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayatButton(dynamic alat) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RiwayatAlatPage(
                alatHashid: alat.hashid,
                namaAlat: alat.namaAlat,
              ),
            ),
          );
        },
        icon: const Icon(Icons.history),
        label: const Text('Lihat Riwayat Pengambilan & Pengembalian'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD97706),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(dynamic alat) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AlatFormPage(hashid: alat.hashid),
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
            onPressed: () => _confirmDelete(alat),
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
    );
  }

  void _confirmDelete(dynamic alat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Alat?'),
        content: const Text(
          'Alat akan dipindahkan ke sampah. Anda bisa mengembalikannya nanti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AlatProvider>().delete(alat.hashid);
              if (mounted) {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
