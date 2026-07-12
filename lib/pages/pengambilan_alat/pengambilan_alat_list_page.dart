import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/api.dart';
import '../../services/auth_service.dart';
import '../../providers/pengambilan_provider.dart';
import 'pengambilan_alat_detail_page.dart';
import 'pengambilan_alat_form_page.dart';

class PengambilanAlatListPage extends StatefulWidget {
  const PengambilanAlatListPage({super.key});

  @override
  State<PengambilanAlatListPage> createState() =>
      _PengambilanAlatListPageState();
}

class _PengambilanAlatListPageState extends State<PengambilanAlatListPage>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _scrollController = ScrollController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String? _currentSearch;
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
      context.read<PengambilanProvider>().fetchAll(refresh: true);
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
      context.read<PengambilanProvider>().loadMore(search: _currentSearch);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PengambilanProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFEF9E7),
      body: Column(
        children: [
          _buildHeaderCard(),
          _buildSearchBar(),
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
                          provider.items.length + (provider.hasMore ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        if (i >= provider.items.length) {
                          return _buildLoadingMore();
                        }
                        final item = provider.items[i];
                        return _StaggeredPengambilanCard(
                          item: item,
                          index: i,
                          getPhotoUrl: _getPhotoUrl,
                          getUserPhotoUrl: _getUserPhotoUrl,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PengambilanAlatDetailPage(
                                  hashid: item['hashid'] ?? '',
                                ),
                              ),
                            );
                            if (result == true) {
                              provider.fetchAll(refresh: true);
                            }
                          },
                        );
                      },
                    ),
                  ),
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
                  Icons.move_to_inbox,
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
                      'Pengambilan Alat',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Riwayat peminjaman alat oleh pengguna',
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
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PengambilanAlatFormPage(),
                        ),
                      );
                      if (result == true) {
                        context.read<PengambilanProvider>().fetchAll(
                          refresh: true,
                        );
                      }
                    },
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text(
                      'Ambil Alat Baru',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                      shadowColor: Colors.amber.withOpacity(0.4),
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
                    context.read<PengambilanProvider>().fetchAll(refresh: true);
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
          context.read<PengambilanProvider>().fetchAll(
            search: v,
            refresh: true,
          );
        },
      ),
    );
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

  Widget _buildError(PengambilanProvider provider) {
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
                Icons.move_to_inbox_outlined,
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
              'Belum ada riwayat pengambilan alat',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PengambilanAlatFormPage(),
                  ),
                );
                if (result == true) {
                  context.read<PengambilanProvider>().fetchAll(refresh: true);
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ambil Alat Baru'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== KARTU PENGAMBILAN ====================
class _StaggeredPengambilanCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final int index;
  final VoidCallback onTap;
  final String? Function(dynamic, {String? folder}) getPhotoUrl;
  final String? Function(dynamic) getUserPhotoUrl;

  const _StaggeredPengambilanCard({
    required this.item,
    required this.index,
    required this.onTap,
    required this.getPhotoUrl,
    required this.getUserPhotoUrl,
  });

  @override
  State<_StaggeredPengambilanCard> createState() =>
      _StaggeredPengambilanCardState();
}

class _StaggeredPengambilanCardState extends State<_StaggeredPengambilanCard>
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
    final alat = item['alat'] ?? {};
    final user = item['user'] ?? {};
    final bagian = item['bagian'] ?? {};

    final namaAlat = alat['nama_alat'] ?? 'Alat Tidak Diketahui';
    final merkAlat = alat['merk'] ?? '';
    final gambarAlat =
        alat['foto_thumb_url'] ?? alat['foto_url'] ?? alat['foto'];
    // ✅ Foto alat dari folder 'alat'
    final fotoAlatUrl = widget.getPhotoUrl(gambarAlat, folder: 'alat');

    final peminjam = item['nama_peminjam'] ?? user['name'] ?? '-';
    final namaBagian = bagian['nama'] ?? '-';
    final waktuAmbil = _formatDateTime(item['waktu_pengambilan']);
    final lamaPinjam = item['lama_pinjam'] ?? '-';
    final jumlah = item['jumlah'] ?? 0;
    final satuan = item['satuan'] ?? 'pcs';
    final status = item['status'] ?? 'dipinjam';
    final isDipinjam = status == 'dipinjam';

    // Status jatuh tempo
    final jatuhTempo = item['tanggal_jatuh_tempo'];
    final sisaHariLabel = item['sisa_hari_label'] ?? '';
    final shouldWarn1Day = item['should_warn_1day'] ?? false;
    final shouldWarn15Percent = item['should_warn_15'] ?? false;
    final statusPinjam = item['status_pinjam'] ?? 'aman';

    // Warna status
    Color statusBarColor;
    IconData statusIcon;
    Color statusIconBg;
    Color statusIconColor;

    if (shouldWarn1Day) {
      statusBarColor = Colors.red;
      statusIcon = Icons.warning;
      statusIconBg = Colors.red.shade100;
      statusIconColor = Colors.red;
    } else if (shouldWarn15Percent || statusPinjam == 'warning') {
      statusBarColor = Colors.orange;
      statusIcon = Icons.warning_amber;
      statusIconBg = Colors.orange.shade100;
      statusIconColor = Colors.orange;
    } else if (isDipinjam) {
      statusBarColor = Colors.red;
      statusIcon = Icons.access_time;
      statusIconBg = Colors.red.shade100;
      statusIconColor = Colors.red;
    } else {
      statusBarColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusIconBg = Colors.green.shade100;
      statusIconColor = Colors.green;
    }

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
                // ==================== STATUS INDICATOR BAR ====================
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [statusBarColor.withOpacity(0.8), statusBarColor],
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
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: statusIconBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: statusIconColor.withOpacity(0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            statusIcon,
                            size: 12,
                            color: statusIconColor,
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

                        _buildStatusBadge(
                          isDipinjam: isDipinjam,
                          shouldWarn1Day: shouldWarn1Day,
                          shouldWarn15Percent: shouldWarn15Percent,
                        ),
                        const SizedBox(height: 8),

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
                          label: 'Waktu Ambil',
                          value: waktuAmbil,
                        ),
                        const SizedBox(height: 4),
                        _buildInfoRow(
                          icon: Icons.hourglass_bottom,
                          label: 'Lama Pinjam',
                          value: '$lamaPinjam hari',
                        ),

                        if (isDipinjam && jatuhTempo != null) ...[
                          const SizedBox(height: 8),
                          _buildJatuhTempoInfo(
                            jatuhTempo: jatuhTempo,
                            sisaHariLabel: sisaHariLabel,
                            shouldWarn1Day: shouldWarn1Day,
                            shouldWarn15Percent: shouldWarn15Percent,
                            statusPinjam: statusPinjam,
                          ),
                        ],

                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2,
                                size: 12,
                                color: Colors.amber.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$jumlah $satuan',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
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

  Widget _buildStatusBadge({
    required bool isDipinjam,
    required bool shouldWarn1Day,
    required bool shouldWarn15Percent,
  }) {
    Color bgColor;
    Color textColor;
    Color dotColor;
    String text;
    IconData? icon;

    if (shouldWarn1Day) {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      dotColor = Colors.red;
      text = 'BESOK JATUH TEMPO!';
      icon = Icons.warning;
    } else if (shouldWarn15Percent) {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
      dotColor = Colors.orange;
      text = 'Peringatan Pengembalian';
      icon = Icons.warning_amber;
    } else if (isDipinjam) {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      dotColor = Colors.red;
      text = 'Dipinjam';
    } else {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      dotColor = Colors.green;
      text = 'Dikembalikan';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: dotColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          if (icon != null) ...[
            Icon(icon, size: 11, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
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

  Widget _buildJatuhTempoInfo({
    required dynamic jatuhTempo,
    required String sisaHariLabel,
    required bool shouldWarn1Day,
    required bool shouldWarn15Percent,
    required String statusPinjam,
  }) {
    String jatuhTempoFormatted = '-';
    try {
      final date = DateTime.parse(jatuhTempo.toString());
      jatuhTempoFormatted =
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {}

    Color bgColor;
    Color textColor;
    IconData icon;
    String text;

    if (shouldWarn1Day) {
      bgColor = Colors.red;
      textColor = Colors.white;
      icon = Icons.warning;
      text = '🔴 BESOK JATUH TEMPO!';
    } else if (shouldWarn15Percent) {
      bgColor = Colors.orange;
      textColor = Colors.white;
      icon = Icons.warning_amber;
      text = '⚠️ $sisaHariLabel';
    } else if (statusPinjam == 'aman') {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      icon = Icons.check_circle;
      text = sisaHariLabel;
    } else if (statusPinjam == 'warning') {
      bgColor = Colors.yellow.shade50;
      textColor = Colors.yellow.shade700;
      icon = Icons.warning_amber;
      text = sisaHariLabel;
    } else if (statusPinjam == 'terlambat') {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      icon = Icons.error;
      text = sisaHariLabel;
    } else {
      bgColor = Colors.blue.shade50;
      textColor = Colors.blue.shade700;
      icon = Icons.calendar_today;
      text = sisaHariLabel;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today, size: 11, color: Colors.blue.shade700),
              const SizedBox(width: 4),
              Text(
                'Jatuh Tempo: $jatuhTempoFormatted',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        if (sisaHariLabel.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 11, color: textColor),
                const SizedBox(width: 4),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
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
