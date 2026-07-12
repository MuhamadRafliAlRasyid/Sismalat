import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/dashboard_service.dart';
import '../config/api.dart';

import 'auth/login_page.dart';
import 'profile/profile_page.dart';
import 'profile/notification_page.dart';
import 'alat/alat_list_page.dart';
import 'profile/edit_profile_page.dart';
import 'kalibrasi/kalibrasi_list_page.dart';
import 'kategori/kategori_list_page.dart';
import 'pengambilan_alat/pengambilan_alat_list_page.dart';
import 'pengembalian_alat/pengembalian_alat_list_page.dart';
import 'qr_scanner_page.dart';
import 'pengambilan_alat/pengambilan_alat_form_page.dart';

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
  int _previousNotificationCount = 0;
  bool _isLoading = true;

  // ✅ Stats data
  Map<String, dynamic> _adminStats = {};
  Map<String, dynamic> _karyawanStats = {};

  // ✅ Animasi
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ✅ Timer untuk auto-refresh
  Timer? _notificationTimer;
  Timer? _statsTimer;

  bool get isAdmin =>
      userData?['role'] == 'admin' || userData?['role'] == 'super';

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

    // ✅ Auto-refresh setiap 30 detik
    _notificationTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadUnreadNotifications(),
    );

    // ✅ Auto-refresh stats setiap 60 detik
    _statsTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _loadStats(),
    );
  }

  Future<void> _loadInitialData() async {
    await _loadUserData();
    await _loadUnreadNotifications();
    await _loadStats();
    if (mounted) {
      setState(() => _isLoading = false);
      _fadeController.forward();
    }
  }

  Future<void> _loadUserData() async {
    final result = await AuthService.getProfile();
    if (result['status'] == true && result['user'] != null) {
      final user = result['user'];
      if (mounted) {
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
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final count = await NotificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _previousNotificationCount = unreadNotificationCount;
          unreadNotificationCount = count;
        });
      }
    } catch (e) {
      print('❌ [Dashboard] Error load notifications: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      if (isAdmin) {
        final stats = await DashboardService.getAdminStats();
        if (mounted) {
          setState(() => _adminStats = stats);
        }
      } else {
        final stats = await DashboardService.getKaryawanStats();
        if (mounted) {
          setState(() => _karyawanStats = stats);
        }
      }
    } catch (e) {
      print('❌ [Dashboard] Error load stats: $e');
    }
  }

  Future<void> _onRefresh() async {
    await _loadUserData();
    await _loadUnreadNotifications();
    await _loadStats();
  }

  Future<void> _logout() async {
    _notificationTimer?.cancel();
    _statsTimer?.cancel();
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _onScanPressed() async {
    final hashid = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerPage()),
    );

    if (hashid != null && hashid.toString().isNotEmpty) {
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

  void _onBottomNavTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _notificationTimer?.cancel();
    _statsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF9E7),
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          _AnimatedNotificationBell(
            unreadCount: unreadNotificationCount,
            previousCount: _previousNotificationCount,
            onTap: () async {
              await Navigator.pushNamed(context, '/notifications');
              _loadUnreadNotifications();
            },
          ),
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
                  child: _buildCurrentTab(),
                ),
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: child,
                );
              },
              child: FloatingActionButton(
                onPressed: _onScanPressed,
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                elevation: 6,
                shape: const CircleBorder(),
                child: const Icon(Icons.qr_code_scanner_rounded, size: 28),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFD97706),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onBottomNavTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_outlined),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Alat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Menu';
      case 2:
        return 'Riwayat Alat';
      case 3:
        return 'Profil';
      default:
        return 'Dashboard';
    }
  }

  /// ✅ Build current tab berdasarkan selected index
  Widget _buildCurrentTab() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildMenuTab();
      case 2:
        return _buildRiwayatTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  // ==================== TAB 1: BERANDA ====================
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Welcome message
          _buildWelcomeHeader(),
          const SizedBox(height: 16),

          // ✅ Notification summary (jika ada)
          if (unreadNotificationCount > 0) ...[
            _buildNotificationSummaryCard(),
            const SizedBox(height: 16),
          ],

          // ✅ Stats cards
          if (isAdmin) _buildAdminStatsCards() else _buildKaryawanStatsCards(),
          const SizedBox(height: 16),

          // ✅ Rasio pengembalian (admin only)
          if (isAdmin) _buildReturnRatioCard(),
          const SizedBox(height: 16),

          // ✅ Quick actions
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    String emoji;

    if (hour < 11) {
      greeting = 'Selamat Pagi';
      emoji = '🌅';
    } else if (hour < 15) {
      greeting = 'Selamat Siang';
      emoji = '☀️';
    } else if (hour < 18) {
      greeting = 'Selamat Sore';
      emoji = '🌤️';
    } else {
      greeting = 'Selamat Malam';
      emoji = '🌙';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $userName!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAdmin
                      ? 'Kelola inventaris dengan mudah'
                      : 'Semoga harimu menyenangkan!',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Admin Stats Cards (Total Alat, Dipinjam, Dikembalikan)
  Widget _buildAdminStatsCards() {
    final totalAlat = _adminStats['total_alat'] ?? 0;
    final totalDipinjam = _adminStats['total_dipinjam'] ?? 0;
    final totalDikembalikan = _adminStats['total_dikembalikan'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'Total Alat',
                value: totalAlat,
                icon: Icons.inventory,
                color: Colors.amber,
                gradient: [Colors.amber.shade400, Colors.amber.shade600],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                label: 'Dipinjam',
                value: totalDipinjam,
                icon: Icons.move_to_inbox,
                color: Colors.orange,
                gradient: [Colors.orange.shade400, Colors.orange.shade600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          label: 'Dikembalikan',
          value: totalDikembalikan,
          icon: Icons.replay,
          color: Colors.yellow.shade700,
          gradient: [Colors.yellow.shade400, Colors.yellow.shade600],
          fullWidth: true,
        ),
      ],
    );
  }

  /// ✅ Karyawan Stats Cards
  Widget _buildKaryawanStatsCards() {
    final totalDipinjam = _karyawanStats['total_dipinjam'] ?? 0;
    final totalDikembalikan = _karyawanStats['total_dikembalikan'] ?? 0;
    final alatTersedia = _karyawanStats['alat_tersedia'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'Dipinjam',
                value: totalDipinjam,
                icon: Icons.move_to_inbox,
                color: Colors.amber,
                gradient: [Colors.amber.shade400, Colors.amber.shade600],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                label: 'Dikembalikan',
                value: totalDikembalikan,
                icon: Icons.replay,
                color: Colors.green,
                gradient: [Colors.green.shade400, Colors.green.shade600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'Scan QR',
                value: 0,
                icon: Icons.qr_code_scanner,
                color: Colors.blue,
                gradient: [Colors.blue.shade400, Colors.blue.shade600],
                isAction: true,
                onTap: _onScanPressed,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                label: 'Alat Tersedia',
                value: alatTersedia,
                icon: Icons.build,
                color: Colors.purple,
                gradient: [Colors.purple.shade400, Colors.purple.shade600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required dynamic value,
    required IconData icon,
    required Color color,
    required List<Color> gradient,
    bool fullWidth = false,
    bool isAction = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isAction ? 'Tap untuk scan' : _formatNumber(value),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Rasio Pengembalian Card
  Widget _buildReturnRatioCard() {
    final totalDipinjam = _adminStats['total_dipinjam'] ?? 0;
    final totalDikembalikan = _adminStats['total_dikembalikan'] ?? 0;
    final rasio = totalDipinjam > 0
        ? ((totalDikembalikan / totalDipinjam) * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Icon(Icons.show_chart, color: Colors.amber.shade600),
              const SizedBox(width: 8),
              const Text(
                'Rasio Pengembalian',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: rasio / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.shade400,
                            Colors.orange.shade500,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$rasio%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$totalDikembalikan dari $totalDipinjam barang dipinjam telah kembali',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  /// ✅ Quick Actions
  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aksi Cepat',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.qr_code_scanner,
                  label: 'Scan QR',
                  color: Colors.blue,
                  onTap: _onScanPressed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.move_to_inbox,
                  label: 'Ambil Alat',
                  color: Colors.amber,
                  onTap: () =>
                      Navigator.pushNamed(context, '/pengambilan_alat/form'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.replay,
                  label: 'Kembalikan',
                  color: Colors.green,
                  onTap: () =>
                      Navigator.pushNamed(context, '/pengembalian_alat/list'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.notifications,
                  label: 'Notifikasi',
                  color: Colors.red,
                  onTap: () => Navigator.pushNamed(context, '/notifications'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TAB 2: MENU ====================
  Widget _buildMenuTab() {
    final menuList = isAdmin
        ? [
            {
              'icon': Icons.build_outlined,
              'label': 'Alat',
              'route': '/alat/list',
            },
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
              'label': 'Pengambilan',
              'route': '/pengambilan_alat/list',
            },
            {
              'icon': Icons.replay_outlined,
              'label': 'Pengembalian',
              'route': '/pengembalian_alat/list',
            },
            {
              'icon': Icons.people_outline,
              'label': 'Bagian',
              'route': '/bagian/list',
            },
            {
              'icon': Icons.group_outlined,
              'label': 'User',
              'route': '/user/list',
            },
          ]
        : [
            {
              'icon': Icons.build_outlined,
              'label': 'Alat',
              'route': '/alat/list',
            },
            {
              'icon': Icons.move_to_inbox_outlined,
              'label': 'Pengambilan',
              'route': '/pengambilan_alat/list',
            },
            {
              'icon': Icons.replay_outlined,
              'label': 'Pengembalian',
              'route': '/pengembalian_alat/list',
            },
          ];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAdmin ? 'Menu Admin' : 'Menu Karyawan',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih menu untuk mengelola',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(menuList.length, (index) {
              return _StaggeredMenuItem(
                index: index,
                item: menuList[index],
                onTap: () {
                  final route = menuList[index]['route'] as String?;
                  if (route != null) Navigator.pushNamed(context, route);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 3: RIWAYAT ALAT ====================
  Widget _buildRiwayatTab() {
    return const AlatListPage();
  }

  // ==================== TAB 4: PROFIL ====================
  // ==================== TAB 4: PROFIL ====================
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // ✅ Profile Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Hero(
                  tag: 'profileAvatarLarge',
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.amber.shade100,
                    backgroundImage: profilePhotoUrl != null
                        ? NetworkImage(profilePhotoUrl!)
                        : null,
                    child: profilePhotoUrl == null
                        ? Text(
                            userInitial,
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD97706),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAdmin ? 'Administrator' : 'Karyawan',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    userData?['email'] ?? '-',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ✅ Menu Profile
          _buildProfileMenuItem(
            icon: Icons.person,
            label: 'Edit Profil',
            onTap: () async {
              // ✅ PERBAIKAN: Gunakan Navigator.push untuk membuka halaman edit
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfilePage(
                    userData: userData,
                    isOwnProfile: true, // ✅ Tambahkan flag ini
                  ),
                ),
              );

              // ✅ Reload data jika berhasil update
              if (result == true && mounted) {
                _loadUserData();
              }
            },
          ),
          _buildProfileMenuItem(
            icon: Icons.notifications,
            label: 'Notifikasi',
            badge: unreadNotificationCount,
            onTap: () => Navigator.pushNamed(context, '/notifications'),
          ),
          _buildProfileMenuItem(
            icon: Icons.info,
            label: 'Tentang Aplikasi',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Sismalat',
                applicationVersion: '1.0.0',
                children: [
                  Text(
                    'Sistem Manajemen Alat Ukur\nDisperindag Kabupaten Karawang',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              );
            },
          ),
          _buildProfileMenuItem(
            icon: Icons.logout,
            label: 'Keluar',
            color: Colors.red,
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    int? badge,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: color ?? const Color(0xFFD97706)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: color ?? const Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (badge != null && badge > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== NOTIFICATION SUMMARY CARD ====================
  Widget _buildNotificationSummaryCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () async {
          await Navigator.pushNamed(context, '/notifications');
          _loadUnreadNotifications();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade50, Colors.orange.shade50],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade200, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications_active,
                  color: Colors.red.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Anda memiliki $unreadNotificationCount notifikasi baru',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap untuk melihat detail',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.red.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== SHIMMER ====================
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

  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    if (value is int) return value.toString();
    if (value is double) return value.toStringAsFixed(0);
    return value.toString();
  }
}

// ==================== ANIMATED NOTIFICATION BELL ====================
class _AnimatedNotificationBell extends StatefulWidget {
  final int unreadCount;
  final int previousCount;
  final VoidCallback onTap;

  const _AnimatedNotificationBell({
    required this.unreadCount,
    required this.previousCount,
    required this.onTap,
  });

  @override
  State<_AnimatedNotificationBell> createState() =>
      _AnimatedNotificationBellState();
}

class _AnimatedNotificationBellState extends State<_AnimatedNotificationBell>
    with TickerProviderStateMixin {
  late AnimationController _bellController;
  late Animation<double> _bellShakeAnimation;
  late AnimationController _badgePulseController;
  late Animation<double> _badgePulseAnimation;
  late AnimationController _badgeScaleController;
  late Animation<double> _badgeScaleAnimation;

  bool _isShaking = false;

  @override
  void initState() {
    super.initState();

    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bellShakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bellController, curve: Curves.easeInOut),
    );

    _badgePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _badgePulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _badgePulseController, curve: Curves.easeInOut),
    );

    _badgeScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _badgeScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _badgeScaleController, curve: Curves.elasticOut),
    );

    if (widget.unreadCount > 0) {
      _triggerInitialAnimation();
    }
  }

  @override
  void didUpdateWidget(_AnimatedNotificationBell oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.unreadCount != oldWidget.unreadCount) {
      if (widget.unreadCount > oldWidget.unreadCount) {
        _triggerBellShake();
      }

      if (widget.unreadCount > 0 && oldWidget.unreadCount == 0) {
        _badgeScaleController.forward(from: 0.0);
      } else if (widget.unreadCount == 0 && oldWidget.unreadCount > 0) {
        _badgeScaleController.reverse();
      }
    }
  }

  void _triggerInitialAnimation() {
    if (widget.unreadCount > 0) {
      _badgeScaleController.forward();
      _badgePulseController.repeat(reverse: true);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _triggerBellShake();
      });
    }
  }

  void _triggerBellShake() {
    if (_isShaking) return;
    _isShaking = true;

    _bellController.forward().then((_) {
      _bellController.reverse().then((_) {
        _isShaking = false;
      });
    });
  }

  @override
  void dispose() {
    _bellController.dispose();
    _badgePulseController.dispose();
    _badgeScaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _bellShakeAnimation,
          builder: (context, child) {
            final shakeValue = _bellShakeAnimation.value;
            final rotation = shakeValue <= 0.5
                ? shakeValue * 2 * 0.3
                : (1 - shakeValue) * 2 * 0.3;
            final direction = shakeValue <= 0.5 ? 1.0 : -1.0;

            return Transform.rotate(
              angle: rotation * direction,
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 24),
                onPressed: widget.onTap,
                tooltip: 'Notifikasi',
              ),
            );
          },
        ),

        if (widget.unreadCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _badgePulseAnimation,
                _badgeScaleAnimation,
              ]),
              builder: (context, child) {
                return Transform.scale(
                  scale:
                      _badgeScaleAnimation.value * _badgePulseAnimation.value,
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                    child: Text(
                      widget.unreadCount > 99 ? '99+' : '${widget.unreadCount}',
                      key: ValueKey<int>(widget.unreadCount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ==================== STAGGERED MENU ITEM ====================
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
