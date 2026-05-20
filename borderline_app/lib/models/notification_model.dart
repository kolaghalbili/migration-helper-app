class AppNotification {
  final int id;
  final String notifType;
  final String title;
  final String body;
  final bool isRead;
  final int? relatedRequest;
  final String createdAt;

  AppNotification({
    required this.id,
    required this.notifType,
    required this.title,
    required this.body,
    required this.isRead,
    this.relatedRequest,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id:             json['id'] ?? 0,
        notifType:      json['notif_type'] ?? '',
        title:          json['title'] ?? '',
        body:           json['body'] ?? '',
        isRead:         json['is_read'] ?? false,
        relatedRequest: json['related_request'],
        createdAt:      json['created_at'] ?? '',
      );

  static String iconFor(String notifType) {
    switch (notifType) {
      case 'new_request':    return '📋';
      case 'status_changed': return '🔄';
      case 'new_message':    return '💬';
      default:               return '🔔';
    }
  }
}
