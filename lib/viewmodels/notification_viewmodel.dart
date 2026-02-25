import 'package:flutter/material.dart';
import '../core/network/api_service.dart';

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String category;
  final String type;
  final String? link;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
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
      category: json['category'] ?? 'SYSTEM',
      type: json['type'] ?? 'INFO',
      link: json['link'],
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  NotificationModel copyWith({
    bool? isRead,
  }) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      category: category,
      type: type,
      link: link,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

class NotificationViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;
  List<NotificationModel> get proposalNotifications =>
      _notifications.where((n) => n.category == 'PROPOSAL').toList();
  List<NotificationModel> get internalNotifications =>
      _notifications.where((n) => n.category == 'INTERNAL').toList();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _muteInternalMessages = false;
  bool get muteInternalMessages => _muteInternalMessages;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  int get unreadCountForBar => _notifications
      .where(
        (n) =>
            !n.isRead &&
            !(_muteInternalMessages && n.category == 'INTERNAL'),
      )
      .length;

  Future<void> refreshNotificationsState() async {
    _setLoading(true);
    try {
      await fetchPreferences(shouldNotify: false);
      await fetchNotifications(shouldNotify: false);
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> fetchNotifications({bool shouldNotify = true}) async {
    try {
      final response = await _apiService.getNotifications();
      if (response.statusCode == 200) {
        final List data = response.data;
        _notifications =
            data.map((e) => NotificationModel.fromJson(e)).toList();
        if (shouldNotify) {
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  Future<void> fetchPreferences({bool shouldNotify = true}) async {
    try {
      final response = await _apiService.getNotificationPreferences();
      if (response.statusCode == 200 && response.data is Map) {
        final map = Map<String, dynamic>.from(response.data as Map);
        _muteInternalMessages = map['mute_internal_messages'] ?? false;
        if (shouldNotify) {
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching notification preferences: $e');
    }
  }

  Future<bool> setMuteInternalMessages(bool value) async {
    try {
      final response = await _apiService.updateNotificationPreferences({
        'mute_internal_messages': value,
      });
      if (response.statusCode == 200) {
        _muteInternalMessages = value;
        await fetchNotifications(shouldNotify: false);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating notification preferences: $e');
      return false;
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      final response = await _apiService.markNotificationRead(id);
      if (response.statusCode == 200) {
        final index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
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
        _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
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
