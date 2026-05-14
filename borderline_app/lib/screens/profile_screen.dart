import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/helper_model.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';

/// Public profile page — works for both helpers and newcomers.
class ProfileScreen extends StatefulWidget {
  final Helper user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _imageIndex = 0;

  Helper get u => widget.user;

  List<String> get _imageUrls {
    final urls = u.profileImages
        .map((i) => i.imageUrl)
        .whereType<String>()
        .toList();
    if (urls.isEmpty && u.avatar != null) return [u.avatar!];
    return urls;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNameRow(),
                  const SizedBox(height: 16),
                  if (u.role == 'helper') _buildStatRow(),
                  if (u.role == 'helper') const SizedBox(height: 20),
                  _buildInfoChips(),
                  const SizedBox(height: 20),
                  if (u.bio.isNotEmpty) _buildSection('About', Text(u.bio, style: const TextStyle(color: Color(0xFF4A5568), height: 1.6))),
                  if (u.languages.isNotEmpty) _buildSection('Languages', _buildLanguageChips()),
                  if (u.specialties.isNotEmpty && u.role == 'helper') _buildSection('Specialties', _buildSpecialtyChips()),
                  if (u.role == 'helper') _buildContactButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── App bar with photo gallery ────────────────────────────────────────────

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: _imageUrls.isEmpty ? 160 : 300,
      pinned: true,
      backgroundColor: const Color(0xFF1A3A5C),
      flexibleSpace: FlexibleSpaceBar(
        background: _imageUrls.isEmpty
            ? _gradientPlaceholder()
            : Stack(
                children: [
                  PageView.builder(
                    itemCount: _imageUrls.length,
                    onPageChanged: (i) => setState(() => _imageIndex = i),
                    itemBuilder: (_, i) => CachedNetworkImage(
                      imageUrl: _imageUrls[i],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, url) => const Center(
                          child: CircularProgressIndicator(color: Colors.white54)),
                      errorWidget: (_, url, e) => _gradientPlaceholder(),
                    ),
                  ),
                  // Dot indicators
                  if (_imageUrls.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _imageUrls.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _imageIndex ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _imageIndex
                                  ? Colors.white
                                  : Colors.white54,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _gradientPlaceholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A3A5C), Color(0xFF2E8B8B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            u.firstName.isNotEmpty ? u.firstName[0].toUpperCase() : '?',
            style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.white54),
          ),
        ),
      );

  // ── Name & role row ───────────────────────────────────────────────────────

  Widget _buildNameRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    u.fullName,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A5C)),
                  ),
                  if (u.isVerified) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.verified, color: Color(0xFF2E8B8B), size: 22),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: u.role == 'helper'
                      ? const Color(0xFF2E8B8B).withValues(alpha: 0.15)
                      : const Color(0xFFE8944A).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  u.role == 'helper' ? 'Local Helper' : 'Newcomer',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: u.role == 'helper'
                        ? const Color(0xFF2E8B8B)
                        : const Color(0xFFE8944A),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (u.hourlyRate != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '€${u.hourlyRate!.toStringAsFixed(0)}/h',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A5C)),
              ),
              const Text('rate', style: TextStyle(fontSize: 11, color: Color(0xFF7A8B9A))),
            ],
          ),
      ],
    );
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  Widget _buildStatRow() {
    return Row(
      children: [
        _stat('⭐', u.ratingAvg.toStringAsFixed(1), 'Rating'),
        const SizedBox(width: 12),
        _stat('✅', '${u.totalReviews}', 'Reviews'),
        const SizedBox(width: 12),
        _stat('🤝', u.isVerified ? 'Verified' : 'Unverified', 'Status'),
      ],
    );
  }

  Widget _stat(String emoji, String value, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)
            ],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1A3A5C))),
              Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF7A8B9A))),
            ],
          ),
        ),
      );

  // ── Info chips (location, nationality) ────────────────────────────────────

  Widget _buildInfoChips() {
    final chips = <Widget>[];

    if (u.city.isNotEmpty || u.country.isNotEmpty) {
      chips.add(_infoChip(
        Icons.location_on_outlined,
        [u.city, u.country].where((s) => s.isNotEmpty).join(', '),
      ));
    }
    if (u.nationality.isNotEmpty) {
      chips.add(_infoChip(Icons.flag_outlined, 'From: ${u.nationality}'));
    } else if (u.originCountry.isNotEmpty) {
      chips.add(_infoChip(Icons.flag_outlined, 'From: ${u.originCountry}'));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 10, runSpacing: 8, children: chips);
  }

  Widget _infoChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDCE5ED)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF7A8B9A)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF4A5568))),
          ],
        ),
      );

  // ── Sections ──────────────────────────────────────────────────────────────

  Widget _buildSection(String title, Widget content) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A5C))),
            const SizedBox(height: 10),
            content,
          ],
        ),
      );

  Widget _buildLanguageChips() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: u.languages
            .map((l) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3A5C).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(l,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF1A3A5C))),
                ))
            .toList(),
      );

  Widget _buildSpecialtyChips() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: u.specialties
            .map((s) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8944A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFE8944A).withValues(alpha: 0.3)),
                  ),
                  child: Text('${s.icon} ${s.name}',
                      style: const TextStyle(
                          color: Color(0xFFE8944A),
                          fontWeight: FontWeight.w600)),
                ))
            .toList(),
      );

  // ── Contact button (helpers only) ─────────────────────────────────────────

  Widget _buildContactButton() => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _openChat,
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Request Help',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE8944A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );

  Future<void> _openChat() async {
    final chatService = ChatService();
    final authService = AuthService();
    final me = await authService.getMe();
    if (me == null || !mounted) return;
    final conversation = await chatService.getOrCreateConversation(u.id);
    if (conversation == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversation['id'],
          helperName: u.fullName,
          currentUserId: me['id'],
        ),
      ),
    );
  }
}
