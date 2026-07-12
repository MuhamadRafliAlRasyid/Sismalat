import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/kategori_provider.dart';

class KategoriListPage extends StatefulWidget {
  const KategoriListPage({super.key});

  @override
  State<KategoriListPage> createState() => _KategoriListPageState();
}

class _KategoriListPageState extends State<KategoriListPage>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KategoriProvider>().fetchKategoris();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KategoriProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFEF9E7),
      appBar: AppBar(
        title: const Text(
          'Kategori',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        actions: [
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
              tooltip: 'Tambah Kategori',
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  '/kategori/form',
                );
                if (result == true) {
                  provider.fetchKategoris();
                }
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: provider.isLoading
                ? _buildShimmerList()
                : provider.error != null
                ? _buildError(provider)
                : provider.kategoris.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    color: const Color(0xFFD97706),
                    onRefresh: () => provider.fetchKategoris(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: provider.kategoris.length,
                      itemBuilder: (ctx, i) {
                        final kategori = provider.kategoris[i];
                        return _StaggeredKategoriCard(
                          kategori: kategori,
                          index: i,
                          onTap: () async {
                            final result = await Navigator.pushNamed(
                              context,
                              '/kategori/form',
                              arguments: kategori['hashid'],
                            );
                            if (result == true) {
                              provider.fetchKategoris();
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
          hintText: 'Cari kategori...',
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
                    context.read<KategoriProvider>().fetchKategoris();
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
        onSubmitted: (v) =>
            context.read<KategoriProvider>().fetchKategoris(search: v),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ShimmerCard(),
      ),
    );
  }

  Widget _buildError(KategoriProvider provider) {
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
              onPressed: () => provider.fetchKategoris(),
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
            Icon(
              Icons.category_outlined,
              size: 72,
              color: Colors.amber.shade200,
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada kategori',
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

// ---------- Kartu Kategori dengan Animasi ----------
class _StaggeredKategoriCard extends StatefulWidget {
  final Map<String, dynamic> kategori;
  final int index;
  final VoidCallback onTap;

  const _StaggeredKategoriCard({
    required this.kategori,
    required this.index,
    required this.onTap,
  });

  @override
  State<_StaggeredKategoriCard> createState() => _StaggeredKategoriCardState();
}

class _StaggeredKategoriCardState extends State<_StaggeredKategoriCard>
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
    final kategori = widget.kategori;

    // ✅ PERBAIKAN: Pakai bracket notation untuk Map
    final nama = kategori['nama'] ?? 'Tanpa Nama';
    final keterangan = kategori['keterangan'] ?? '-';
    final hashid = kategori['hashid'] ?? '';

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
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shadowColor: Colors.amber.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.category,
                    color: Color(0xFFD97706),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        keterangan,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFFD97706)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- Shimmer Card ----------
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
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _shimmerAnimation.value,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        color: _shimmerAnimation.value,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 120,
                        color: _shimmerAnimation.value,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------- Scale Tap ----------
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
      end: 0.95,
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
