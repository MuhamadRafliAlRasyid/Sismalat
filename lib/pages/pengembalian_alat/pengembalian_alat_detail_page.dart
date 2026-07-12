import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/api.dart';
import '../../services/auth_service.dart';
import '../../providers/pengembalian_provider.dart';
import 'pengembalian_alat_form_page.dart';

class PengembalianAlatDetailPage extends StatefulWidget {
  final String hashid;

  const PengembalianAlatDetailPage({super.key, required this.hashid});

  @override
  State<PengembalianAlatDetailPage> createState() =>
      _PengembalianAlatDetailPageState();
}

class _PengembalianAlatDetailPageState
    extends State<PengembalianAlatDetailPage> {
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
    final items = context.read<PengembalianProvider>().items;
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

  String _getServerBaseUrl() {
    try {
      final uri = Uri.tryParse(Apiimg.baseUrl);
      if (uri != null) {
        return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
      }
    } catch (_) {}
    return Apiimg.baseUrl;
  }

  /// ✅ URL foto dengan folder
  String? _getPhotoUrl(dynamic photoPath, {String? folder}) {
    if (photoPath == null) return null;
    String photoStr = photoPath.toString().trim();
    if (photoStr.isEmpty) return null;

    // 1. URL eksternal langsung return
    if (photoStr.startsWith('https://') &&
        (photoStr.contains('googleusercontent') ||
            photoStr.contains('ui-avatars') ||
            photoStr.contains('google.com') ||
            photoStr.contains('lh3.') ||
            photoStr.contains('gstatic'))) {
      return photoStr;
    }

    // 2. URL localhost fix
    if (photoStr.startsWith('http://127.0.0.1') ||
        photoStr.startsWith('http://localhost')) {
      try {
        final uri = Uri.parse(photoStr);
        final baseUrl = _getServerBaseUrl();
        if (uri.path.contains('/storage/') &&
            (uri.path.contains('https://') || uri.path.contains('http://'))) {
          final match = RegExp(r'/storage/(https?://.+)$').firstMatch(uri.path);
          if (match != null) return match.group(1);
        }
        return '$baseUrl${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
      } catch (_) {}
      return photoStr;
    }

    // 3. Full URL
    if (photoStr.startsWith('http://') || photoStr.startsWith('https://')) {
      return photoStr;
    }

    // 4. Path relatif + folder
    final baseUrl = _getServerBaseUrl();
    if (baseUrl.isEmpty) return photoStr;

    if (photoStr.startsWith('/')) {
      photoStr = photoStr.substring(1);
    }
    if (photoStr.startsWith('storage/')) {
      photoStr = photoStr.substring('storage/'.length);
    }

    if (folder != null && folder.isNotEmpty) {
      return '$baseUrl/storage/$folder/$photoStr';
    }
    return '$baseUrl/storage/$photoStr';
  }

  /// ✅ Helper khusus foto profil user
  String? _getUserPhotoUrl(dynamic photoPath) {
    if (photoPath == null) return null;
    String photoStr = photoPath.toString().trim();
    if (photoStr.isEmpty) return null;

    if (photoStr.startsWith('https://') &&
        (photoStr.contains('googleusercontent') ||
            photoStr.contains('ui-avatars'))) {
      return photoStr;
    }

    if (photoStr.startsWith('http://127.0.0.1') ||
        photoStr.startsWith('http://localhost')) {
      try {
        final uri = Uri.parse(photoStr);
        final baseUrl = _getServerBaseUrl();
        return '$baseUrl${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
      } catch (_) {}
    }

    if (photoStr.startsWith('http://') || photoStr.startsWith('https://')) {
      return photoStr;
    }

    final baseUrl = _getServerBaseUrl();
    if (photoStr.startsWith('images/profile/')) {
      return '$baseUrl/$photoStr';
    }
    return '$baseUrl/images/profile/$photoStr';
  }

  Widget _buildNetworkImage(String? imageUrl, {BoxFit fit = BoxFit.contain}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
        ),
      );
    }

    final baseUrl = _getServerBaseUrl();
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
          color: Colors.grey.shade200,
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
          title: const Text('Detail Pengembalian Alat'),
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
          title: const Text('Detail Pengembalian Alat'),
          backgroundColor: const Color(0xFFD97706),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'Data tidak ditemukan',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    // ==================== EKSTRAK DATA ====================
    final pengambilan = map['pengambilan'] ?? {};
    final alat = pengambilan['alat'] ?? {};
    final user = map['user'] ?? {};
    final bagian = pengambilan['bagian'] ?? {};

    // Info dasar
    final namaAlat = alat['nama_alat'] ?? '-';
    final merkAlat = alat['merk'] ?? '';
    final tipeAlat = alat['tipe'] ?? '';
    final peminjam = user['name'] ?? 'Tanpa Nama';
    final namaBagian = bagian['nama'] ?? '-';
    final jumlah = map['jumlah'] ?? 0;
    final tanggal = _formatDate(map['tanggal_pengembalian']);
    final keterangan = map['keterangan'];

    // Foto paths
    final gambarAlat =
        alat['foto_thumb_url'] ?? alat['foto_url'] ?? alat['foto'];
    final fotoBuktiPath = map['foto'];
    final fotoProfilUser =
        user['profile_photo_url'] ?? user['profile_photo_path'];

    // ✅ Generate URLs dengan folder yang benar
    final fotoBuktiUrl = _getPhotoUrl(fotoBuktiPath, folder: 'pengembalian');
    final fotoAlatUrl = _getPhotoUrl(gambarAlat, folder: 'alat');
    final fotoUserUrl = _getUserPhotoUrl(fotoProfilUser);

    // Debug log
    print('🖼️ [Detail] fotoBukti: $fotoBuktiUrl');
    print('🖼️ [Detail] fotoAlat: $fotoAlatUrl');
    print('🖼️ [Detail] fotoUser: $fotoUserUrl');

    // Cek status expired/warning
    final statusAlat = alat['status'];
    final isExpired = statusAlat == 'expired';
    final isWarning = statusAlat == 'warning';

    return Scaffold(
      backgroundColor: const Color(0xFFFEF9E7),
      appBar: AppBar(
        title: const Text(
          'Detail Pengembalian Alat',
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
                    builder: (_) =>
                        PengembalianAlatFormPage(hashid: widget.hashid),
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
                    Text('Edit Data'),
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
                // ==================== HEADER CARD ====================
                _fadeInSection(
                  0,
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFF8E1),
                          Color(0xFFFFF3E0),
                          Color(0xFFFFECB3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFFFE082),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.2),
                          blurRadius: 12,
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
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.3),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.assignment_return,
                                size: 28,
                                color: Color(0xFFD97706),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Detail Pengembalian Alat',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Informasi lengkap pengembalian alat',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.amber.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFD97706),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Sudah Dikembalikan',
                                    style: TextStyle(
                                      color: Color(0xFFD97706),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isExpired)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Alat Expired',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (isWarning)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.yellow.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.yellow.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.warning_amber,
                                      size: 16,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Alat Warning',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ==================== FOTO ALAT ====================
                if (fotoAlatUrl != null) ...[
                  _fadeInSection(
                    1,
                    GestureDetector(
                      onTap: () => _showImageModal(fotoAlatUrl),
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
                            const Text(
                              'Foto Alat',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: double.infinity,
                                height: 240,
                                child: _buildNetworkImage(
                                  fotoAlatUrl,
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
                  2,
                  Column(
                    children: [
                      // Alat Info
                      _buildInfoCard(
                        icon: Icons.build,
                        iconColor: const Color(0xFFD97706),
                        label: 'Alat',
                        value: namaAlat,
                        subtitle: '$merkAlat $tipeAlat'.trim().isEmpty
                            ? null
                            : '$merkAlat $tipeAlat',
                      ),
                      const SizedBox(height: 12),

                      // User Info
                      _buildInfoCard(
                        icon: Icons.person,
                        iconColor: const Color(0xFFD97706),
                        label: 'Pengguna',
                        value: peminjam,
                        subtitle: 'Bagian: $namaBagian',
                        leadingWidget: _buildUserAvatar(
                          fotoUrl: fotoUserUrl,
                          name: peminjam,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Jumlah
                      _buildInfoCard(
                        icon: Icons.inventory_2,
                        iconColor: const Color(0xFFD97706),
                        label: 'Jumlah Dikembalikan',
                        value: '$jumlah',
                        valueColor: const Color(0xFFD97706),
                        valueBold: true,
                        valueSize: 32,
                      ),
                      const SizedBox(height: 12),

                      // Tanggal
                      _buildInfoCard(
                        icon: Icons.calendar_today,
                        iconColor: const Color(0xFFD97706),
                        label: 'Tanggal Pengembalian',
                        value: tanggal,
                      ),
                      const SizedBox(height: 12),

                      // Keterangan
                      if (keterangan != null &&
                          keterangan.toString().isNotEmpty &&
                          keterangan != '-')
                        _buildInfoCard(
                          icon: Icons.description,
                          iconColor: const Color(0xFFD97706),
                          label: 'Keterangan',
                          value: keterangan,
                          isFullWidth: true,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ==================== FOTO BUKTI PENGEMBALIAN ====================
                if (fotoBuktiUrl != null) ...[
                  _fadeInSection(
                    3,
                    GestureDetector(
                      onTap: () => _showImageModal(fotoBuktiUrl),
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
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 18,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Foto Bukti Pengembalian',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
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
                                  fotoBuktiUrl,
                                  fit: BoxFit.cover,
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

                // ==================== ACTION BUTTONS ====================
                _fadeInSection(
                  4,
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
                                builder: (_) => PengembalianAlatFormPage(
                                  hashid: widget.hashid,
                                ),
                              ),
                            );
                            if (result == true && context.mounted) {
                              Navigator.pop(context, true);
                            }
                          },
                          icon: const Icon(Icons.edit, size: 20),
                          label: const Text(
                            'Edit Data',
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
                          icon: const Icon(Icons.list, size: 20),
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

          // ==================== LIGHTBOX MODAL (UPGRADED) ====================
          if (_imgModal && _imgSrc != null)
            Stack(
              children: [
                // Backdrop dengan gradient
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

                // Header dengan judul
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
                                'Foto Bukti',
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

                // Image dengan InteractiveViewer (zoom & pan)
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

                // Footer dengan hint
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pinch,
                            color: Colors.amber.shade300,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
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

  // ==================== HELPER: User Avatar ====================
  Widget _buildUserAvatar({required String? fotoUrl, required String name}) {
    if (fotoUrl != null && fotoUrl.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: 40,
          height: 40,
          child: _buildNetworkImage(fotoUrl, fit: BoxFit.cover),
        ),
      );
    }
    return _buildInitialAvatar(name);
  }

  Widget _buildInitialAvatar(String name) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD97706),
          ),
        ),
      ),
    );
  }

  // ==================== HELPER: Info Card ====================
  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? subtitle,
    bool isFullWidth = false,
    bool valueBold = false,
    Color? valueColor,
    double valueSize = 16,
    Widget? leadingWidget,
  }) {
    return Container(
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leadingWidget != null) ...[
                leadingWidget,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: valueSize,
                        fontWeight: valueBold
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: valueColor ?? const Color(0xFF1E293B),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== HELPER: Fade In Animation ====================
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

  // ==================== HELPER: Format Date ====================
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
}
