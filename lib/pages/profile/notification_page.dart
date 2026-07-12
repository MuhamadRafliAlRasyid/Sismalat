import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  String? _error;
  String _activeFilter = 'all';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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
    _loadNotifications();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔄 [NotificationPage] Loading notifications...');

      // ✅ Panggil service
      final Map<String, dynamic> result = await NotificationService.getAll();

      print('📦 [NotificationPage] Result keys: ${result.keys.toList()}');
      print('📦 [NotificationPage] Success: ${result['success']}');

      // ✅ Cek success
      final bool isSuccess = result['success'] == true;

      if (isSuccess) {
        // ✅ Parse notifications dengan aman
        final dynamic rawNotifications = result['notifications'];
        final List<Map<String, dynamic>> notifications = [];

        if (rawNotifications is List) {
          for (var item in rawNotifications) {
            if (item is Map<String, dynamic>) {
              notifications.add(item);
            } else if (item is Map) {
              notifications.add(Map<String, dynamic>.from(item));
            }
          }
        }

        // ✅ Parse unread_count dengan aman
        final dynamic rawUnreadCount = result['unread_count'];
        final int unreadCount = (rawUnreadCount is int) ? rawUnreadCount : 0;

        print(
          '✅ [NotificationPage] Parsed: ${notifications.length} notifications, $unreadCount unread',
        );

        if (mounted) {
          setState(() {
            _notifications = notifications;
            _unreadCount = unreadCount;
            _isLoading = false;
            _error = null;
          });

          _fadeController.forward(from: 0.0);
        }
      } else {
        final String errorMessage =
            result['message']?.toString() ?? 'Gagal memuat notifikasi';
        print('❌ [NotificationPage] API Error: $errorMessage');

        if (mounted) {
          setState(() {
            _error = errorMessage;
            _isLoading = false;
            _notifications = [];
            _unreadCount = 0;
          });
        }
      }
    } catch (e, stackTrace) {
      print('❌ [NotificationPage] Error: $e');
      print('📚 [NotificationPage] Stack: $stackTrace');

      if (mounted) {
        setState(() {
          _error = 'Terjadi kesalahan: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(Map<String, dynamic> notif) async {
    final String? id = notif['id']?.toString();
    if (id == null) return;

    final bool success = await NotificationService.markAsRead(id);
    if (success && mounted) {
      setState(() {
        final int index = _notifications.indexWhere(
          (n) => n['id']?.toString() == id,
        );
        if (index != -1) {
          _notifications[index]['read'] = true;
          _notifications[index]['read_at'] = DateTime.now().toIso8601String();
          _unreadCount = _notifications.where((n) => n['read'] != true).length;
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final bool success = await NotificationService.markAllAsRead();
    if (success && mounted) {
      setState(() {
        _notifications = _notifications.map((n) {
          n['read'] = true;
          n['read_at'] = DateTime.now().toIso8601String();
          return n;
        }).toList();
        _unreadCount = 0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua notifikasi ditandai sudah dibaca'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(String id) async {
    final bool success = await NotificationService.delete(id);
    if (success && mounted) {
      setState(() {
        _notifications.removeWhere((n) => n['id']?.toString() == id);
        _unreadCount = _notifications.where((n) => n['read'] != true).length;
      });
    }
  }

  int get _urgentCount => _notifications
      .where((n) => n['read'] != true && n['priority'] == 'high')
      .length;

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_activeFilter == 'unread') {
      return _notifications.where((n) => n['read'] != true).toList();
    }
    if (_activeFilter == 'urgent') {
      return _notifications
          .where((n) => n['read'] != true && n['priority'] == 'high')
          .toList();
    }
    return _notifications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF9E7),
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        actions: [
          if (_unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Tandai semua sudah dibaca',
              onPressed: _markAllAsRead,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: _isLoading
                ? _buildShimmerList()
                : _error != null
                ? _buildError()
                : _filteredNotifications.isEmpty
                ? _buildEmptyState()
                : _buildNotificationList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Semua',
            count: _notifications.length,
            isActive: _activeFilter == 'all',
            onTap: () => setState(() => _activeFilter = 'all'),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: '🔴 Urgent',
            count: _urgentCount,
            isActive: _activeFilter == 'urgent',
            onTap: () => setState(() => _activeFilter = 'urgent'),
            color: Colors.red,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Belum',
            count: _unreadCount,
            isActive: _activeFilter == 'unread',
            onTap: () => setState(() => _activeFilter = 'unread'),
            color: const Color(0xFFD97706),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isActive,
    required VoidCallback onTap,
    Color? color,
  }) {
    final Color activeColor = color ?? const Color(0xFFD97706);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
            border: Border.all(
              color: isActive ? activeColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? activeColor : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '($count)',
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? activeColor : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _filteredNotifications.length,
        itemBuilder: (context, index) {
          final Map<String, dynamic> notif = _filteredNotifications[index];
          return _NotificationCard(
            notif: notif,
            onTap: () => _handleNotifTap(notif),
            onMarkRead: () => _markAsRead(notif),
            onDelete: () => _deleteNotification(notif['id']?.toString() ?? ''),
          );
        },
      ),
    );
  }

  void _handleNotifTap(Map<String, dynamic> notif) async {
    if (notif['read'] != true) {
      await _markAsRead(notif);
    }

    final String type = notif['type']?.toString() ?? '';
    final String actionUrl = notif['action_url']?.toString() ?? '';
    final String? alatHashid = notif['alat_hashid']?.toString();
    final String? pengambilanHashid = notif['hashid']?.toString();

    print('🔔 [Notification] Tap: type=$type, url=$actionUrl');

    if (!mounted) return;

    if (type == 'alat_kalibrasi' || type.contains('AlatExpired')) {
      if (alatHashid != null && alatHashid.isNotEmpty) {
        Navigator.pushNamed(
          context,
          '/kalibrasi/form',
          arguments: {'alatHashid': alatHashid},
        );
      } else {
        Navigator.pushNamed(context, '/kalibrasi/list');
      }
    } else if (type.contains('peminjaman_warning')) {
      if (pengambilanHashid != null && pengambilanHashid.isNotEmpty) {
        Navigator.pushNamed(
          context,
          '/pengembalian_alat/form',
          arguments: {'pengambilanHashid': pengambilanHashid},
        );
      } else {
        Navigator.pushNamed(context, '/pengembalian_alat/list');
      }
    } else {
      _navigateFromUrl(actionUrl);
    }
  }

  void _navigateFromUrl(String url) {
    if (url.isEmpty || url == '#') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifikasi tidak memiliki aksi'),
            backgroundColor: Colors.grey,
          ),
        );
      }
      return;
    }

    try {
      final Uri uri = Uri.parse(url);
      final String path = uri.path;

      if (path.contains('/kalibrasi')) {
        Navigator.pushNamed(context, '/kalibrasi/list');
      } else if (path.contains('/pengembalian')) {
        Navigator.pushNamed(context, '/pengembalian_alat/list');
      } else if (path.contains('/pengambilan')) {
        Navigator.pushNamed(context, '/pengambilan_alat/list');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Route tidak dikenal: $path'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [Navigate] Error: $e');
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _activeFilter == 'unread'
                ? 'Tidak ada notifikasi belum dibaca'
                : _activeFilter == 'urgent'
                ? 'Tidak ada notifikasi urgent'
                : 'Tidak ada notifikasi',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Notifikasi baru akan muncul di sini',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Gagal memuat notifikasi',
            style: const TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5,
      itemBuilder: (context, index) => _ShimmerNotifCard(),
    );
  }
}

// ==================== NOTIFICATION CARD ====================
class _NotificationCard extends StatefulWidget {
  final Map<String, dynamic> notif;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notif,
    required this.onTap,
    required this.onMarkRead,
    required this.onDelete,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  double _swipeOffset = 0;
  double _startX = 0;
  bool _isSwiping = false;

  void _onPanStart(DragStartDetails details) {
    _startX = details.localPosition.dx;
    _isSwiping = true;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isSwiping) return;
    final double dx = details.localPosition.dx - _startX;
    if (dx > 0) {
      setState(() {
        _swipeOffset = dx.clamp(0, 120);
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _isSwiping = false;
    if (_swipeOffset > 75) {
      widget.onDelete();
    } else {
      setState(() => _swipeOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> notif = widget.notif;
    final bool isRead = notif['read'] == true;
    final String priority = notif['priority']?.toString() ?? 'normal';
    final String color = notif['color']?.toString() ?? 'gray';
    final String icon = notif['icon']?.toString() ?? 'bell';
    final String title =
        notif['nama_alat']?.toString() ??
        notif['message']?.toString() ??
        'Notifikasi';
    final String message = notif['message']?.toString() ?? '';
    final dynamic sisaHari = notif['sisa_hari'];
    final dynamic persentase = notif['persentase_sisa'];
    final dynamic jatuhTempo = notif['jatuh_tempo'];
    final String actionLabel =
        notif['action_label']?.toString() ?? 'Lihat Detail';
    final String? createdAt = notif['created_at']?.toString();

    final bool isUrgent = !isRead && priority == 'high';
    final bool isWarning = !isRead && priority != 'high';

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(_swipeOffset, 0),
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUrgent
                        ? Colors.red.shade50
                        : isWarning
                        ? Colors.amber.shade50
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: isUrgent
                        ? Border.all(color: Colors.red.shade300)
                        : isWarning
                        ? Border.all(color: Colors.amber.shade300)
                        : Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getIconBgColor(color, isRead),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getIconData(icon),
                              color: _getIconColor(color, isRead),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title.length > 70
                                      ? '${title.substring(0, 70)}...'
                                      : title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isRead
                                        ? FontWeight.normal
                                        : FontWeight.w600,
                                    color: isRead
                                        ? Colors.grey.shade600
                                        : const Color(0xFF1E293B),
                                  ),
                                ),
                                if (message.isNotEmpty && message != title)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      message,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (!isRead)
                            GestureDetector(
                              onTap: widget.onMarkRead,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.blue.shade500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (sisaHari != null ||
                          persentase != null ||
                          jatuhTempo != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10, left: 52),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (sisaHari != null)
                                _buildInfoBadge(
                                  icon: Icons.access_time,
                                  text: '$sisaHari hari lagi',
                                  color: isUrgent ? Colors.red : Colors.orange,
                                ),
                              if (persentase != null)
                                _buildInfoBadge(
                                  icon: Icons.pie_chart,
                                  text: '$persentase%',
                                  color: Colors.blue,
                                ),
                              if (jatuhTempo != null)
                                _buildInfoBadge(
                                  icon: Icons.calendar_today,
                                  text: jatuhTempo.toString(),
                                  color: Colors.purple,
                                ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10, left: 52),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: widget.onTap,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isUrgent
                                          ? [
                                              Colors.red.shade500,
                                              Colors.red.shade600,
                                            ]
                                          : [
                                              const Color(0xFFF59E0B),
                                              const Color(0xFFEA580C),
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (isUrgent
                                                    ? Colors.red
                                                    : Colors.amber)
                                                .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        actionLabel,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isRead)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Baru',
                                      style: TextStyle(
                                        color: Color(0xFFD97706),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatTime(createdAt),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getIconBgColor(String color, bool isRead) {
    if (isRead) return Colors.grey.shade100;
    switch (color) {
      case 'red':
        return Colors.red.shade100;
      case 'orange':
        return Colors.orange.shade100;
      case 'green':
        return Colors.green.shade100;
      default:
        return Colors.amber.shade100;
    }
  }

  Color _getIconColor(String color, bool isRead) {
    if (isRead) return Colors.grey.shade500;
    switch (color) {
      case 'red':
        return Colors.red.shade500;
      case 'orange':
        return Colors.orange.shade500;
      case 'green':
        return Colors.green.shade500;
      default:
        return const Color(0xFFD97706);
    }
  }

  IconData _getIconData(String icon) {
    switch (icon) {
      case 'bell':
        return Icons.notifications;
      case 'exclamation-triangle':
        return Icons.warning;
      case 'exclamation-circle':
        return Icons.error;
      case 'check-circle':
        return Icons.check_circle;
      case 'calendar':
        return Icons.calendar_today;
      case 'tools':
        return Icons.build;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final DateTime date = DateTime.parse(isoString);
      final Duration diff = DateTime.now().difference(date);

      if (diff.inSeconds < 10) return 'baru saja';
      if (diff.inMinutes < 1) return '${diff.inSeconds} detik lalu';
      if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
      if (diff.inDays < 1) return '${diff.inHours} jam lalu';
      if (diff.inDays == 1) return 'kemarin';
      if (diff.inDays < 7) return '${diff.inDays} hari lalu';

      return '${date.day} ${_monthName(date.month)}';
    } catch (_) {
      return '';
    }
  }

  String _monthName(int month) {
    const List<String> months = [
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
    return months[month - 1];
  }
}

// ==================== SHIMMER NOTIFICATION CARD ====================
class _ShimmerNotifCard extends StatefulWidget {
  @override
  State<_ShimmerNotifCard> createState() => _ShimmerNotifCardState();
}

class _ShimmerNotifCardState extends State<_ShimmerNotifCard>
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
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _animation.value,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      color: _animation.value,
                    ),
                    const SizedBox(height: 6),
                    Container(height: 10, width: 120, color: _animation.value),
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
