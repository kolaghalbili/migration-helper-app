import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import '../models/helper_model.dart';
import 'edit_profile_screen.dart';

class NewcomerProfileScreen extends StatefulWidget {
  const NewcomerProfileScreen({super.key});

  @override
  State<NewcomerProfileScreen> createState() => _NewcomerProfileScreenState();
}

class _NewcomerProfileScreenState extends State<NewcomerProfileScreen> {
  final _authService = AuthService();

  Map<String, dynamic>? _me;
  List<HelpRequest> _requests = [];
  bool _isLoading = true;
  bool _isSavingScope = false;

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _setScope(String scope) async {
    setState(() => _isSavingScope = true);
    await _authService.updateProfile(helperScope: scope);
    if (!mounted) return;
    setState(() {
      if (_me != null) _me!['helper_scope'] = scope;
      _isSavingScope = false;
    });
  }

  List<HelpRequest> get _openRequests =>
      _requests.where((r) => r.status == 'pending' || r.status == 'accepted').toList();
  List<HelpRequest> get _pastRequests =>
      _requests.where((r) => r.status == 'done').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        foregroundColor: Colors.white,
        title: const Text('My Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
              if (updated == true) _load();
            },
            icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
            label: const Text('Edit',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(),
                    const SizedBox(height: 20),
                    _buildScopeSection(),
                    const SizedBox(height: 20),
                    _buildOpenRequests(),
                    const SizedBox(height: 20),
                    _buildPastSessions(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
    final firstName = _me?['first_name'] ?? '';
    final lastName = _me?['last_name'] ?? '';
    final nationality = _me?['nationality'] ?? '';
    final city = _me?['city'] ?? '';
    final bio = _me?['bio'] ?? '';
    final languages = (_me?['languages'] as List? ?? []).cast<String>();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$firstName $lastName'.trim(),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A5C))),
                if (city.isNotEmpty || nationality.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    [if (city.isNotEmpty) city, if (nationality.isNotEmpty) nationality]
                        .join(' · '),
                    style: const TextStyle(
                        color: Color(0xFF7A8B9A), fontSize: 13),
                  ),
                ],
                if (languages.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: languages
                        .take(4)
                        .map((l) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A3A5C).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(l,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF1A3A5C),
                                      fontWeight: FontWeight.w500)),
                            ))
                        .toList(),
                  ),
                ],
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(bio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4A5568),
                          height: 1.4)),
                ],
              ],
            ),
          ),
        ],
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
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorWidget: (_, u, e) => _avatarFallback(),
        ),
      );
    }
    return _avatarFallback();
  }

  Widget _avatarFallback() {
    final name = _me?['first_name'] ?? '?';
    return CircleAvatar(
      radius: 32,
      backgroundColor: const Color(0xFFE8944A).withValues(alpha: 0.2),
      child: Text(
        (name as String).isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE8944A)),
      ),
    );
  }

  Widget _buildScopeSection() {
    final currentScope = (_me?['helper_scope'] as String?) ?? 'any';

    const options = [
      {
        'value': 'any',
        'label': 'Open to all',
        'desc': 'Show me helpers from any background',
        'icon': '🌍',
      },
      {
        'value': 'same_nationality',
        'label': 'Same nationality',
        'desc': 'Prioritise helpers from my home country',
        'icon': '🤝',
      },
      {
        'value': 'language_match',
        'label': 'Language match',
        'desc': 'Show helpers who speak my language(s)',
        'icon': '💬',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Helper Preference',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3A5C))),
              const Spacer(),
              if (_isSavingScope)
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('How should we filter helpers for you?',
              style: TextStyle(fontSize: 12, color: Color(0xFF7A8B9A))),
          const SizedBox(height: 14),
          ...options.map((opt) {
            final selected = currentScope == opt['value'];
            return GestureDetector(
              onTap: _isSavingScope
                  ? null
                  : () => _setScope(opt['value'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF1A3A5C)
                      : const Color(0xFFF5F0EB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF1A3A5C)
                        : const Color(0xFFDCE5ED),
                  ),
                ),
                child: Row(
                  children: [
                    Text(opt['icon'] as String,
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(opt['label'] as String,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF1A3A5C))),
                          Text(opt['desc'] as String,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: selected
                                      ? Colors.white70
                                      : const Color(0xFF7A8B9A))),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle,
                          color: Color(0xFFE8944A), size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOpenRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Open Requests (${_openRequests.length})',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3A5C))),
        const SizedBox(height: 10),
        if (_openRequests.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('No open requests.',
                  style: TextStyle(color: Color(0xFF7A8B9A))),
            ),
          )
        else
          ..._openRequests.map(_buildRequestTile),
      ],
    );
  }

  Widget _buildPastSessions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Past Sessions (${_pastRequests.length})',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3A5C))),
        const SizedBox(height: 10),
        if (_pastRequests.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('No completed sessions yet.',
                  style: TextStyle(color: Color(0xFF7A8B9A))),
            ),
          )
        else
          ..._pastRequests.map(_buildRequestTile),
      ],
    );
  }

  Widget _buildRequestTile(HelpRequest req) {
    const icons = {
      'Banking': '🏦', 'Housing': '🏠', 'SIM Card': '📱',
      'Legal & Documents': '📄', 'Healthcare': '🏥',
      'Language Support': '💬', 'Job Search': '💼',
      'General Guidance': '🧭',
    };
    const statusColors = {
      'pending':   Color(0xFFFFF3CD),
      'accepted':  Color(0xFFD1FAE5),
      'done':      Color(0xFFE0F2FE),
      'cancelled': Color(0xFFF3F4F6),
      'declined':  Color(0xFFFFE4E4),
    };
    const statusText = {
      'pending':   Color(0xFF856404),
      'accepted':  Colors.green,
      'done':      Colors.blue,
      'cancelled': Colors.grey,
      'declined':  Colors.red,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(icons[req.category] ?? '🤝',
              style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(req.category,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A3A5C))),
                if (req.helperName != null)
                  Text('with ${req.helperName}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF7A8B9A))),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColors[req.status] ?? const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(req.status,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusText[req.status] ?? Colors.grey)),
          ),
        ],
      ),
    );
  }
}
