import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/helper_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'rate_screen.dart';
import 'request_help_screen.dart';

class HelperDetailScreen extends StatefulWidget {
  final Helper helper;
  const HelperDetailScreen({super.key, required this.helper});

  @override
  State<HelperDetailScreen> createState() => _HelperDetailScreenState();
}

class _HelperDetailScreenState extends State<HelperDetailScreen> {
  int _imageIndex = 0;
  List<Review> _reviews = [];
  bool _hasReviewed = false;
  int? _myUserId;
  double _ratingAvg = 0;
  int _totalReviews = 0;

  Helper get h => widget.helper;

  List<String> get _imageUrls {
    final urls = h.profileImages.map((i) => i.imageUrl).whereType<String>().toList();
    if (urls.isEmpty && h.avatar != null) return [h.avatar!];
    return urls;
  }

  @override
  void initState() {
    super.initState();
    _ratingAvg = h.ratingAvg;
    _totalReviews = h.totalReviews;
    _loadReviewData();
  }

  Future<void> _loadReviewData() async {
    final authService = AuthService();
    final results = await Future.wait([
      authService.getReviews(h.id),
      authService.getMe(),
    ]);

    final reviewList = results[0] as List<dynamic>;
    final me = results[1] as Map<String, dynamic>?;
    final myId = me?['id'] as int?;

    final reviews = reviewList.map((r) => Review.fromJson(r as Map<String, dynamic>)).toList();
    final alreadyReviewed = myId != null && reviews.any((r) => r.reviewer == myId);
    final total = reviews.length;
    final avg = total > 0
        ? reviews.map((r) => r.rating).reduce((a, b) => a + b) / total
        : 0.0;

    if (mounted) {
      setState(() {
        _reviews = reviews;
        _hasReviewed = alreadyReviewed;
        _myUserId = myId;
        _totalReviews = total;
        _ratingAvg = avg;
      });
    }
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
                        style: const TextStyle(color: Color(0xFF4A5568), height: 1.6)),
                    const SizedBox(height: 20),
                  ],
                  if (h.specialties.isNotEmpty) ...[
                    _sectionTitle('Specialties'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: h.specialties.map((s) => _specialtyChip(s)).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  _buildActionButtons(),
                  const SizedBox(height: 32),
                  if (_reviews.isNotEmpty) ...[
                    _buildReviewsSection(),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────

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
                              color: i == _imageIndex ? Colors.white : Colors.white54,
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
                backgroundColor: const Color(0xFFE8944A).withValues(alpha: 0.3),
                child: Text(
                  h.firstName.isNotEmpty ? h.firstName[0].toUpperCase() : '?',
                  style: const TextStyle(
                      fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
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
          Text(h.fullName,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          if (h.isVerified) ...[
            const SizedBox(width: 6),
            const Icon(Icons.verified, color: Colors.lightBlueAccent, size: 20),
          ],
        ],
      );

  // ── Body sections ─────────────────────────────────────────────────────────

  Widget _buildStats() {
    return Row(
      children: [
        _statCard('⭐', _ratingAvg.toStringAsFixed(1), 'Rating'),
        const SizedBox(width: 12),
        _statCard('✅', '$_totalReviews', 'Reviews'),
        const SizedBox(width: 12),
        _statCard(
          '💰',
          h.hourlyRate != null ? '€${h.hourlyRate!.toStringAsFixed(0)}/h' : 'Free',
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
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)
            ],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A3A5C))),
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF7A8B9A))),
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
          child: Text(h.languages.join(' · '),
              style: const TextStyle(color: Color(0xFF4A5568), fontSize: 13)),
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
            Text(text, style: const TextStyle(color: Color(0xFF4A5568), fontSize: 14)),
          ],
        ),
      );

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C)),
      );

  Widget _specialtyChip(Specialty s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8944A).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8944A).withValues(alpha: 0.3)),
        ),
        child: Text('${s.icon} ${s.name}',
            style: const TextStyle(color: Color(0xFFE8944A), fontWeight: FontWeight.w600)),
      );

  // ── Action buttons ────────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    final isSelf = _myUserId == h.id;
    return Column(
      children: [
        if (!isSelf) ...[
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _openRequestHelp,
              icon: const Icon(Icons.handshake_outlined),
              label: const Text('Request Help',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8944A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _openChat,
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Message', style: TextStyle(fontSize: 15)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A3A5C),
                side: const BorderSide(color: Color(0xFF1A3A5C)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          if (!_hasReviewed) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _openRateScreen,
                icon: const Icon(Icons.star_outline, size: 18),
                label: const Text('Leave a Review', style: TextStyle(fontSize: 15)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber.shade700,
                  side: BorderSide(color: Colors.amber.shade700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  // ── Reviews section ───────────────────────────────────────────────────────

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionTitle('Reviews'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1A3A5C).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${_reviews.length}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ..._reviews.take(5).map(_buildReviewCard),
        if (_reviews.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: TextButton(
                onPressed: () {},
                child: Text('See all ${_reviews.length} reviews →',
                    style: const TextStyle(color: Color(0xFFE8944A))),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF1A3A5C).withValues(alpha: 0.15),
                backgroundImage: review.reviewerImage != null
                    ? NetworkImage(review.reviewerImage!)
                    : null,
                child: review.reviewerImage == null
                    ? Text(
                        review.reviewerName.isNotEmpty
                            ? review.reviewerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C)),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.reviewerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: i < review.rating ? Colors.amber : const Color(0xFFDCE5ED),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                style: const TextStyle(fontSize: 11, color: Color(0xFF7A8B9A)),
              ),
            ],
          ),
          if (review.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: review.tags
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A3A5C).withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(tag,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF1A3A5C))),
                      ))
                  .toList(),
            ),
          ],
          if (review.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('"${review.note}"',
                style: const TextStyle(
                    color: Color(0xFF4A5568), fontSize: 13, fontStyle: FontStyle.italic,
                    height: 1.5)),
          ],
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      final diff = now.difference(dt).inDays;
      if (diff == 0) return 'today';
      if (diff == 1) return 'yesterday';
      if (diff < 7) return '${diff}d ago';
      if (diff < 30) return '${(diff / 7).floor()}w ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _openRequestHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RequestHelpScreen(helper: h)),
    );
  }

  Future<void> _openChat() async {
    final me = await AuthService().getMe();
    if (me == null || !mounted) return;
    if (me['id'] == h.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't start a chat with yourself.")),
      );
      return;
    }
    final conversation = await ChatService().getOrCreateConversation(h.id);
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

  Future<void> _openRateScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => RateScreen(helper: h)),
    );
    if (result == true) {
      _loadReviewData();
    }
  }
}
