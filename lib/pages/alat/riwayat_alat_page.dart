import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/api.dart';
import '../../services/auth_service.dart';
import '../../providers/pengambilan_provider.dart';
import '../../providers/pengembalian_provider.dart';
import '../../providers/kalibrasi_provider.dart';

class RiwayatAlatPage extends StatefulWidget {
  final String alatHashid;
  final String namaAlat;

  const RiwayatAlatPage({
    super.key,
    required this.alatHashid,
    required this.namaAlat,
  });

  @override
  State<RiwayatAlatPage> createState() => _RiwayatAlatPageState();
}

class _RiwayatAlatPageState extends State<RiwayatAlatPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _token;

  // State untuk modal
  Map<String, dynamic>? _modalData;
  String? _modalType;
  bool _showModal = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadToken();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PengambilanProvider>().fetchByAlatId(widget.alatHashid);
      context.read<PengembalianProvider>().fetchByAlatId(widget.alatHashid);
      context.read<KalibrasiProvider>().fetchByAlatId(widget.alatHashid);
    });
  }

  Future<void> _loadToken() async {
    final token = await AuthService.getToken();
    if (mounted) {
      setState(() => _token = token);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  String? _getPhotoUrl(dynamic photoPath, {required String folder}) {
    if (photoPath == null) return null;
    String photoStr = photoPath.toString().trim();
    if (photoStr.isEmpty) return null;

    // URL eksternal langsung return
    if (photoStr.startsWith('https://') &&
        (photoStr.contains('googleusercontent') ||
            photoStr.contains('ui-avatars'))) {
      return photoStr;
    }

    // URL localhost fix
    if (photoStr.startsWith('http://127.0.0.1') ||
        photoStr.startsWith('http://localhost')) {
      try {
        final uri = Uri.parse(photoStr);
        final baseUrl = _getServerBaseUrl();
        return '$baseUrl${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
      } catch (_) {}
      return photoStr;
    }

    // Full URL
    if (photoStr.startsWith('http://') || photoStr.startsWith('https://')) {
      return photoStr;
    }

    // Path relatif + folder
    final baseUrl = _getServerBaseUrl();
    if (photoStr.startsWith('/')) {
      photoStr = photoStr.substring(1);
    }
    if (photoStr.startsWith('storage/')) {
      photoStr = photoStr.substring('storage/'.length);
    }
    if (photoStr.startsWith('$folder/')) {
      photoStr = photoStr.substring('$folder/'.length);
    }

    return '$baseUrl/storage/$folder/$photoStr';
  }

  Widget _buildNetworkImage(String? imageUrl, {BoxFit fit = BoxFit.cover}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
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
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
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

  // ==================== MODAL HANDLERS ====================

  void _showDetailModal(Map<String, dynamic> data, String type) {
    setState(() {
      _modalData = data;
      _modalType = type;
      _showModal = true;
    });
  }

  void _hideModal() {
    setState(() {
      _showModal = false;
      _modalData = null;
      _modalType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF9E7),
      appBar: AppBar(
        title: Text(
          'Riwayat: ${widget.namaAlat}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.move_to_inbox, size: 20), text: 'Pengambilan'),
            Tab(
              icon: Icon(Icons.assignment_return, size: 20),
              text: 'Pengembalian',
            ),
            Tab(icon: Icon(Icons.calendar_today, size: 20), text: 'Kalibrasi'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _PengambilanTab(
                getPhotoUrl: (path) =>
                    _getPhotoUrl(path, folder: 'pengambilan'),
                buildNetworkImage: _buildNetworkImage,
                onShowDetail: (data) => _showDetailModal(data, 'pengambilan'),
              ),
              _PengembalianTab(
                getPhotoUrl: (path) =>
                    _getPhotoUrl(path, folder: 'pengembalian'),
                buildNetworkImage: _buildNetworkImage,
                onShowDetail: (data) => _showDetailModal(data, 'pengembalian'),
              ),
              _KalibrasiTab(
                onShowDetail: (data) => _showDetailModal(data, 'kalibrasi'),
              ),
            ],
          ),

          // ==================== MODAL DETAIL ====================
          if (_showModal && _modalData != null) _buildDetailModal(),
        ],
      ),
    );
  }

  Widget _buildDetailModal() {
    return Stack(
      children: [
        // Backdrop
        GestureDetector(
          onTap: _hideModal,
          child: Container(color: Colors.black.withOpacity(0.7)),
        ),
        // Modal content
        Center(
          child: GestureDetector(
            onTap: () {}, // Prevent tap through
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(child: _buildModalContent()),
            ),
          ),
        ),
        // Close button
        Positioned(
          top: 40,
          right: 20,
          child: GestureDetector(
            onTap: _hideModal,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.black87, size: 24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModalContent() {
    if (_modalType == 'pengambilan') {
      return _buildPengambilanModal();
    } else if (_modalType == 'pengembalian') {
      return _buildPengembalianModal();
    } else if (_modalType == 'kalibrasi') {
      return _buildKalibrasiModal();
    }
    return const SizedBox();
  }

  Widget _buildPengambilanModal() {
    final data = _modalData!;
    final fotoPath = data['foto'];
    final fotoUrl = fotoPath != null
        ? _getPhotoUrl(fotoPath, folder: 'pengambilan')
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.move_to_inbox,
                color: Color(0xFFD97706),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Detail Pengambilan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD97706),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _modalInfoRow(
          'Peminjam',
          data['nama_peminjam'] ?? data['user']?['name'] ?? '-',
        ),
        _modalInfoRow('Bagian', data['bagian']?['nama'] ?? '-'),
        _modalInfoRow(
          'Jumlah',
          '${data['jumlah'] ?? 0} ${data['satuan'] ?? ''}',
        ),
        _modalInfoRow('Keperluan', data['keperluan'] ?? '-'),
        _modalInfoRow('Waktu', _formatDateTime(data['waktu_pengambilan'])),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (data['status'] == 'dipinjam' ? Colors.orange : Colors.green)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            (data['status'] ?? '-').toUpperCase(),
            style: TextStyle(
              color: data['status'] == 'dipinjam'
                  ? Colors.orange
                  : Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        if (fotoUrl != null) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildNetworkImage(fotoUrl, fit: BoxFit.cover),
          ),
        ],
      ],
    );
  }

  Widget _buildPengembalianModal() {
    final data = _modalData!;
    final fotoPath = data['foto'];
    final fotoUrl = fotoPath != null
        ? _getPhotoUrl(fotoPath, folder: 'pengembalian')
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.assignment_return,
                color: Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Detail Pengembalian',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _modalInfoRow('Pengembali', data['user']?['name'] ?? '-'),
        _modalInfoRow('Jumlah', '${data['jumlah'] ?? 0}'),
        _modalInfoRow('Keterangan', data['keterangan'] ?? '-'),
        _modalInfoRow('Tanggal', _formatDateTime(data['tanggal_pengembalian'])),
        if (fotoUrl != null) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildNetworkImage(fotoUrl, fit: BoxFit.cover),
          ),
        ],
      ],
    );
  }

  Widget _buildKalibrasiModal() {
    final data = _modalData!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_today,
                color: Colors.blue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Detail Kalibrasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _modalInfoRow('No. Sertifikat', data['no_sertifikat'] ?? '-'),
        _modalInfoRow(
          'Tanggal Kalibrasi',
          _formatDate(data['tanggal_kalibrasi']),
        ),
        _modalInfoRow('Masa Berlaku', _formatDate(data['masa_berlaku_baru'])),
        _modalInfoRow('Keterangan', data['keterangan'] ?? '-'),
      ],
    );
  }

  Widget _modalInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
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

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}, '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}

// ==================== TAB PENGAMBILAN ====================
class _PengambilanTab extends StatelessWidget {
  final String? Function(dynamic) getPhotoUrl;
  final Widget Function(String?, {BoxFit fit}) buildNetworkImage;
  final Function(Map<String, dynamic>) onShowDetail;

  const _PengambilanTab({
    required this.getPhotoUrl,
    required this.buildNetworkImage,
    required this.onShowDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PengambilanProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _buildShimmerList();
        }
        if (provider.error != null) {
          return _buildError(provider.error!);
        }
        final items = provider.items;
        if (items.isEmpty) {
          return _buildEmptyState(
            Icons.inbox_outlined,
            'Belum ada riwayat pengambilan',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _PengambilanCard(
              item: item,
              index: index,
              getPhotoUrl: getPhotoUrl,
              buildNetworkImage: buildNetworkImage,
              onTap: () => onShowDetail(item),
            );
          },
        );
      },
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ShimmerCard(),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: Colors.amber.shade300),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== TAB PENGEMBALIAN ====================
class _PengembalianTab extends StatelessWidget {
  final String? Function(dynamic) getPhotoUrl;
  final Widget Function(String?, {BoxFit fit}) buildNetworkImage;
  final Function(Map<String, dynamic>) onShowDetail;

  const _PengembalianTab({
    required this.getPhotoUrl,
    required this.buildNetworkImage,
    required this.onShowDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PengembalianProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _PengambilanTab(
            getPhotoUrl: getPhotoUrl,
            buildNetworkImage: buildNetworkImage,
            onShowDetail: onShowDetail,
          )._buildShimmerList();
        }
        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 12),
                Text(
                  provider.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
            ),
          );
        }
        final items = provider.items;
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.assignment_return_outlined,
                    size: 48,
                    color: Colors.green.shade300,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada riwayat pengembalian',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _PengembalianCard(
              item: item,
              index: index,
              getPhotoUrl: getPhotoUrl,
              buildNetworkImage: buildNetworkImage,
              onTap: () => onShowDetail(item),
            );
          },
        );
      },
    );
  }
}

// ==================== TAB KALIBRASI ====================
class _KalibrasiTab extends StatelessWidget {
  final Function(Map<String, dynamic>) onShowDetail;

  const _KalibrasiTab({required this.onShowDetail});

  @override
  Widget build(BuildContext context) {
    return Consumer<KalibrasiProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ShimmerCard(),
            ),
          );
        }
        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 12),
                Text(
                  provider.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
            ),
          );
        }
        final items = provider.items;
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    size: 48,
                    color: Colors.blue.shade300,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada riwayat kalibrasi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _KalibrasiCard(
              item: item,
              index: index,
              onTap: () => onShowDetail(item),
            );
          },
        );
      },
    );
  }
}

// ==================== CARD PENGAMBILAN ====================
class _PengambilanCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final int index;
  final String? Function(dynamic) getPhotoUrl;
  final Widget Function(String?, {BoxFit fit}) buildNetworkImage;
  final VoidCallback onTap;

  const _PengambilanCard({
    required this.item,
    required this.index,
    required this.getPhotoUrl,
    required this.buildNetworkImage,
    required this.onTap,
  });

  @override
  State<_PengambilanCard> createState() => _PengambilanCardState();
}

class _PengambilanCardState extends State<_PengambilanCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final peminjam = item['nama_peminjam'] ?? item['user']?['name'] ?? '-';
    final bagian = item['bagian']?['nama'] ?? '-';
    final waktu = _formatDateTime(item['waktu_pengambilan']);
    final jumlah = '${item['jumlah'] ?? 0} ${item['satuan'] ?? ''}'.trim();
    final status = item['status'] ?? 'dipinjam';
    final keperluan = item['keperluan'] ?? '-';
    final fotoPath = item['foto'];
    final fotoUrl = fotoPath != null ? widget.getPhotoUrl(fotoPath) : null;

    final statusColor = status == 'dipinjam' ? Colors.orange : Colors.green;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: Transform.scale(scale: _scaleAnimation.value, child: child),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan status badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.move_to_inbox,
                      color: Color(0xFFD97706),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      peminjam,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Info grid
              _infoRow(Icons.business, 'Bagian', bagian),
              const SizedBox(height: 6),
              _infoRow(Icons.format_list_numbered, 'Jumlah', jumlah),
              const SizedBox(height: 6),
              _infoRow(Icons.access_time, 'Waktu', waktu),

              if (keperluan != '-') ...[
                const SizedBox(height: 6),
                _infoRow(Icons.description, 'Keperluan', keperluan),
              ],

              // Foto (jika ada)
              if (fotoUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    child: widget.buildNetworkImage(fotoUrl, fit: BoxFit.cover),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: Colors.amber.shade600),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}, '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}

// ==================== CARD PENGEMBALIAN ====================
class _PengembalianCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final int index;
  final String? Function(dynamic) getPhotoUrl;
  final Widget Function(String?, {BoxFit fit}) buildNetworkImage;
  final VoidCallback onTap;

  const _PengembalianCard({
    required this.item,
    required this.index,
    required this.getPhotoUrl,
    required this.buildNetworkImage,
    required this.onTap,
  });

  @override
  State<_PengembalianCard> createState() => _PengembalianCardState();
}

class _PengembalianCardState extends State<_PengembalianCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final peminjam = item['user']?['name'] ?? '-';
    final tanggal = _formatDate(item['tanggal_pengembalian']);
    final jumlah = '${item['jumlah'] ?? 0}';
    final keterangan = item['keterangan'];
    final fotoPath = item['foto'];
    final fotoUrl = fotoPath != null ? widget.getPhotoUrl(fotoPath) : null;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: Transform.scale(scale: _scaleAnimation.value, child: child),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.assignment_return,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      peminjam,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'DIKEMBALIKAN',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Info
              _infoRow(Icons.format_list_numbered, 'Jumlah', '$jumlah unit'),
              const SizedBox(height: 6),
              _infoRow(Icons.calendar_today, 'Tanggal', tanggal),

              if (keterangan != null && keterangan.toString().isNotEmpty) ...[
                const SizedBox(height: 6),
                _infoRow(Icons.description, 'Keterangan', keterangan),
              ],

              // Foto
              if (fotoUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    child: widget.buildNetworkImage(fotoUrl, fit: BoxFit.cover),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: Colors.green.shade600),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
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

// ==================== CARD KALIBRASI ====================
class _KalibrasiCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final int index;
  final VoidCallback onTap;

  const _KalibrasiCard({
    required this.item,
    required this.index,
    required this.onTap,
  });

  @override
  State<_KalibrasiCard> createState() => _KalibrasiCardState();
}

class _KalibrasiCardState extends State<_KalibrasiCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final noSertifikat = item['no_sertifikat'] ?? '-';
    final tanggalKalibrasi = _formatDate(item['tanggal_kalibrasi']);
    final masaBerlaku = _formatDate(item['masa_berlaku_baru']);
    final keterangan = item['keterangan'];

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: Transform.scale(scale: _scaleAnimation.value, child: child),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Kalibrasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'TERKALIBRASI',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Info
              _infoRow(Icons.article, 'No. Sertifikat', noSertifikat),
              const SizedBox(height: 6),
              _infoRow(Icons.calendar_today, 'Tanggal', tanggalKalibrasi),
              const SizedBox(height: 6),
              _infoRow(Icons.event_available, 'Masa Berlaku', masaBerlaku),

              if (keterangan != null && keterangan.toString().isNotEmpty) ...[
                const SizedBox(height: 6),
                _infoRow(Icons.description, 'Keterangan', keterangan),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: Colors.blue.shade600),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
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

// ==================== SHIMMER CARD ====================
class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<Color?> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _shimmerAnimation = ColorTween(
      begin: Colors.grey.shade200,
      end: Colors.grey.shade100,
    ).animate(_shimmerController);
    _shimmerController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _shimmerAnimation.value,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 16,
                      color: _shimmerAnimation.value,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 12,
                width: double.infinity,
                color: _shimmerAnimation.value,
              ),
              const SizedBox(height: 8),
              Container(height: 12, width: 150, color: _shimmerAnimation.value),
            ],
          ),
        );
      },
    );
  }
}
