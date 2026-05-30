import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../api/api_client.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> loadNotifications(int userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _apiClient.get('/api/notifications/user/$userId');
      _notifications = (res['data'] as List)
          .map((e) => NotificationModel.fromJson(e))
          .toList();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(int notificationId) async {
    try {
      await _apiClient.post('/api/notifications/$notificationId/read', {});
      final idx = _notifications.indexWhere((n) => n.id == notificationId);
      if (idx != -1 && !_notifications[idx].isRead) {
        _notifications[idx] = NotificationModel(
          id: _notifications[idx].id,
          userId: _notifications[idx].userId,
          title: _notifications[idx].title,
          body: _notifications[idx].body,
          type: _notifications[idx].type,
          refId: _notifications[idx].refId,
          isRead: true,
          createdAt: _notifications[idx].createdAt,
        );
        _unreadCount = (_unreadCount - 1).clamp(0, 9999);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllRead(int userId) async {
    try {
      await _apiClient.post('/api/notifications/user/$userId/read-all', {});
      _notifications = _notifications
          .map((n) => NotificationModel(
                id: n.id,
                userId: n.userId,
                title: n.title,
                body: n.body,
                type: n.type,
                refId: n.refId,
                isRead: true,
                createdAt: n.createdAt,
              ))
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }
}
