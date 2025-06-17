import 'notification_dto.dart';

abstract class NotificationRepository {
  Future<List<NotificationDto>> fetchNotifications();
  Future<void> markAsRead(int id);
}
