import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/helper_model.dart';
import 'chat_screen.dart';

class QuickMatchScreen extends StatefulWidget {
  const QuickMatchScreen({super.key, this.service});
  final ApiService? service;

  @override
  State<QuickMatchScreen> createState() => _QuickMatchScreenState();
}

class _QuickMatchScreenState extends State<QuickMatchScreen>
    with SingleTickerProviderStateMixin {
  late final ApiService _service;

  List<Helper> _deck = [];
  int _currentIndex = 0;
  final Set<int> _seen = {};
  final List<int> _starred = [];

  double _dragDx = 0;
  bool _isFlying = false;
  bool _isLoading = true;

  late AnimationController _swipeCtrl;
  Animation<double>? _swipeAnimation;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ApiService();
    _swipeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadDeck();
  }

  Future<void> _loadDeck() async {
    setState(() => _isLoading = true);
    final helpers = await _service.getHelpers();
    if (!mounted) return;
    final filtered = helpers.where((h) => !_seen.contains(h.id)).toList()
      ..shuffle(Random());
    setState(() {
      _deck = filtered;
      _currentIndex = 0;
      _isLoading = false;
    });
  }

  void _swipeRight() {
    if (_currentIndex >= _deck.length || _isFlying) return;
    final helper = _deck[_currentIndex];
    _starred.add(helper.id);
    _seen.add(helper.id);
    _animateOff(
      direction: 1,
      onDone: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⭐ Saved ${helper.firstName}'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }

  void _swipeLeft() {
    if (_currentIndex >= _deck.length || _isFlying) return;
    _seen.add(_deck[_currentIndex].id);
    _animateOff(direction: -1);
  }

  void _animateOff({required int direction, VoidCallback? onDone}) {
    final screenWidth = MediaQuery.of(context).size.width;
    _swipeAnimation = Tween<double>(
      begin: _dragDx,
      end: screenWidth * 1.5 * direction,
    ).animate(CurvedAnimation(parent: _swipeCtrl, curve: Curves.easeOut));
    setState(() => _isFlying = true);
    _swipeCtrl.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() {
        _currentIndex++;
        _dragDx = 0;
        _isFlying = false;
      });
      _swipeCtrl.reset();
      onDone?.call();
    });
  }

  void _snapBack() {
    _swipeAnimation = Tween<double>(begin: _dragDx, end: 0)
        .animate(CurvedAnimation(parent: _swipeCtrl, curve: Curves.elasticOut));
    setState(() => _isFlying = true);
    _swipeCtrl.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() {
        _dragDx = 0;
        _isFlying = false;
      });
      _swipeCtrl.reset();
    });
  }

  Future<void> _openChat() async {
    if (_currentIndex >= _deck.length) return;
    final helper = _deck[_currentIndex];
    final me = await AuthService().getMe();
    final currentUserId = (me?['id'] as int?) ?? 0;
    final result = await _service.createConversation(helper.id);
    if (!mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open chat')),
      );
      return;
    }
    final conversationId = result['id'] as int;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversationId,
          helperName: helper.fullName,
          currentUserId: currentUserId,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _swipeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _deck.length - _currentIndex;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Quick Match',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '$remaining left',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentIndex >= _deck.length
              ? _buildEmptyState()
              : Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_currentIndex + 1 < _deck.length)
                              Positioned.fill(
                                child: Transform.translate(
                                  offset: const Offset(0, -8),
                                  child: Transform.scale(
                                    scale: 0.95,
                                    child: Opacity(
                                      opacity: 0.6,
                                      child: IgnorePointer(
                                        child: _buildCardContent(
                                            _deck[_currentIndex + 1]),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Positioned.fill(
                              child: _buildForegroundCard(
                                  _deck[_currentIndex]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildActionBar(),
                    const SizedBox(height: 16),
                  ],
                ),
    );
  }

  Widget _buildForegroundCard(Helper helper) {
    return GestureDetector(
      onHorizontalDragStart: (_) {
        if (_isFlying) return;
        setState(() => _dragDx = 0);
      },
      onHorizontalDragUpdate: (details) {
        if (_isFlying) return;
        setState(() => _dragDx += details.delta.dx);
      },
      onHorizontalDragEnd: (_) {
        if (_isFlying) return;
        if (_dragDx > 80) {
          _swipeRight();
        } else if (_dragDx < -80) {
          _swipeLeft();
        } else {
          _snapBack();
        }
      },
      child: AnimatedBuilder(
        animation: _swipeCtrl,
        builder: (ctx, child) {
          final dx =
              _isFlying ? (_swipeAnimation?.value ?? _dragDx) : _dragDx;
          return Transform.rotate(
            angle: (dx / 400) * 0.3,
            child: Transform.translate(
              offset: Offset(dx, dx.abs() * 0.2),
              child: Stack(
                children: [
                  child!,
                  if (dx > 40)
                    Positioned(
                      top: 20,
                      left: 20,
                      child: _buildSwipeLabel('★ LIKE', Colors.green, dx),
                    ),
                  if (dx < -40)
                    Positioned(
                      top: 20,
                      right: 20,
                      child: _buildSwipeLabel('✕ PASS', Colors.red, dx),
                    ),
                ],
              ),
            ),
          );
        },
        child: _buildCardContent(helper),
      ),
    );
  }

  Widget _buildSwipeLabel(String text, Color color, double dx) {
    return Opacity(
      opacity: (dx.abs() / 120).clamp(0.0, 1.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCardContent(Helper helper) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 6,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildHeroImage(helper),
                if (helper.isVerified)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '✓ verified',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildCardInfo(helper),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(Helper helper) {
    final url = helper.primaryImageUrl;
    if (url != null) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, _) => _buildImageFallback(helper),
        errorWidget: (_, _, _) => _buildImageFallback(helper),
      );
    }
    return _buildImageFallback(helper);
  }

  Widget _buildImageFallback(Helper helper) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3A5C), Color(0xFF2E8B8B)],
        ),
      ),
      child: Center(
        child: Text(
          helper.firstName.isNotEmpty
              ? helper.firstName[0].toUpperCase()
              : '?',
          style: const TextStyle(
              fontSize: 80,
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCardInfo(Helper helper) {
    final flag = _nationalityFlag(helper.nationality);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                helper.firstName,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A5C)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(flag, style: const TextStyle(fontSize: 22)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          helper.country.isNotEmpty
              ? '${helper.city} · ${helper.country}'
              : helper.city,
          style: const TextStyle(color: Color(0xFF7A8B9A), fontSize: 13),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Text(
            helper.bio,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
          ),
        ),
        if (helper.specialties.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: helper.specialties
                .take(4)
                .map(
                  (s) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8944A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${s.icon} ${s.name}',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFE8944A)),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _actionButton(
              icon: Icons.close,
              color: Colors.red,
              radius: 28,
              onTap: _swipeLeft),
          _actionButton(
              icon: Icons.chat_bubble_outline,
              color: Colors.grey,
              radius: 22,
              onTap: () => _openChat()),
          _actionButton(
              icon: Icons.star_border,
              color: Colors.green,
              radius: 28,
              onTap: _swipeRight),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required double radius,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: radius * 0.8),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              "You've seen all helpers in your area!",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A5C)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() => _seen.clear());
              _loadDeck();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A3A5C),
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Start over',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _nationalityFlag(String nationality) {
    const flags = {
      'iranian': '🇮🇷',
      'persian': '🇮🇷',
      'german': '🇩🇪',
      'french': '🇫🇷',
      'american': '🇺🇸',
      'british': '🇬🇧',
      'canadian': '🇨🇦',
      'australian': '🇦🇺',
      'turkish': '🇹🇷',
      'afghan': '🇦🇫',
      'syrian': '🇸🇾',
      'iraqi': '🇮🇶',
      'moroccan': '🇲🇦',
      'algerian': '🇩🇿',
      'lebanese': '🇱🇧',
      'jordanian': '🇯🇴',
      'saudi': '🇸🇦',
      'egyptian': '🇪🇬',
      'pakistani': '🇵🇰',
      'indian': '🇮🇳',
      'chinese': '🇨🇳',
      'spanish': '🇪🇸',
      'italian': '🇮🇹',
      'portuguese': '🇵🇹',
      'dutch': '🇳🇱',
      'swedish': '🇸🇪',
      'norwegian': '🇳🇴',
      'danish': '🇩🇰',
      'polish': '🇵🇱',
      'ukrainian': '🇺🇦',
      'russian': '🇷🇺',
      'greek': '🇬🇷',
    };
    return flags[nationality.toLowerCase()] ?? '🌍';
  }
}
