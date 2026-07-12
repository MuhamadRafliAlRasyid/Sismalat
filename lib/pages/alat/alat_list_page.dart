import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/api.dart';
import '../../services/auth_service.dart';
import '../../providers/alat_provider.dart';
import 'alat_detail_page.dart';
import 'alat_form_page.dart';

class AlatListPage extends StatefulWidget {
  const AlatListPage({super.key});

  @override
  State<AlatListPage> createState() => _AlatListPageState();
}

class _AlatListPageState extends State<AlatListPage>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _scrollController = ScrollController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String? _currentSearch;
  String? _selectedKategoriId;
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
      context.read<AlatProvider>().fetchAlats(refresh: true);
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
      context.read<AlatProvider>().loadMore(
        search: _currentSearch,
        kategoriId: _selectedKategoriId,
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

  // ==================== HELPER URL FOTO ====================

  /// ✅ Fix URL localhost menjadi IP server yang benar
  String _fixLocalhostUrl(String url) {
    return url
        .replaceAll('http://127.0.0.1:8000', Apiimg.baseUrl)
        .replaceAll('http://localhost:8000', Apiimg.baseUrl)
        .replaceAll('http://127.0.0.1', Apiimg.baseUrl)
        .replaceAll('http://localhost', Apiimg.baseUrl);
  }

  /// ✅ Ambil URL GAMBAR ASLI dari backend (bukan thumbnail)
  String? _getFotoUrl(Map<String, dynamic> alat) {
    // ✅ Prioritas 1: foto_url (gambar asli) dari backend
    final fotoUrl = alat['foto_url'];
    if (fotoUrl != null && fotoUrl.toString().isNotEmpty) {
      return _fixLocalhostUrl(fotoUrl.toString());
    }

    // ✅ Prioritas 2: foto_thumb_url sebagai fallback
    final thumbUrl = alat['foto_thumb_url'];
    if (thumbUrl != null && thumbUrl.toString().isNotEmpty) {
      return _fixLocalhostUrl(thumbUrl.toString());
    }

    // ✅ Prioritas 3: QR Code sebagai fallback terakhir
    final qrUrl = alat['qr_code_url'];
    if (qrUrl != null && qrUrl.toString().isNotEmpty) {
      return _fixLocalhostUrl(qrUrl.toString());
    }

    return null;
  }

  /// ✅ Membangun NetworkImage dengan header auth
  Widget _buildNetworkImage(String? imageUrl, {BoxFit fit = BoxFit.cover}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildPlaceholderImage();
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
      errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
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

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.amber.shade50,
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          size: 32,
          color: Color(0xFFD97706),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlatProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFEF9E7),
      appBar: AppBar(
        title: const Text(
          'Katalog Alat',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, size: 24),
            tooltip: 'Filter Kategori',
            onPressed: () => _showKategoriFilter(provider),
          ),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: child,
              );
            },
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 28),
              tooltip: 'Tambah Alat',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlatFormPage()),
                );
                if (result == true) {
                  provider.fetchAlats(refresh: true);
                }
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_selectedKategoriId != null) _buildKategoriBadge(provider),
          Expanded(
            child: provider.isLoading
                ? _buildShimmerGrid()
                : provider.error != null
                ? _buildError(provider)
                : provider.alats.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    color: const Color(0xFFD97706),
                    onRefresh: () => provider.fetchAlats(
                      search: _currentSearch,
                      kategoriId: _selectedKategoriId,
                      refresh: true,
                    ),
                    child: _buildAlatGrid(provider),
                  ),
          ),
        ],
      ),
    );
  }

  void _showKategoriFilter(AlatProvider provider) async {
    if (provider.kategoris.isEmpty) {
      await provider.getCreateData();
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Kategori',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _kategoriChip('Semua', null, provider),
                ...provider.kategoris.map(
                  (kat) => _kategoriChip(
                    kat['nama'] ?? '-',
                    kat['id'].toString(),
                    provider,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _kategoriChip(String label, String? value, AlatProvider provider) {
    final isSelected = _selectedKategoriId == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedKategoriId = value;
        });
        Navigator.pop(context);
        provider.fetchAlats(
          search: _currentSearch,
          kategoriId: value,
          refresh: true,
        );
      },
      selectedColor: const Color(0xFFD97706),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildKategoriBadge(AlatProvider provider) {
    final kategori = provider.kategoris.firstWhere(
      (k) => k['id'].toString() == _selectedKategoriId,
      orElse: () => {'nama': 'Unknown'},
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFD97706).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 16, color: Color(0xFFD97706)),
          const SizedBox(width: 8),
          Text(
            'Kategori: ${kategori['nama']}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFD97706),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              setState(() => _selectedKategoriId = null);
              provider.fetchAlats(search: _currentSearch, refresh: true);
            },
            child: const Icon(Icons.close, size: 18, color: Color(0xFFD97706)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.amber.withOpacity(0.1), blurRadius: 12),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Cari alat...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFD97706)),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchCtrl.clear();
                    _currentSearch = null;
                    context.read<AlatProvider>().fetchAlats(refresh: true);
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (v) {
          _currentSearch = v;
          context.read<AlatProvider>().fetchAlats(
            search: v,
            kategoriId: _selectedKategoriId,
            refresh: true,
          );
        },
      ),
    );
  }

  Widget _buildAlatGrid(AlatProvider provider) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemCount: provider.alats.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= provider.alats.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD97706)),
              ),
            ),
          );
        }
        final alat = provider.alats[index];
        return _StaggeredAlatCard(
          alat: alat,
          index: index,
          getFotoUrl: _getFotoUrl,
          buildNetworkImage: _buildNetworkImage,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AlatDetailPage(hashid: alat['hashid']),
              ),
            );
            if (result == true) {
              provider.fetchAlats(refresh: true);
            }
          },
        );
      },
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const _ShimmerAlatCard(),
    );
  }

  Widget _buildError(AlatProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              provider.error ?? 'Gagal memuat data',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => provider.fetchAlats(refresh: true),
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
        builder: (context, value, child) {
          return Opacity(opacity: value, child: child);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 72,
              color: Colors.amber.shade200,
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada alat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tambahkan dengan tombol +',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------- Kartu Alat dengan Animasi -------------------
class _StaggeredAlatCard extends StatefulWidget {
  final Map<String, dynamic> alat;
  final int index;
  final VoidCallback onTap;
  final String? Function(Map<String, dynamic>) getFotoUrl;
  final Widget Function(String?, {BoxFit fit}) buildNetworkImage;

  const _StaggeredAlatCard({
    required this.alat,
    required this.index,
    required this.onTap,
    required this.getFotoUrl,
    required this.buildNetworkImage,
  });

  @override
  State<_StaggeredAlatCard> createState() => _StaggeredAlatCardState();
}

class _StaggeredAlatCardState extends State<_StaggeredAlatCard>
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
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
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
    final alat = widget.alat;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return SlideTransition(
            position: _slideAnimation,
            child: Transform.scale(scale: _scaleAnimation.value, child: child),
          );
        },
        child: _ScaleTap(onTap: widget.onTap, child: _buildCardContent(alat)),
      ),
    );
  }

  Widget _buildCardContent(Map<String, dynamic> alat) {
    final namaAlat = alat['nama_alat'] ?? 'Tanpa Nama';
    final merk = alat['merk'] ?? '';
    final tipe = alat['tipe'] ?? '';
    final noSeri = alat['no_seri'] ?? '';
    final jumlah = alat['jumlah'] ?? 0;

    // ✅ Ambil URL GAMBAR ASLI dari backend
    final fotoUrl = widget.getFotoUrl(alat);

    final info = <String>[];
    if (tipe.isNotEmpty) info.add(tipe);
    if (noSeri.isNotEmpty) info.add('SN: $noSeri');
    final infoText = info.isNotEmpty ? info.join(' · ') : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // ✅ AREA FOTO (GAMBAR ASLI)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 120,
              width: double.infinity,
              color: Colors.grey.shade100,
              child: fotoUrl != null
                  ? widget.buildNetworkImage(fotoUrl, fit: BoxFit.cover)
                  : Container(
                      color: Colors.amber.shade50,
                      child: const Center(
                        child: Icon(
                          Icons.build,
                          size: 40,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaAlat,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                if (merk.isNotEmpty)
                  Text(
                    merk,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                if (infoText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      infoText,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Stok: $jumlah',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (jumlah > 0 ? Colors.green : Colors.red)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        jumlah > 0 ? 'Tersedia' : 'Habis',
                        style: TextStyle(
                          color: jumlah > 0 ? Colors.green : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------- Shimmer Card -------------------
class _ShimmerAlatCard extends StatefulWidget {
  const _ShimmerAlatCard();
  @override
  State<_ShimmerAlatCard> createState() => _ShimmerAlatCardState();
}

class _ShimmerAlatCardState extends State<_ShimmerAlatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = ColorTween(
      begin: Colors.grey.shade200,
      end: Colors.grey.shade100,
    ).animate(_controller);
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 120, color: _animation.value),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      color: _animation.value,
                    ),
                    const SizedBox(height: 8),
                    Container(height: 10, width: 80, color: _animation.value),
                    const SizedBox(height: 8),
                    Container(height: 10, width: 60, color: _animation.value),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ------------------- Scale Tap -------------------
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
      end: 0.92,
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
