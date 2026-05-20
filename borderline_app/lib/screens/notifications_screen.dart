import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  List<AppNotification> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final items = await _service.getNotifications();
    if (!mounted) return;
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  Future<void> _markRead(AppNotification notif) async {
    if (notif.isRead) return;
    await _service.markRead(notif.id);
    setState(() {
      final idx = _items.indexWhere((n) => n.id == notif.id);
      if (idx != -1) {
        _items[idx] = AppNotification(
          id:             notif.id,
          notifType:      notif.notifType,
          title:          notif.title,
          body:           notif.body,
          isRead:         true,
          relatedRequest: notif.relatedRequest,
          createdAt:      notif.createdAt,
        );
      }
    });
  }

  Future<void> _markAllRead() async {
    await _service.markAllRead();
    setState(() {
      _items = _items.map((n) => AppNotification(
        id:             n.id,
        notifType:      n.notifType,
        title:          n.title,
        body:           n.body,
        isRead:         true,
        relatedRequest: n.relatedRequest,
        createdAt:      n.createdAt,
      )).toList();
    });
  }

  String _timeAgo(String iso) {
    try {
      final dt   = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inDays >= 1)    return '${diff.inDays}d ago';
      if (diff.inHours >= 1)   return '${diff.inHours}h ago';
      if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
      return 'just now';
    } catch (_) {
      return '';
    }
  }

  int get _unreadCount => _items.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Text('Notifications',
                style: TextStyle(fontWeight: FontWeight.bold)),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8944A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      itemBuilder: (_, i) => _buildTile(_items[i]),
                    ),
            ),
    );
  }

  Widget _buildTile(AppNotification notif) {
    final unread = !notif.isRead;
    return InkWell(
      onTap: () => _markRead(notif),
      child: Container(
        color: unread
            ? const Color(0xFF1A3A5C).withValues(alpha: 0.04)
            : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _iconBg(notif.notifType),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  AppNotification.iconFor(notif.notifType),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight: unread
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 14,
                            color: const Color(0xFF1A3A5C),
                          ),
                        ),
                      ),
                      if (unread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8944A),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (notif.body.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      notif.body,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF7A8B9A)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(notif.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFFADB5BD)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _iconBg(String type) {
    switch (type) {
      case 'new_request':    return const Color(0xFFE8944A).withValues(alpha: 0.12);
      case 'status_changed': return const Color(0xFF1A3A5C).withValues(alpha: 0.08);
      case 'new_message':    return const Color(0xFF2E8B8B).withValues(alpha: 0.12);
      default:               return const Color(0xFFDCE5ED);
    }
  }

  Widget _buildEmptyState() {
    return ListView(
      children: const [
        SizedBox(
          height: 360,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🔔', style: TextStyle(fontSize: 52)),
              SizedBox(height: 16),
              Text(
                'No notifications yet',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A5C),
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  'You\'ll be notified about new requests, status changes, and messages.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF7A8B9A), fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
