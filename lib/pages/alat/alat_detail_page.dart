import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/api.dart';
import '../../services/auth_service.dart';
import '../../providers/alat_provider.dart';
import 'alat_form_page.dart';

class AlatDetailPage extends StatefulWidget {
  final String hashid;

  const AlatDetailPage({super.key, required this.hashid});

  @override
  State<AlatDetailPage> createState() => _AlatDetailPageState();
}

class _AlatDetailPageState extends State<AlatDetailPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _imgSrc;
  bool _imgModal = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadToken();
    _loadData();
  }

  Future<void> _loadToken() async {
    final token = await AuthService.getToken();
    if (mounted) {
      setState(() => _token = token);
    }
  }

  void _loadData() {
    // Cari dari provider (data sudah ada dari list)
    final items = context.read<AlatProvider>().alats;
    _data = items.firstWhere(
      (m) => m['hashid'] == widget.hashid,
      orElse: () => <String, dynamic>{},
    );
    if (_data!.isEmpty) _data = null;
    setState(() => _loading = false);
  }

  void _showImageModal(String imageUrl) {
    setState(() {
      _imgSrc = imageUrl;
      _imgModal = true;
    });
  }

  void _hideImageModal() {
    setState(() {
      _imgModal = false;
      _imgSrc = null;
    });
  }

  // ==================== HELPER URL FOTO ====================

  String _fixLocalhostUrl(String url) {
    return url
        .replaceAll('http://127.0.0.1:8000', Apiimg.baseUrl)
        .replaceAll('http://localhost:8000', Apiimg.baseUrl)
        .replaceAll('http://127.0.0.1', Apiimg.baseUrl)
        .replaceAll('http://localhost', Apiimg.baseUrl);
  }

  /// ✅ Ambil URL foto ASLI (untuk detail page)
  String? _getFotoUrl(Map<String, dynamic> alat) {
    // ✅ Prioritas: foto_url (ukuran asli)
    final fotoUrl = alat['foto_url'];
    if (fotoUrl != null && fotoUrl.toString().isNotEmpty) {
      return _fixLocalhostUrl(fotoUrl.toString());
    }

    // Fallback ke QR code
    final qrUrl = alat['qr_code_url'];
    if (qrUrl != null && qrUrl.toString().isNotEmpty) {
      return _fixLocalhostUrl(qrUrl.toString());
    }

    return null;
  }

  Widget _buildNetworkImage(String? imageUrl, {BoxFit fit = BoxFit.cover}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
        ),
      );
    }

    final baseUrl = Apiimg.baseUrl;
    final isInternal = imageUrl.startsWith(baseUrl);

    final headers = <String, String>{};
    if (isInternal && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return Image.network(
      imageUrl,
      fit: fit,
      headers: headers.isNotEmpty ? headers : null,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.grey.shade100,
          child: Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                  : null,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFD97706),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFEF9E7),
        appBar: AppBar(
          title: const Text('Detail Alat'),
          backgroundColor: const Color(0xFFD97706),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD97706)),
          ),
        ),
      );
    }

    final map = _data;
    if (map == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFEF9E7),
        appBar: AppBar(
          title: const Text('Detail Alat'),
          backgroundColor: const Color(0xFFD97706),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: Text('Data tidak ditemukan')),
      );
    }

    final namaAlat = map['nama_alat'] ?? '-';
    final merk = map['merk'] ?? '';
    final tipe = map['tipe'] ?? '';
    final noSeri = map['no_seri'] ?? '-';
    final jumlah = map['jumlah'] ?? 0;
    final kategori = map['kategori']?['nama'] ?? '-';
    final masaBerlaku = map['masa_berlaku'];

    // ✅ Ambil URL foto ASLI (bukan thumbnail)
    final fotoUrl = _getFotoUrl(map);

    return Scaffold(
      backgroundColor: const Color(0xFFFEF9E7),
      appBar: AppBar(
        title: const Text(
          'Detail Alat',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) async {
              if (value == 'edit') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AlatFormPage(hashid: widget.hashid),
                  ),
                );
                if (result == true && context.mounted) {
                  Navigator.pop(context, true);
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: Color(0xFFD97706),
                    ),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================== FOTO ASLI (bukan thumbnail) ====================
                if (fotoUrl != null) ...[
                  _fadeInSection(
                    0,
                    GestureDetector(
                      onTap: () => _showImageModal(fotoUrl),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.photo_camera,
                                    color: Color(0xFFD97706),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Foto Alat',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    '📷 Asli',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: double.infinity,
                                height: 240,
                                child: _buildNetworkImage(
                                  fotoUrl,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                'Ketuk untuk memperbesar',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ==================== INFO GRID ====================
                _fadeInSection(
                  1,
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRowWithIcon(
                          icon: Icons.build,
                          label: 'Nama Alat',
                          value: namaAlat,
                          bold: true,
                        ),
                        const Divider(height: 24),
                        _infoRowWithIcon(
                          icon: Icons.label,
                          label: 'Merk',
                          value: merk.isNotEmpty ? merk : '-',
                        ),
                        const Divider(height: 24),
                        _infoRowWithIcon(
                          icon: Icons.category,
                          label: 'Tipe',
                          value: tipe.isNotEmpty ? tipe : '-',
                        ),
                        const Divider(height: 24),
                        _infoRowWithIcon(
                          icon: Icons.qr_code,
                          label: 'No. Seri',
                          value: noSeri,
                        ),
                        const Divider(height: 24),
                        _infoRowWithIcon(
                          icon: Icons.inventory_2,
                          label: 'Jumlah Stok',
                          value: '$jumlah',
                          bold: true,
                          valueColor: const Color(0xFFD97706),
                        ),
                        const Divider(height: 24),
                        _infoRowWithIcon(
                          icon: Icons.folder,
                          label: 'Kategori',
                          value: kategori,
                        ),
                        if (masaBerlaku != null) ...[
                          const Divider(height: 24),
                          _infoRowWithIcon(
                            icon: Icons.calendar_today,
                            label: 'Masa Berlaku',
                            value: _formatDate(masaBerlaku),
                            valueColor: _isExpired(masaBerlaku)
                                ? Colors.red
                                : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ==================== ACTION BUTTONS ====================
                _fadeInSection(
                  2,
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AlatFormPage(hashid: widget.hashid),
                              ),
                            );
                            if (result == true && context.mounted) {
                              Navigator.pop(context, true);
                            }
                          },
                          icon: const Icon(Icons.edit, size: 20),
                          label: const Text(
                            'Edit Alat',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: Colors.amber.withOpacity(0.4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, size: 20),
                          label: const Text(
                            'Kembali ke Daftar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD97706),
                            side: const BorderSide(
                              color: Color(0xFFD97706),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // ==================== LIGHTBOX MODAL ====================
          if (_imgModal && _imgSrc != null)
            Stack(
              children: [
                GestureDetector(
                  onTap: _hideImageModal,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.95),
                          Colors.black.withOpacity(0.85),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      right: 16,
                      bottom: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.photo_camera,
                            color: Color(0xFFD97706),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Foto Alat (Ukuran Asli)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Cubit untuk zoom • Geser untuk pan',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _hideImageModal,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.black87,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    boundaryMargin: const EdgeInsets.all(20),
                    clipBehavior: Clip.none,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      constraints: const BoxConstraints(
                        maxWidth: double.infinity,
                        maxHeight: double.infinity,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildNetworkImage(_imgSrc, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pinch, color: Colors.amber, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Cubit untuk zoom • Tap di luar untuk menutup',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _infoRowWithIcon({
    required IconData icon,
    required String label,
    required String value,
    bool bold = false,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFFD97706)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                  color: valueColor ?? const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
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

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  bool _isExpired(String? dateStr) {
    if (dateStr == null) return false;
    try {
      final date = DateTime.parse(dateStr);
      return date.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }
}
