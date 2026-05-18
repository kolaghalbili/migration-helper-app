import 'package:flutter/material.dart';
import '../models/helper_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';

class RequestIntakeScreen extends StatefulWidget {
  final HelpRequest request;
  const RequestIntakeScreen({super.key, required this.request});

  @override
  State<RequestIntakeScreen> createState() => _RequestIntakeScreenState();
}

class _RequestIntakeScreenState extends State<RequestIntakeScreen> {
  final _api = ApiService();
  final _authService = AuthService();
  bool _isActing = false;
  String? _selectedQuickReply;
  final _customReplyCtrl = TextEditingController();
  bool _showCustomInput = false;

  static const _accent = Color(0xFFE8944A);
  static const _primary = Color(0xFF1A3A5C);
  static const _bg = Color(0xFFF5F0EB);

  @override
  void dispose() {
    _customReplyCtrl.dispose();
    super.dispose();
  }

  String _packageLabel(String p) {
    const map = {
      'starter': '2h Starter',
      'half_day': 'Half Day',
      'first_week': 'First Week',
      'custom': 'Custom',
    };
    return map[p] ?? p;
  }

  String _relativeTime(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      return '${diff.inMinutes}m ago';
    } catch (_) {
      return isoDate;
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Future<void> _onAccept() async {
    setState(() => _isActing = true);

    final ok = await _api.updateRequestStatus(widget.request.id, 'accepted');
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to accept. Try again.')),
      );
      setState(() => _isActing = false);
      return;
    }

    final convId = await _api.getOrCreateConversation(widget.request.newcomer);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request accepted! 🎉')),
    );

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    if (convId != null) {
      final me = await _authService.getMe();
      final currentUserId = (me?['id'] as num?)?.toInt() ?? 0;
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: convId,
            helperName: widget.request.newcomerName,
            currentUserId: currentUserId,
          ),
        ),
      );
    } else {
      Navigator.pop(context, 'accepted');
    }
  }

  Future<void> _onDecline() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Decline this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isActing = true);
    await _api.updateRequestStatus(widget.request.id, 'declined');
    if (!mounted) return;
    Navigator.pop(context, 'declined');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text(
          'New Request',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContextCard(),
            const SizedBox(height: 8),
            _buildQuickReplySection(),
            const SizedBox(height: 8),
            _buildProposePackage(),
            const SizedBox(height: 8),
            _buildCustomInputSection(),
            _buildCustomReplyLink(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildContextCard() {
    final req = widget.request;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _accent.withValues(alpha: 0.2),
                child: Text(
                  _initials(req.newcomerName),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    req.newcomerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _primary,
                    ),
                  ),
                  Text(
                    'arriving soon · ${_relativeTime(req.createdAt)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            req.description,
            style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _topicChip(req.category),
              ...req.subTopics.map(_topicChip),
            ],
          ),
          if (req.package.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Package: ${_packageLabel(req.package)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _topicChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: _accent,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildQuickReplySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Reply',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _primary,
            ),
          ),
          const SizedBox(height: 8),
          _quickReplyCard(
            Icons.waving_hand,
            'happy to help! when would you like to meet?',
          ),
          _quickReplyCard(
            Icons.description_outlined,
            'send me your passport scan and I\'ll review',
          ),
          _quickReplyCard(
            Icons.calendar_today_outlined,
            'let me check my schedule — I\'ll get back tonight',
          ),
        ],
      ),
    );
  }

  Widget _quickReplyCard(IconData icon, String message) {
    final isSelected = _selectedQuickReply == message;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedQuickReply = message;
        _showCustomInput = false;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _accent : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18, color: isSelected ? _accent : _primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? _accent : const Color(0xFF333333),
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, size: 16, color: _accent),
          ],
        ),
      ),
    );
  }

  Widget _buildProposePackage() {
    final packages = [
      ('half_day', 'Half-day · €60 · sat'),
      ('first_week', 'First week · €180'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Or propose a package',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: packages
                .map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _customReplyCtrl.text =
                            'I\'d like to propose the ${p.$2} package. Let me know if that works for you!';
                        _showCustomInput = true;
                        _selectedQuickReply = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          p.$2,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomInputSection() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: (_showCustomInput || _selectedQuickReply == null)
          ? Padding(
              key: const ValueKey('custom-input'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _customReplyCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Write a custom reply...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDCE5ED)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDCE5ED)),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(key: ValueKey('custom-hidden')),
    );
  }

  Widget _buildCustomReplyLink() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextButton.icon(
        onPressed: () => setState(() {
          _showCustomInput = true;
          _selectedQuickReply = null;
        }),
        icon: const Text('✏️'),
        label: const Text('Write a custom reply'),
        style: TextButton.styleFrom(foregroundColor: _primary),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(
            width: 100,
            child: OutlinedButton(
              onPressed: _isActing ? null : _onDecline,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: const Text('Decline'),
            ),
          ),
          SizedBox(
            width: 120,
            child: OutlinedButton(
              onPressed: _isActing
                  ? null
                  : () => setState(
                      () => _showCustomInput = !_showCustomInput),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: const BorderSide(color: Colors.grey),
              ),
              child: const Text('Custom reply'),
            ),
          ),
          SizedBox(
            width: 100,
            child: ElevatedButton(
              onPressed: _isActing ? null : _onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Accept →'),
            ),
          ),
        ],
      ),
    );
  }
}
