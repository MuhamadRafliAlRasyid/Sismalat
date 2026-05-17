// lib/pages/alat/alat_list_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      context.read<AlatProvider>().fetchAlats();
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
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlatFormPage()),
                );
                provider.fetchAlats();
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
                ? _buildShimmerGrid()
                : provider.error != null
                ? _buildError(provider)
                : provider.alats.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    color: const Color(0xFFD97706),
                    onRefresh: () => provider.fetchAlats(),
                    child: _buildAlatGrid(provider),
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
          BoxShadow(color: Colors.amber.withOpacity(0.1), blurRadius: 12),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Cari alat...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFFD97706)),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchCtrl.clear();
                    context.read<AlatProvider>().fetchAlats();
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
        onSubmitted: (v) => context.read<AlatProvider>().fetchAlats(search: v),
      ),
    );
  }

  Widget _buildAlatGrid(AlatProvider provider) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemCount: provider.alats.length,
      itemBuilder: (context, index) {
        final alat = provider.alats[index];
        return _StaggeredAlatCard(
          alat: alat,
          index: index,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AlatDetailPage(hashid: alat.hashid),
            ),
          ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 8),
          Text(provider.error ?? 'Gagal memuat'),
          ElevatedButton(
            onPressed: () => provider.fetchAlats(),
            child: const Text('Coba lagi'),
          ),
        ],
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
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada alat',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------- Kartu Alat dengan Stagger & Hover -------------------
class _StaggeredAlatCard extends StatefulWidget {
  final dynamic alat;
  final int index;
  final VoidCallback onTap;
  const _StaggeredAlatCard({
    required this.alat,
    required this.index,
    required this.onTap,
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

  Widget _buildCardContent(dynamic alat) {
    final statusColor = (alat.status ?? '').toLowerCase() == 'ok'
        ? Colors.green
        : (alat.status ?? '').toLowerCase() == 'warning'
        ? Colors.orange
        : Colors.red;

    final info = <String>[];
    if (alat.tipe != null && alat.tipe!.isNotEmpty) info.add(alat.tipe!);
    if (alat.kelas != null && alat.kelas!.isNotEmpty)
      info.add('Kls: ${alat.kelas}');
    if (alat.noSeri != null && alat.noSeri!.isNotEmpty)
      info.add('SN: ${alat.noSeri}');
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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 120,
              width: double.infinity,
              color: Colors.grey.shade100,
              child: alat.fotoThumb != null
                  ? Image.network(
                      alat.fotoThumb!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _defaultImage(alat.namaAlat),
                    )
                  : _defaultImage(alat.namaAlat),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alat.namaAlat ?? 'Tanpa Nama',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                if (alat.merk != null && alat.merk!.isNotEmpty)
                  Text(
                    alat.merk!,
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
                        'Stok: ${alat.jumlah ?? 0}',
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
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        alat.status ?? '?',
                        style: TextStyle(
                          color: statusColor,
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

  Widget _defaultImage(String? name) {
    return Container(
      color: Colors.amber.shade50,
      child: const Center(
        child: Icon(Icons.build, size: 40, color: Color(0xFFD97706)),
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
