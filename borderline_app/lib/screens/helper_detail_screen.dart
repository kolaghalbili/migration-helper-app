import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/helper_model.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';

class HelperDetailScreen extends StatefulWidget {
  final Helper helper;
  const HelperDetailScreen({super.key, required this.helper});

  @override
  State<HelperDetailScreen> createState() => _HelperDetailScreenState();
}

class _HelperDetailScreenState extends State<HelperDetailScreen> {
  int _imageIndex = 0;

  Helper get h => widget.helper;

  List<String> get _imageUrls {
    final urls = h.profileImages
        .map((i) => i.imageUrl)
        .whereType<String>()
        .toList();
    if (urls.isEmpty && h.avatar != null) return [h.avatar!];
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
                  _buildStats(),
                  const SizedBox(height: 20),
                  _buildLocationRow(),
                  if (h.languages.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildLanguages(),
                  ],
                  const SizedBox(height: 20),
                  if (h.bio.isNotEmpty) ...[
                    _sectionTitle('About'),
                    const SizedBox(height: 8),
                    Text(h.bio,
                        style: const TextStyle(
                            color: Color(0xFF4A5568), height: 1.6)),
                    const SizedBox(height: 20),
                  ],
                  if (h.specialties.isNotEmpty) ...[
                    _sectionTitle('Specialties'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: h.specialties
                          .map((s) => _specialtyChip(s))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  _buildRequestButton(),
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
      expandedHeight: 260,
      pinned: true,
      backgroundColor: const Color(0xFF1A3A5C),
      flexibleSpace: FlexibleSpaceBar(
        background: _imageUrls.isEmpty
            ? _placeholder()
            : Stack(
                children: [
                  PageView.builder(
                    itemCount: _imageUrls.length,
                    onPageChanged: (i) => setState(() => _imageIndex = i),
                    itemBuilder: (_, i) => CachedNetworkImage(
                      imageUrl: _imageUrls[i],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, url) => _placeholder(),
                      errorWidget: (_, url, e) => _placeholder(),
                    ),
                  ),
                  // Name overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                        ),
                      ),
                      child: _nameRow(),
                    ),
                  ),
                  // Dot indicators
                  if (_imageUrls.length > 1)
                    Positioned(
                      top: 12,
                      right: 16,
                      child: Row(
                        children: List.generate(
                          _imageUrls.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(left: 4),
                            width: i == _imageIndex ? 16 : 6,
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

  Widget _placeholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A3A5C), Color(0xFF2E8B8B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              CircleAvatar(
                radius: 45,
                backgroundColor:
                    const Color(0xFFE8944A).withValues(alpha: 0.3),
                child: Text(
                  h.firstName.isNotEmpty
                      ? h.firstName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              _nameRow(),
            ],
          ),
        ),
      );

  Widget _nameRow() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            h.fullName,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          if (h.isVerified) ...[
            const SizedBox(width: 6),
            const Icon(Icons.verified,
                color: Colors.lightBlueAccent, size: 20),
          ],
        ],
      );

  // ── Body sections ─────────────────────────────────────────────────────────

  Widget _buildStats() {
    return Row(
      children: [
        _statCard('⭐', h.ratingAvg.toStringAsFixed(1), 'Rating'),
        const SizedBox(width: 12),
        _statCard('✅', '${h.totalReviews}', 'Reviews'),
        const SizedBox(width: 12),
        _statCard(
          '💰',
          h.hourlyRate != null
              ? '€${h.hourlyRate!.toStringAsFixed(0)}/h'
              : 'Free',
          'Rate',
        ),
      ],
    );
  }

  Widget _statCard(String emoji, String value, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)
            ],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1A3A5C))),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF7A8B9A))),
            ],
          ),
        ),
      );

  Widget _buildLocationRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (h.city.isNotEmpty || h.country.isNotEmpty)
          _infoRow(Icons.location_on_outlined,
              [h.city, h.country].where((s) => s.isNotEmpty).join(', ')),
        if (h.nationality.isNotEmpty)
          _infoRow(Icons.flag_outlined, 'From: ${h.nationality}')
        else if (h.originCountry.isNotEmpty)
          _infoRow(Icons.flag_outlined, 'From: ${h.originCountry}'),
      ],
    );
  }

  Widget _buildLanguages() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.language, size: 16, color: Color(0xFF7A8B9A)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            h.languages.join(' · '),
            style: const TextStyle(color: Color(0xFF4A5568), fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF7A8B9A)),
            const SizedBox(width: 8),
            Text(text,
                style: const TextStyle(
                    color: Color(0xFF4A5568), fontSize: 14)),
          ],
        ),
      );

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A3A5C)),
      );

  Widget _specialtyChip(Specialty s) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8944A).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFFE8944A).withValues(alpha: 0.3)),
        ),
        child: Text(
          '${s.icon} ${s.name}',
          style: const TextStyle(
              color: Color(0xFFE8944A), fontWeight: FontWeight.w600),
        ),
      );

  Widget _buildRequestButton() => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _openChat,
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Request Help',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE8944A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );

  Future<void> _openChat() async {
    final chatService = ChatService();
    final me = await AuthService().getMe();
    if (me == null || !mounted) return;
    if (me['id'] == h.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't start a chat with yourself.")),
      );
      return;
    }
    final conversation =
        await chatService.getOrCreateConversation(h.id);
    if (conversation == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversation['id'],
          helperName: h.fullName,
          currentUserId: me['id'],
        ),
      ),
    );
  }
}
