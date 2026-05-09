import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../config/api.dart';

import 'auth/login_page.dart';
import 'profile/profile_page.dart';
import 'profile/user_list_page.dart';

// Import halaman yang dibutuhkan karyawan
import 'barang/barang_list_page.dart';
import 'purchase/purchase_request_list_page.dart';
import 'pengambilan/pengambilan_list_page.dart';
import 'pengembalian/pengembalian_list_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  String userName = "User";
  String userInitial = "U";
  String? profilePhotoUrl;

  int unreadNotificationCount = 0;

  bool get isAdmin => userData?['role'] == 'admin';

  // Menu untuk Admin
  final List<Map<String, dynamic>> _adminMenu = [
    {
      'icon': Icons.inventory_2_outlined,
      'label': 'Daftar Barang',
      'route': '/barang/list',
    },
    {
      'icon': Icons.shopping_cart_outlined,
      'label': 'Purchase Request',
      'route': '/purchase/list',
    },
    {
      'icon': Icons.local_shipping_outlined,
      'label': 'Pengambilan Barang',
      'route': '/pengambilan/list',
    },
    {
      'icon': Icons.assignment_return_outlined,
      'label': 'Pengembalian',
      'route': '/pengembalian/list',
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

  // Menu untuk Karyawan
  final List<Map<String, dynamic>> _karyawanMenu = [
    {
      'icon': Icons.inventory_2_outlined,
      'label': 'Daftar Barang',
      'route': '/barang/list',
    },
    {
      'icon': Icons.shopping_cart_outlined,
      'label': 'Purchase Request',
      'route': '/purchase/list',
    },
    {
      'icon': Icons.local_shipping_outlined,
      'label': 'Pengambilan Saya',
      'route': '/pengambilan/list',
    }, // Bisa difilter nanti
    {
      'icon': Icons.assignment_return_outlined,
      'label': 'Pengembalian Sparepart',
      'route': '/pengembalian/list',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUnreadNotifications();
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
        if (photoPath != null && photoPath.toString().isNotEmpty) {
          profilePhotoUrl = '${Api.baseUrl}/images/profile/$photoPath';
        }
      });
    }
  }

  Future<void> _loadUnreadNotifications() async {
    final count = await NotificationService.getUnreadCount();
    if (mounted) {
      setState(() => unreadNotificationCount = count);
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _onScanPressed() {
    Navigator.pushNamed(context, '/qr-scanner');
  }

  void _onMenuTapped(int index) {
    final menuList = isAdmin ? _adminMenu : _karyawanMenu;
    final route = menuList[index]['route'] as String?;

    if (route != null) {
      Navigator.pushNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final menuList = isAdmin ? _adminMenu : _karyawanMenu;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Inventarisasi'),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false, // Hapus tombol back
        actions: [
          // Notifikasi
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
              ),
              if (unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
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
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),

          // Popup Profil
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            icon: CircleAvatar(
              backgroundColor: colorScheme.primary,
              radius: 18,
              backgroundImage: profilePhotoUrl != null
                  ? NetworkImage(profilePhotoUrl!)
                  : null,
              child: profilePhotoUrl == null
                  ? Text(
                      userInitial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat datang, $userName',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kelola inventaris dengan mudah',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.05,
                ),
                itemCount: menuList.length,
                itemBuilder: (context, index) {
                  final item = menuList[index];
                  return _buildMenuCard(item, index, colorScheme, theme);
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.large(
        onPressed: _onScanPressed,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner_rounded, size: 36),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 8,
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, 0),
            _buildNavItem(Icons.list_alt_outlined, 1),
            const SizedBox(width: 48),
            _buildNavItem(Icons.inventory_outlined, 2),
            _buildNavItem(Icons.person_outline, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    Map<String, dynamic> item,
    int index,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Card(
      elevation: 4,
      shadowColor: colorScheme.shadow.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _onMenuTapped(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item['icon'], size: 42, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              item['label'],
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconButton _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return IconButton(
      icon: Icon(icon),
      color: isSelected ? Theme.of(context).colorScheme.primary : null,
      onPressed: () => setState(() => _selectedIndex = index),
    );
  }
}
