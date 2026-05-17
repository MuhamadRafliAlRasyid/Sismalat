// lib/pages/notification/notification_page.dart
import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<dynamic> notifications = [];
  bool isLoading = true;
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => isLoading = true);
    final result = await NotificationService.getAll();
    if (result['status'] == true) {
      setState(() {
        notifications = result['data'] ?? [];
        unreadCount = result['unread_count'] ?? 0;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal memuat notifikasi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _markAllAsRead() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tandai Semua Dibaca?'),
        content: const Text(
          'Semua notifikasi akan ditandai sebagai sudah dibaca.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Ya, Tandai Semua'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final result = await NotificationService.markAllAsRead();
    if (result['status'] == true) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua notifikasi telah ditandai sebagai dibaca'),
            backgroundColor: Colors.green,
          ),
        );
      _loadNotifications();
    }
  }

  void _handleNotificationTap(dynamic notif) {
    final data = notif['data'] ?? {};
    final sparepartHashid =
        data['sparepart_hashid']?.toString() ??
        data['hashid']?.toString() ??
        data['sparepart_id']?.toString();
    if (sparepartHashid != null && sparepartHashid.isNotEmpty) {
      Navigator.pushNamed(
        context,
        '/purchase/form',
        arguments: {'sparepartHashid': sparepartHashid},
      );
    } else {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(notif['message'] ?? 'Notifikasi')),
        );
    }
  }

  String _formatRelativeTime(String? dateStr) {
    if (dateStr == null) return 'Baru saja';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
      if (diff.inDays < 1) return '${diff.inHours} jam lalu';
      return '${diff.inDays} hari lalu';
    } catch (_) {
      return dateStr.substring(0, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF9E7),
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Tandai semua dibaca',
              onPressed: _markAllAsRead,
            ),
        ],
      ),
      body: isLoading
          ? _buildShimmerList()
          : RefreshIndicator(
              color: const Color(0xFFD97706),
              onRefresh: _loadNotifications,
              child: notifications.isEmpty
                  ? ListView(children: [_buildEmpty()])
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        return _StaggeredNotificationCard(
                          notif: notifications[index],
                          index: index,
                          onTap: () =>
                              _handleNotificationTap(notifications[index]),
                          formatTime: _formatRelativeTime,
                        );
                      },
                    ),
            ),
      bottomNavigationBar: unreadCount > 0
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _markAllAsRead,
                icon: const Icon(Icons.done_all),
                label: Text('Tandai semua ($unreadCount) sudah dibaca'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmpty() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none,
              size: 72,
              color: Colors.amber.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada notifikasi',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ShimmerCard(),
      ),
    );
  }
}

class _StaggeredNotificationCard extends StatefulWidget {
  final dynamic notif;
  final int index;
  final VoidCallback onTap;
  final String Function(String?) formatTime;
  const _StaggeredNotificationCard({
    required this.notif,
    required this.index,
    required this.onTap,
    required this.formatTime,
  });

  @override
  State<_StaggeredNotificationCard> createState() =>
      _StaggeredNotificationCardState();
}

class _StaggeredNotificationCardState extends State<_StaggeredNotificationCard>
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
    final notif = widget.notif;
    final data = notif['data'] ?? {};
    final isRead = notif['read_at'] != null;
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) => SlideTransition(
        position: _slideAnimation,
        child: Transform.scale(scale: _scaleAnimation.value, child: child),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: isRead ? 0 : 2,
        color: isRead ? Colors.white : const Color(0xFFFFFBF0),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isRead)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 6, right: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD97706),
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(width: 22),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['nama_part'] ?? data['title'] ?? 'Notifikasi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isRead
                              ? FontWeight.w500
                              : FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notif['message'] ?? data['body'] ?? '',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.shopping_cart,
                            size: 16,
                            color: const Color(0xFFD97706).withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ajukan pembelian',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFFD97706).withOpacity(0.8),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            widget.formatTime(notif['created_at']),
                            style: TextStyle(
                              fontSize: 11,
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
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
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
      builder: (context, child) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: _animation.value,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      color: _animation.value,
                    ),
                    const SizedBox(height: 8),
                    Container(height: 10, width: 200, color: _animation.value),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
