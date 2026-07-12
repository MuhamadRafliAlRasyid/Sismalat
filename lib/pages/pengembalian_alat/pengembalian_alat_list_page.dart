import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/api.dart';
import '../../services/auth_service.dart';
import '../../providers/pengembalian_provider.dart';
import 'pengembalian_alat_detail_page.dart';
import 'pengembalian_alat_form_page.dart';

class PengembalianAlatListPage extends StatefulWidget {
  const PengembalianAlatListPage({super.key});

  @override
  State<PengembalianAlatListPage> createState() =>
      _PengembalianAlatListPageState();
}

class _PengembalianAlatListPageState extends State<PengembalianAlatListPage>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _scrollController = ScrollController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String? _currentSearch;
  String? _currentTanggal;

  // ✅ State untuk modal bukti pengembalian
  String? _imgSrc;
  bool _imgModal = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    _scrollController.addListener(_onScroll);
    _loadToken();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PengembalianProvider>().fetchAll(refresh: true);
    });
  }

  Future<void> _loadToken() async {
    final token = await AuthService.getToken();
    if (mounted) {
      setState(() => _token = token);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<PengembalianProvider>().loadMore(
        search: _currentSearch,
        tanggal: _currentTanggal,
      );
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ✅ Show modal bukti pengembalian
  void _showBuktiModal(String imageUrl) {
    setState(() {
      _imgSrc = imageUrl;
      _imgModal = true;
    });
  }

  void _hideBuktiModal() {
    setState(() {
      _imgModal = false;
      _imgSrc = null;
    });
  }

  // ==================== HELPER URL FOTO ====================

  /// Mendapatkan base URL server
  String _getServerBaseUrl() {
    try {
      final uri = Uri.tryParse(Apiimg.baseUrl);
      if (uri != null) {
        return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
      }
    } catch (_) {}
    return Apiimg.baseUrl;
  }

  /// ✅ PERBAIKAN: URL foto dengan folder yang benar
  /// - folder: 'pengembalian', 'alat', 'images/profile', dll
  String? _getPhotoUrl(dynamic photoPath, {String? folder}) {
    if (photoPath == null) return null;
    String photoStr = photoPath.toString().trim();
    if (photoStr.isEmpty) return null;

    // 1. Jika sudah full URL eksternal (Google, ui-avatars, dll)
    if (photoStr.startsWith('https://') &&
        (photoStr.contains('googleusercontent') ||
            photoStr.contains('ui-avatars') ||
            photoStr.contains('google.com') ||
            photoStr.contains('lh3.') ||
            photoStr.contains('gstatic'))) {
      return photoStr;
    }

    // 2. Jika sudah full URL localhost/127.0.0.1
    if (photoStr.startsWith('http://127.0.0.1') ||
        photoStr.startsWith('http://localhost')) {
      try {
        final uri = Uri.parse(photoStr);
        final baseUrl = _getServerBaseUrl();
        // Jika path mengandung URL eksternal setelah /storage/
        if (uri.path.contains('/storage/') &&
            (uri.path.contains('https://') || uri.path.contains('http://'))) {
          final match = RegExp(r'/storage/(https?://.+)$').firstMatch(uri.path);
          if (match != null) return match.group(1);
        }
        return '$baseUrl${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
      } catch (_) {}
      return photoStr;
    }

    // 3. Jika sudah full URL http/https yang valid
    if (photoStr.startsWith('http://') || photoStr.startsWith('https://')) {
      return photoStr;
    }

    // 4. Path relatif: gabungkan dengan baseUrl + folder
    final baseUrl = _getServerBaseUrl();
    if (baseUrl.isEmpty) return photoStr;

    // Hapus prefix '/' jika ada
    if (photoStr.startsWith('/')) {
      photoStr = photoStr.substring(1);
    }

    // Hapus prefix 'storage/' jika sudah ada
    if (photoStr.startsWith('storage/')) {
      photoStr = photoStr.substring('storage/'.length);
    }

    // Gabungkan dengan folder yang benar
    if (folder != null && folder.isNotEmpty) {
      return '$baseUrl/storage/$folder/$photoStr';
    }

    // Default: gabungkan dengan /storage/
    return '$baseUrl/storage/$photoStr';
  }

  /// ✅ Helper khusus untuk foto profil user
  String? _getUserPhotoUrl(dynamic photoPath) {
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
    }

    // Full URL
    if (photoStr.startsWith('http://') || photoStr.startsWith('https://')) {
      return photoStr;
    }

    // Path relatif untuk foto profil
    final baseUrl = _getServerBaseUrl();
    if (photoStr.startsWith('images/profile/')) {
      return '$baseUrl/$photoStr';
    }
    return '$baseUrl/images/profile/$photoStr';
  }

  /// ✅ Membangun NetworkImage dengan header auth jika internal
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
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
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
    final provider = context.watch<PengembalianProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFEF9E7),
      body: Stack(
        children: [
          Column(
            children: [
              // ==================== HEADER CARD ====================
              _buildHeaderCard(),

              // ==================== SEARCH BAR ====================
              _buildSearchBar(),

              // ==================== LIST ====================
              Expanded(
                child: provider.isLoading
                    ? _buildShimmerList()
                    : provider.error != null
                    ? _buildError(provider)
                    : provider.items.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        color: const Color(0xFFD97706),
                        onRefresh: () => provider.fetchAll(
                          search: _currentSearch,
                          tanggal: _currentTanggal,
                          refresh: true,
                        ),
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          itemCount:
                              provider.items.length +
                              (provider.hasMore ? 1 : 0),
                          itemBuilder: (ctx, i) {
                            if (i >= provider.items.length) {
                              return _buildLoadingMore();
                            }
                            final item = provider.items[i];
                            return _StaggeredPengembalianCard(
                              item: item,
                              index: i,
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PengembalianAlatDetailPage(
                                      hashid: item['hashid'] ?? '',
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  provider.fetchAll(refresh: true);
                                }
                              },
                              onLihatBukti: (fotoBuktiUrl) {
                                _showBuktiModal(fotoBuktiUrl);
                              },
                              getPhotoUrl: _getPhotoUrl,
                              buildNetworkImage: _buildNetworkImage,
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),

          // ==================== MODAL BUKTI PENGEMBALIAN ====================
          if (_imgModal && _imgSrc != null)
            Stack(
              children: [
                // Backdrop
                GestureDetector(
                  onTap: _hideBuktiModal,
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
                // Header
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
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
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
                                'Foto Bukti Pengembalian',
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
                          onTap: _hideBuktiModal,
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
                // Image dengan InteractiveViewer
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
                // Footer hint
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

  // ==================== HEADER CARD ====================
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFFFFF), Color(0xFFFFF3E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border.all(
          color: const Color(0xFFFFE082).withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.1),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFEA580C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.assignment_return,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengembalian Alat',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Riwayat pengembalian alat oleh pengguna',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _showDateFilter,
                    icon: Icon(
                      _currentTanggal != null
                          ? Icons.filter_alt
                          : Icons.calendar_today,
                      size: 18,
                    ),
                    label: Text(
                      _currentTanggal != null
                          ? 'Filter: $_currentTanggal'
                          : 'Filter Tanggal',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD97706),
                      side: const BorderSide(color: Color(0xFFD97706)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              if (_currentTanggal != null) ...[
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  width: 44,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _currentTanggal = null);
                      context.read<PengembalianProvider>().fetchAll(
                        refresh: true,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.clear, size: 18),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ==================== SEARCH BAR ====================
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Cari alat, pengguna, atau bagian...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Icon(Icons.search_rounded, color: const Color(0xFFD97706)),
          ),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchCtrl.clear();
                    _currentSearch = null;
                    context.read<PengembalianProvider>().fetchAll(
                      refresh: true,
                    );
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (v) {
          _currentSearch = v;
          context.read<PengembalianProvider>().fetchAll(
            search: v,
            tanggal: _currentTanggal,
            refresh: true,
          );
        },
      ),
    );
  }

  void _showDateFilter() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFD97706)),
        ),
        child: child!,
      ),
    );

    if (date != null) {
      final formatted =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      setState(() => _currentTanggal = formatted);
      context.read<PengembalianProvider>().fetchAll(
        search: _currentSearch,
        tanggal: formatted,
        refresh: true,
      );
    }
  }

  Widget _buildLoadingMore() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD97706)),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ShimmerCard(),
      ),
    );
  }

  Widget _buildError(PengembalianProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              provider.error ?? 'Gagal memuat data',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => provider.fetchAll(refresh: true),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        builder: (context, value, child) =>
            Opacity(opacity: value, child: child),
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
              child: Icon(
                Icons.assignment_return_outlined,
                size: 48,
                color: Colors.amber.shade300,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Belum ada riwayat pengembalian alat',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== KARTU PENGEMBALIAN ====================
class _StaggeredPengembalianCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final int index;
  final VoidCallback onTap;
  final Function(String) onLihatBukti;
  // ✅ PERBAIKAN: Tambah parameter folder
  final String? Function(dynamic, {String? folder}) getPhotoUrl;
  final Widget Function(String?, {BoxFit fit}) buildNetworkImage;

  const _StaggeredPengembalianCard({
    required this.item,
    required this.index,
    required this.onTap,
    required this.onLihatBukti,
    required this.getPhotoUrl,
    required this.buildNetworkImage,
  });

  @override
  State<_StaggeredPengembalianCard> createState() =>
      _StaggeredPengembalianCardState();
}

class _StaggeredPengembalianCardState extends State<_StaggeredPengembalianCard>
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
    final pengambilan = item['pengambilan'] ?? {};
    final alat = pengambilan['alat'] ?? {};
    final user = item['user'] ?? {};
    final bagian = pengambilan['bagian'] ?? {};

    final namaAlat = alat['nama_alat'] ?? 'Alat Tidak Diketahui';
    final merkAlat = alat['merk'] ?? '';
    final gambarAlat =
        alat['foto_thumb_url'] ?? alat['foto_url'] ?? alat['foto'];

    // ✅ PERBAIKAN: Tambahkan folder 'alat' untuk foto alat
    final fotoAlatUrl = widget.getPhotoUrl(gambarAlat, folder: 'alat');

    final peminjam = user['name'] ?? '-';
    final namaBagian = bagian['nama'] ?? '-';
    final tanggalKembali = _formatDateTime(item['tanggal_pengembalian']);
    final jumlah = item['jumlah'] ?? 0;
    final keterangan = item['keterangan'];

    // ✅ PERBAIKAN: Tambahkan folder 'peng embalian' untuk foto bukti
    final fotoBuktiPath = item['foto'];
    final fotoBuktiUrl = widget.getPhotoUrl(
      fotoBuktiPath,
      folder: 'pengembalian',
    );
    final hasBukti = fotoBuktiUrl != null && fotoBuktiUrl.toString().isNotEmpty;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: Transform.scale(scale: _scaleAnimation.value, child: child),
        );
      },
      child: _ScaleTap(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade100, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // ==================== STATUS INDICATOR BAR (HIJAU) ====================
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF34D399), Color(0xFF10B981)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                  ),
                ),

                // ==================== THUMBNAIL ====================
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.grey.shade100,
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: fotoAlatUrl != null
                              ? Image.network(
                                  fotoAlatUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _defaultImage(),
                                )
                              : _defaultImage(),
                        ),
                      ),
                      // Status icon overlay (check circle hijau)
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            size: 12,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================== INFO UTAMA ====================
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nama alat + merk
                        Text(
                          namaAlat,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (merkAlat.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              merkAlat,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        const SizedBox(height: 6),

                        // Status badge "Sudah Dikembalikan"
                        _buildStatusBadge(),
                        const SizedBox(height: 8),

                        // Info grid
                        _buildInfoRow(
                          icon: Icons.person,
                          label: 'Peminjam',
                          value: peminjam,
                        ),
                        const SizedBox(height: 4),
                        _buildInfoRow(
                          icon: Icons.business,
                          label: 'Bagian',
                          value: namaBagian,
                        ),
                        const SizedBox(height: 4),
                        _buildInfoRow(
                          icon: Icons.calendar_today,
                          label: 'Tanggal Kembali',
                          value: tanggalKembali,
                        ),
                        const SizedBox(height: 4),
                        _buildInfoRow(
                          icon: Icons.inventory_2,
                          label: 'Jumlah',
                          value: '$jumlah',
                        ),

                        // Keterangan (jika ada)
                        if (keterangan != null &&
                            keterangan.toString().isNotEmpty &&
                            keterangan != '-') ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.description,
                                  size: 11,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    keterangan,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue.shade700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ==================== TOMBOL BUKTI / CHEVRON ====================
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: hasBukti
                      ? GestureDetector(
                          onTap: () {
                            widget.onLihatBukti(fotoBuktiUrl);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFD97706), Color(0xFFEA580C)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.photo_library,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Bukti',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.chevron_right,
                            color: Color(0xFFD97706),
                            size: 20,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.check_circle, size: 11, color: Colors.green),
          const SizedBox(width: 4),
          const Text(
            'Sudah Dikembalikan',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 11, color: Colors.amber.shade600),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

  Widget _defaultImage() => Container(
    color: Colors.amber.shade50,
    child: Icon(Icons.build, size: 28, color: Colors.amber.shade300),
  );
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
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: _shimmerAnimation.value,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _shimmerAnimation.value,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 150,
                        decoration: BoxDecoration(
                          color: _shimmerAnimation.value,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 10,
                        width: 100,
                        decoration: BoxDecoration(
                          color: _shimmerAnimation.value,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 10,
                        width: 120,
                        decoration: BoxDecoration(
                          color: _shimmerAnimation.value,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==================== SCALE TAP ====================
class _ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _ScaleTap({required this.child, required this.onTap});

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: widget.child,
      ),
    );
  }
}
