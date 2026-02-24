import 'package:flutter/material.dart';
import '../core/network/api_service.dart';

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String type;
  final String? link;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.link,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'INFO',
      link: json['link'],
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

class NotificationViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications() async {
    _setLoading(true);
    try {
      final response = await _apiService.getNotifications();
      if (response.statusCode == 200) {
        final List data = response.data;
        _notifications =
            data.map((e) => NotificationModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      final response = await _apiService.markNotificationRead(id);
      if (response.statusCode == 200) {
        final index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          _notifications[index] = NotificationModel(
            id: _notifications[index].id,
            title: _notifications[index].title,
            message: _notifications[index].message,
            type: _notifications[index].type,
            link: _notifications[index].link,
            isRead: true,
            createdAt: _notifications[index].createdAt,
          );
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final response = await _apiService.markAllAllRead();
      if (response.statusCode == 200) {
        _notifications = _notifications.map((n) {
          return NotificationModel(
            id: n.id,
            title: n.title,
            message: n.message,
            type: n.type,
            link: n.link,
            isRead: true,
            createdAt: n.createdAt,
          );
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<bool> sendBroadcast(
      {required String title,
      required String message,
      String type = 'INFO'}) async {
    _setLoading(true);
    try {
      final response = await _apiService.broadcastNotification({
        'title': title,
        'message': message,
        'type': type,
      });
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Error sending broadcast: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
