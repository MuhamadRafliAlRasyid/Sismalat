// lib/pages/dashboard/dashboard_page.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../config/api.dart';

import 'auth/login_page.dart';
import 'profile/profile_page.dart';
import 'profile/user_list_page.dart';
import 'alat/alat_list_page.dart';
import 'kalibrasi/kalibrasi_list_page.dart';
import 'kategori/kategori_list_page.dart';
import 'pengambilan_alat/pengambilan_alat_list_page.dart';
import 'pengembalian_alat/pengembalian_alat_list_page.dart';
import 'qr_scanner_page.dart'; // pastikan import halaman scanner
import 'pengambilan_alat/pengambilan_alat_form_page.dart'; // import form

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  Map<String, dynamic>? userData;
  String userName = "User";
  String userInitial = "U";
  String? profilePhotoUrl;
  int unreadNotificationCount = 0;
  bool _isLoading = true;

  // Animasi kemunculan konten
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Animasi FAB denyut
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool get isAdmin => userData?['role'] == 'admin';

  List<Map<String, dynamic>> get _adminMenu => [
    {'icon': Icons.build_outlined, 'label': 'Alat', 'route': '/alat/list'},
    {
      'icon': Icons.science_outlined,
      'label': 'Kalibrasi',
      'route': '/kalibrasi/list',
    },
    {
      'icon': Icons.category_outlined,
      'label': 'Kategori',
      'route': '/kategori/list',
    },
    {
      'icon': Icons.move_to_inbox_outlined,
      'label': 'Pengambilan Alat',
      'route': '/pengambilan_alat/list',
    },
    {
      'icon': Icons.replay_outlined,
      'label': 'Pengembalian Alat',
      'route': '/pengembalian_alat/list',
    },
    {
      'icon': Icons.people_outline,
      'label': 'Daftar Bagian',
      'route': '/bagian/list',
    },
    {
      'icon': Icons.group_outlined,
      'label': 'Daftar User',
      'route': '/user/list',
    },
  ];

  List<Map<String, dynamic>> get _karyawanMenu => [
    {'icon': Icons.build_outlined, 'label': 'Alat', 'route': '/alat/list'},
    {
      'icon': Icons.move_to_inbox_outlined,
      'label': 'Pengambilan Alat',
      'route': '/pengambilan_alat/list',
    },
    {
      'icon': Icons.replay_outlined,
      'label': 'Pengembalian Alat',
      'route': '/pengembalian_alat/list',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadUserData();
    await _loadUnreadNotifications();
    if (mounted) {
      setState(() => _isLoading = false);
      _fadeController.forward(); // mulai fade-in konten utama
    }
  }

  Future<void> _onRefresh() async {
    await _loadUserData();
    await _loadUnreadNotifications();
  }

  Future<void> _loadUserData() async {
    final result = await AuthService.getProfile();
    if (result['status'] == true && result['user'] != null) {
      final user = result['user'];
      setState(() {
        userData = user;
        userName = user['name'] ?? 'User';
        userInitial = (user['name'] ?? 'U').substring(0, 1).toUpperCase();

        final photoPath = user['profile_photo_path'];
        final imageUrl = photoPath != null && photoPath.toString().isNotEmpty
            ? '${Apiimg.baseUrl}/images/profile/$photoPath'
            : null;
        profilePhotoUrl = imageUrl;
      });
    }
  }

  Future<void> _loadUnreadNotifications() async {
    final count = await NotificationService.getUnreadCount();
    if (mounted) setState(() => unreadNotificationCount = count);
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // 🆕 Scan QR, tangkap hasil, lalu buka form pengambilan dengan alat terpilih
  void _onScanPressed() async {
    final hashid = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerPage()),
    );

    if (hashid != null && hashid.toString().isNotEmpty) {
      // Buka form pengambilan alat dengan alat yang sudah terpilih
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PengambilanAlatFormPage(alatHashid: hashid.toString()),
        ),
      );
    }
  }

  void _onMenuTapped(int index) {
    final menuList = isAdmin ? _adminMenu : _karyawanMenu;
    final route = menuList[index]['route'] as String?;
    if (route != null) Navigator.pushNamed(context, route);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuList = isAdmin ? _adminMenu : _karyawanMenu;
    return Scaffold(
      backgroundColor: const Color(0xFFFEF9E7),
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          // Notifikasi dengan badge animasi
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: unreadNotificationCount > 0
                    ? Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          key: const ValueKey('notif_badge'),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadNotificationCount > 99
                                ? '99+'
                                : '$unreadNotificationCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          // Avatar dengan Hero dan animasi
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            icon: _isLoading
                ? const CircleAvatar(
                    backgroundColor: Colors.amber,
                    radius: 18,
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Hero(
                    tag: 'profileAvatar',
                    child: CircleAvatar(
                      backgroundColor: Colors.amber.shade100,
                      radius: 18,
                      backgroundImage: profilePhotoUrl != null
                          ? NetworkImage(profilePhotoUrl!)
                          : null,
                      child: profilePhotoUrl == null
                          ? Text(
                              userInitial,
                              style: const TextStyle(
                                color: Color(0xFFD97706),
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              } else if (value == 'logout') {
                await _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Profil Saya'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Keluar', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: const Color(0xFFD97706),
          child: _isLoading
              ? _buildShimmer()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSlide(
                          duration: const Duration(milliseconds: 500),
                          offset: Offset.zero,
                          child: Text(
                            'Selamat datang, $userName',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedSlide(
                          duration: const Duration(
                            milliseconds: 500,
                            microseconds: 200,
                          ),
                          offset: Offset.zero,
                          child: Text(
                            'Kelola inventaris dengan mudah',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildMenuGrid(menuList),
                      ],
                    ),
                  ),
                ),
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _pulseAnimation.value, child: child);
        },
        child: FloatingActionButton(
          onPressed: _onScanPressed,
          backgroundColor: const Color(0xFFD97706),
          foregroundColor: Colors.white,
          elevation: 6,
          shape: const CircleBorder(),
          child: const Icon(Icons.qr_code_scanner_rounded, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFD97706),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_outlined),
            label: 'Barang',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(List<Map<String, dynamic>> menuList) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(menuList.length, (index) {
        return _StaggeredMenuItem(
          index: index,
          item: menuList[index],
          onTap: () => _onMenuTapped(index),
        );
      }),
    );
  }

  Widget _buildShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 28,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 20,
            width: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(6, (index) {
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 56) / 3,
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30, horizontal: 8),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// Widget untuk menampilkan satu item menu dengan animasi staggered
class _StaggeredMenuItem extends StatefulWidget {
  final int index;
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const _StaggeredMenuItem({
    required this.index,
    required this.item,
    required this.onTap,
  });

  @override
  State<_StaggeredMenuItem> createState() => _StaggeredMenuItemState();
}

class _StaggeredMenuItemState extends State<_StaggeredMenuItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    final delay = widget.index * 50;

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
          ),
        );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    // Mulai animasi setelah widget terpasang
    Future.delayed(Duration(milliseconds: 100 + delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Transform.scale(scale: _scaleAnimation.value, child: child),
          ),
        );
      },
      child: _ScaleTap(
        onTap: widget.onTap,
        child: SizedBox(
          width: (MediaQuery.of(context).size.width - 56) / 3,
          child: Card(
            elevation: 2,
            shadowColor: Colors.amber.withOpacity(0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      widget.item['icon'],
                      size: 30,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.item['label'],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Widget efek tap dengan animasi skala
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
