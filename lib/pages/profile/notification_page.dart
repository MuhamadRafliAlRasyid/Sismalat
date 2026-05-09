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
            child: const Text('Ya, Tandai Semua'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await NotificationService.markAllAsRead();

    if (result['status'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua notifikasi telah ditandai sebagai dibaca'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadNotifications();
    }
  }

  // Tetap gunakan sparepartHashid seperti yang Anda inginkan
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
        arguments: {'sparepartHashid': sparepartHashid}, // ← sparepartHashid
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(notif['message'] ?? 'Notifikasi')),
        );
      }
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: notifications.isEmpty
                  ? const Center(child: Text('Belum ada notifikasi'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notif = notifications[index];
                        final data = notif['data'] ?? {};
                        final isRead = notif['read_at'] != null;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _handleNotificationTap(notif),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 5,
                                    backgroundColor: Colors.red,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                data['nama_part'] ??
                                                    'Notifikasi',
                                                style: TextStyle(
                                                  fontWeight: isRead
                                                      ? FontWeight.w500
                                                      : FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '#${data['sparepart_id'] ?? 'N/A'}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Stok: ${data['jumlah_baru'] ?? 0} ≤ Titik: ${data['titik_pesanan'] ?? 0}',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Row(
                                          children: [
                                            Icon(
                                              Icons.shopping_cart,
                                              size: 16,
                                              color: Colors.blue,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Ajukan Pembelian',
                                              style: TextStyle(
                                                color: Colors.blue,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatRelativeTime(
                                            notif['created_at'],
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
      bottomNavigationBar: unreadCount > 0
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _markAllAsRead,
                icon: const Icon(Icons.done_all),
                label: const Text('Tandai semua sudah dibaca'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            )
          : null,
    );
  }
}
