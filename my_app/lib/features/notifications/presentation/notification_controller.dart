import 'package:flutter/foundation.dart';
import '../data/api_notification_repository.dart';
import '../domain/notification_dto.dart';
import '../domain/notification_repository.dart';

enum NotificationLoadState { initial, loading, success, empty, error, unauthorized }

class NotificationController extends ChangeNotifier {
  final NotificationRepository _repository;

  List<NotificationDto> _notifications = [];
  NotificationLoadState _state = NotificationLoadState.initial;
  String? error;

  NotificationController({NotificationRepository? repository})
      : _repository = repository ?? ApiNotificationRepository();

  List<NotificationDto> get notifications => List.unmodifiable(_notifications);
  NotificationLoadState get state => _state;
  
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> load() async {
    _state = NotificationLoadState.loading;
    error = null;
    notifyListeners();

    try {
      _notifications = await _repository.fetchNotifications();
      _state = _notifications.isEmpty ? NotificationLoadState.empty : NotificationLoadState.success;
    } on NotificationUnauthorizedException {
      _state = NotificationLoadState.unauthorized;
    } catch (e) {
      error = e.toString();
      _state = NotificationLoadState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _repository.markAsRead(id);
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1) {
        final list = List<NotificationDto>.from(_notifications);
        final old = list[idx];
        list[idx] = NotificationDto(
          id: old.id,
          title: old.title,
          body: old.body,
          isRead: true,
          createdAt: old.createdAt,
        );
        _notifications = list;
        notifyListeners();
      }
    } catch (_) {
      // Ignore errors for markAsRead in MVP
    }
  }
}
