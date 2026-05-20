import 'package:flutter/material.dart';
import '../models/helper_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'request_intake_screen.dart';

class ReceivedRequestsScreen extends StatefulWidget {
  const ReceivedRequestsScreen({super.key});

  @override
  State<ReceivedRequestsScreen> createState() =>
      _ReceivedRequestsScreenState();
}

class _ReceivedRequestsScreenState extends State<ReceivedRequestsScreen> {
  final _authService = AuthService();
  List<HelpRequest> _requests = [];
  bool _isLoading = true;
  String _filter = 'all';

  static const _filterOptions = [
    ('all',      'All'),
    ('pending',  'New'),
    ('accepted', 'Active'),
    ('done',     'Done'),
    ('declined', 'Declined'),
  ];

  static const _categoryIcons = {
    'Banking':           '🏦',
    'Housing':           '🏠',
    'SIM Card':          '📱',
    'Legal & Documents': '📄',
    'Healthcare':        '🏥',
    'Language Support':  '💬',
    'Job Search':        '💼',
    'General Guidance':  '🧭',
  };

  static const _packageLabels = {
    'starter':    '2hr Starter',
    'half_day':   'Half Day',
    'first_week': 'First Week',
    'custom':     'Custom',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final raw = await _authService.getMyRequests();
    if (!mounted) return;
    setState(() {
      _requests = raw
          .map((r) => HelpRequest.fromJson(r as Map<String, dynamic>))
          .toList();
      _isLoading = false;
    });
  }

  List<HelpRequest> get _filtered {
    if (_filter == 'all') return _requests;
    return _requests.where((r) => r.status == _filter).toList();
  }

  Future<void> _markDone(HelpRequest req) async {
    final ok = await _authService.updateRequestStatus(req.id, 'done');
    if (!mounted) return;
    if (ok) {
      _load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session marked as done!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _openChat(HelpRequest req) async {
    final me = await _authService.getMe();
    final conv =
        await ChatService().getOrCreateConversation(req.newcomer);
    if (!mounted || conv == null || me == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conv['id'],
          helperName: req.newcomerName,
          currentUserId: me['id'],
        ),
      ),
    );
  }

  Future<void> _openIntake(HelpRequest req) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => RequestIntakeScreen(request: req),
      ),
    );
    if (result == 'accepted' || result == 'declined') {
      _load();
    }
  }

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inDays >= 1) return '${diff.inDays}d ago';
      if (diff.inHours >= 1) return '${diff.inHours}h ago';
      if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
      return 'just now';
    } catch (_) {
      return '';
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount =
        _requests.where((r) => r.status == 'pending').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Text('Received Requests',
                style: TextStyle(fontWeight: FontWeight.bold)),
            if (pendingCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8944A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$pendingCount',
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) =>
                                _buildCard(_filtered[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filterOptions.length,
        itemBuilder: (_, i) {
          final (value, label) = _filterOptions[i];
          final apiStatus = value == 'all' ? 'all' : value;
          final count = apiStatus == 'all'
              ? _requests.length
              : _requests.where((r) => r.status == apiStatus).length;
          final selected = _filter == value;
          return GestureDetector(
            onTap: () => setState(() => _filter = value),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF1A3A5C)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF1A3A5C)
                      : const Color(0xFFDCE5ED),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : const Color(0xFF1A3A5C),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.25)
                            : const Color(0xFFE8944A)
                                .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: selected
                              ? Colors.white
                              : const Color(0xFFE8944A),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(HelpRequest req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          const Color(0xFFE8944A).withValues(alpha: 0.18),
                      child: Text(
                        _initials(req.newcomerName),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE8944A),
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
                                  req.newcomerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF1A3A5C),
                                  ),
                                ),
                              ),
                              _statusBadge(req.status),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                _categoryIcons[req.category] ?? '🤝',
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                req.category,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A3A5C),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (req.subTopics.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: req.subTopics.take(3).map((t) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8944A)
                              .withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(t,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFE8944A))),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (req.package.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A3A5C)
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _packageLabels[req.package] ?? req.package,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF1A3A5C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      _timeAgo(req.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF7A8B9A)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (req.status == 'pending' || req.status == 'accepted')
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                border:
                    Border(top: BorderSide(color: Color(0xFFF0F0F0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openChat(req),
                      icon: const Icon(Icons.chat_bubble_outline,
                          size: 16),
                      label: const Text('Chat'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A3A5C),
                        side: const BorderSide(
                            color: Color(0xFF1A3A5C)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (req.status == 'pending') ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _openIntake(req),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE8944A),
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                          elevation: 0,
                        ),
                        child: const Text('Review →'),
                      ),
                    ),
                  ],
                  if (req.status == 'accepted') ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _markDone(req),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                          elevation: 0,
                        ),
                        child: const Text('Mark Done'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    const bg = {
      'pending':   Color(0xFFFFF3CD),
      'accepted':  Color(0xFFD1FAE5),
      'declined':  Color(0xFFFFE4E4),
      'done':      Color(0xFFE0F2FE),
      'cancelled': Color(0xFFF3F4F6),
    };
    const fg = {
      'pending':   Color(0xFF856404),
      'accepted':  Color(0xFF166534),
      'declined':  Color(0xFFB91C1C),
      'done':      Color(0xFF1D4ED8),
      'cancelled': Color(0xFF6B7280),
    };
    const labels = {
      'pending':   'New',
      'accepted':  'Active',
      'declined':  'Declined',
      'done':      'Done',
      'cancelled': 'Cancelled',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg[status] ?? const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        labels[status] ?? status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg[status] ?? const Color(0xFF856404),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final messages = {
      'all':      ('📬', 'No requests yet', 'Requests from newcomers will appear here once they find your profile.'),
      'pending':  ('⏳', 'No new requests', 'New incoming requests will appear here.'),
      'accepted': ('🤝', 'No active sessions', 'Accepted requests will appear here.'),
      'done':     ('✅', 'No completed sessions', 'Sessions you mark as done will appear here.'),
      'declined': ('❌', 'No declined requests', ''),
    };
    final (emoji, title, sub) =
        messages[_filter] ?? messages['all']!;
    return ListView(
      children: [
        SizedBox(
          height: 320,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A5C),
                ),
              ),
              if (sub.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    sub,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFF7A8B9A), fontSize: 14),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
