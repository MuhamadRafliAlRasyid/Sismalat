import 'api_service.dart';

class NotificationService {
  // ==================== GET ALL NOTIFICATIONS ====================
  static Future<Map<String, dynamic>> getAll() async {
    return await ApiService.get('notifications');
  }

  // ==================== MARK ALL AS READ ====================
  static Future<Map<String, dynamic>> markAllAsRead() async {
    return await ApiService.post('notifications/mark-all-read', {});
  }

  // ==================== MARK SINGLE NOTIFICATION AS READ ====================
  // Jika backend mendukung (opsional)
  static Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    return await ApiService.post('notifications/$notificationId/read', {});
  }

  // ==================== GET UNREAD COUNT ONLY ====================
  static Future<int> getUnreadCount() async {
    final result = await getAll();
    if (result['status'] == true) {
      return result['unread_count'] ?? 0;
    }
    return 0;
  }
}
