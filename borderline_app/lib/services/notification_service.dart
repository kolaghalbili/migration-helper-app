import 'package:dio/dio.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../models/notification_model.dart';

class NotificationService {
  final Dio _dio = Dio();
  final String _base = 'http://127.0.0.1:8000/api';

  String? get _token => html.window.localStorage['access'];
  Options get _auth  => Options(headers: {'Authorization': 'Bearer $_token'});

  Future<List<AppNotification>> getNotifications() async {
    try {
      final res = await _dio.get('$_base/notifications/', options: _auth);
      return (res.data as List)
          .map((j) => AppNotification.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final res = await _dio.get('$_base/notifications/unread-count/', options: _auth);
      return (res.data['count'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _dio.patch('$_base/notifications/$id/read/', options: _auth);
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _dio.post('$_base/notifications/read-all/', options: _auth);
    } catch (_) {}
  }
}
