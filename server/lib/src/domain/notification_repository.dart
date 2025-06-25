abstract class NotificationRepository {
  Future<List<Map<String, dynamic>>> fetchNotifications(int userId);
  Future<int> markAsRead(int notificationId, int userId);
  Future<int> createNotification(int userId, String title, String body);
}
