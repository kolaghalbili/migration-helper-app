import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../models/helper_model.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'inbox_screen.dart';
import 'chat_screen.dart';

class HelperDashboardScreen extends StatefulWidget {
  const HelperDashboardScreen({super.key});

  @override
  State<HelperDashboardScreen> createState() => _HelperDashboardScreenState();
}

class _HelperDashboardScreenState extends State<HelperDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  late TabController _tabController;

  Map<String, dynamic>? _me;
  List<HelpRequest> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _authService.getMe(),
      _authService.getMyRequests(),
    ]);
    if (!mounted) return;
    setState(() {
      _me = results[0] as Map<String, dynamic>?;
      _requests = (results[1] as List<dynamic>)
          .map((r) => HelpRequest.fromJson(r as Map<String, dynamic>))
          .toList();
      _isLoading = false;
    });
  }

  List<HelpRequest> get _pending =>
      _requests.where((r) => r.status == 'pending').toList();
  List<HelpRequest> get _accepted =>
      _requests.where((r) => r.status == 'accepted').toList();
  List<HelpRequest> get _done =>
      _requests.where((r) => r.status == 'done').toList();

  Future<void> _updateStatus(HelpRequest req, String newStatus) async {
    final ok = await _authService.updateRequestStatus(req.id, newStatus);
    if (ok && mounted) {
      _load();
    }
  }

  Future<void> _openChat(int newcomerId, String newcomerName) async {
    final me = _me;
    if (me == null) return;
    final conv = await ChatService().getOrCreateConversation(newcomerId);
    if (!mounted || conv == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conv['id'],
          helperName: newcomerName,
          currentUserId: me['id'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        title: const Text('My Dashboard',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.inbox, color: Colors.white),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const InboxScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.manage_accounts_outlined, color: Colors.white),
            tooltip: 'Edit Profile',
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
              if (updated == true) _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await _authService.logout();
              if (context.mounted) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE8944A),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'New (${_pending.length})'),
            Tab(text: 'Active (${_accepted.length})'),
            Tab(text: 'Done (${_done.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: Column(
                children: [
                  _buildStatsBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRequestList(_pending, showActions: true),
                        _buildRequestList(_accepted, showDone: true),
                        _buildRequestList(_done),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsBar() {
    final ratingAvg = _me?['rating_avg'] ?? 0.0;
    final totalReviews = _me?['total_reviews'] ?? 0;
    final totalSessions = _me?['total_sessions'] ?? 0;
    final firstName = _me?['first_name'] ?? 'Helper';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back, $firstName!',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3A5C))),
                    const SizedBox(height: 2),
                    Text(
                      _me?['city'] != null && (_me!['city'] as String).isNotEmpty
                          ? _me!['city']
                          : 'Local Helper',
                      style: const TextStyle(color: Color(0xFF7A8B9A), fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (_me?['is_available'] == true)
                      ? Colors.green.withValues(alpha: 0.12)
                      : Colors.grey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  (_me?['is_available'] == true) ? 'Available' : 'Busy',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: (_me?['is_available'] == true)
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statChip(Icons.star, Colors.amber,
                  double.tryParse(ratingAvg.toString())?.toStringAsFixed(1) ?? '0.0',
                  'Rating'),
              const SizedBox(width: 10),
              _statChip(Icons.rate_review_outlined, const Color(0xFF1A3A5C),
                  totalReviews.toString(), 'Reviews'),
              const SizedBox(width: 10),
              _statChip(Icons.handshake_outlined, const Color(0xFFE8944A),
                  totalSessions.toString(), 'Sessions'),
              const SizedBox(width: 10),
              _statChip(Icons.pending_actions_outlined, Colors.blue,
                  _pending.length.toString(), 'Pending'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, Color color, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: Color(0xFF7A8B9A))),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final images = _me?['profile_images'] as List?;
    String? url;
    if (images != null && images.isNotEmpty) {
      final primary = images.firstWhere(
          (i) => i['is_primary'] == true,
          orElse: () => images.first);
      url = primary['image_url'] as String?;
    }
    if (url != null) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorWidget: (_, url, err) => _avatarFallback(),
        ),
      );
    }
    return _avatarFallback();
  }

  Widget _avatarFallback() {
    final name = _me?['first_name'] ?? '?';
    return CircleAvatar(
      radius: 25,
      backgroundColor: const Color(0xFFE8944A).withValues(alpha: 0.2),
      child: Text(
        name.isNotEmpty ? (name as String)[0].toUpperCase() : '?',
        style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFE8944A)),
      ),
    );
  }

  Widget _buildRequestList(List<HelpRequest> list,
      {bool showActions = false, bool showDone = false}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              showActions
                  ? Icons.inbox_outlined
                  : showDone
                      ? Icons.event_available_outlined
                      : Icons.check_circle_outline,
              size: 56,
              color: const Color(0xFFDCE5ED),
            ),
            const SizedBox(height: 12),
            Text(
              showActions
                  ? 'No new requests'
                  : showDone
                      ? 'No active sessions'
                      : 'No completed sessions yet',
              style: const TextStyle(color: Color(0xFF7A8B9A)),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) =>
          _buildRequestCard(list[i], showActions: showActions, showDone: showDone),
    );
  }

  Widget _buildRequestCard(HelpRequest req,
      {bool showActions = false, bool showDone = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8944A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(_categoryIcon(req.category),
                        style: const TextStyle(fontSize: 20)),
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
                            child: Text(req.newcomerName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A3A5C))),
                          ),
                          _statusBadge(req.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(req.category,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A3A5C),
                              fontSize: 13)),
                      if (req.subTopics.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(req.subTopics.join(' · '),
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF7A8B9A))),
                        ),
                      const SizedBox(height: 4),
                      _packageBadge(req.package),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showActions || showDone)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                    top: BorderSide(color: Color(0xFFF0F0F0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _openChat(req.newcomer, req.newcomerName),
                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: const Text('Chat'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A3A5C),
                        side: const BorderSide(color: Color(0xFF1A3A5C)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  if (showActions) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _updateStatus(req, 'declined'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateStatus(req, 'accepted'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE8944A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                  if (showDone) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateStatus(req, 'done'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
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
    final colors = {
      'pending':   [const Color(0xFFFFF3CD), const Color(0xFF856404)],
      'accepted':  [const Color(0xFFD1FAE5), Colors.green.shade800],
      'declined':  [const Color(0xFFFFE4E4), Colors.red.shade700],
      'done':      [const Color(0xFFE0F2FE), Colors.blue.shade700],
      'cancelled': [const Color(0xFFF3F4F6), Colors.grey.shade600],
    };
    final pair = colors[status] ?? colors['pending']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: pair[0], borderRadius: BorderRadius.circular(20)),
      child: Text(status,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: pair[1])),
    );
  }

  Widget _packageBadge(String package) {
    const labels = {
      'starter':    '2hr Starter',
      'half_day':   'Half Day',
      'first_week': 'First Week',
      'custom':     'Custom',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3A5C).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        labels[package] ?? package,
        style: const TextStyle(
            fontSize: 11, color: Color(0xFF1A3A5C), fontWeight: FontWeight.w500),
      ),
    );
  }

  String _categoryIcon(String category) {
    const icons = {
      'Banking': '🏦',
      'Housing': '🏠',
      'SIM Card': '📱',
      'Legal & Documents': '📄',
      'Healthcare': '🏥',
      'Language Support': '💬',
      'Job Search': '💼',
      'General Guidance': '🧭',
    };
    return icons[category] ?? '🤝';
  }
}
