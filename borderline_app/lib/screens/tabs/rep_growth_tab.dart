import 'package:flutter/material.dart';

class RepGrowthTab extends StatelessWidget {
  final Map<String, dynamic>? me;
  final int pendingCount;
  final int acceptedCount;
  final int doneCount;

  const RepGrowthTab({
    super.key,
    required this.me,
    required this.pendingCount,
    required this.acceptedCount,
    required this.doneCount,
  });

  // ── Helper level logic ─────────────────────────────────────────────────────

  int get _totalSessions => me?['total_sessions'] ?? 0;
  double get _rating => double.tryParse(me?['rating_avg']?.toString() ?? '0') ?? 0;
  int get _totalReviews => me?['total_reviews'] ?? 0;
  int get _badgeCount => (me?['badges'] as List?)?.length ?? 0;

  String get _levelLabel {
    if (_totalSessions >= 50) return 'Elite';
    if (_totalSessions >= 20) return 'Pro';
    if (_totalSessions >= 5)  return 'Rising';
    return 'Newcomer';
  }

  String get _levelEmoji {
    if (_totalSessions >= 50) return '🏆';
    if (_totalSessions >= 20) return '⭐';
    if (_totalSessions >= 5)  return '🌱';
    return '👋';
  }

  int get _levelMin {
    if (_totalSessions >= 50) return 50;
    if (_totalSessions >= 20) return 20;
    if (_totalSessions >= 5)  return 5;
    return 0;
  }

  int get _levelMax {
    if (_totalSessions >= 50) return 100;
    if (_totalSessions >= 20) return 50;
    if (_totalSessions >= 5)  return 20;
    return 5;
  }

  double get _levelProgress =>
      ((_totalSessions - _levelMin) / (_levelMax - _levelMin)).clamp(0.0, 1.0);

  // ── Acceptance rate ────────────────────────────────────────────────────────
  double get _acceptanceRate {
    final total = pendingCount + acceptedCount + doneCount;
    if (total == 0) return 0;
    return ((acceptedCount + doneCount) / total * 100);
  }

  // Next badge to climb toward
  String get _nextBadge {
    if (_totalSessions >= 50) return 'You\'ve reached Elite! 🏆';
    if (_totalSessions >= 20) return '${50 - _totalSessions} sessions to Elite 🏆';
    if (_totalSessions >= 5)  return '${20 - _totalSessions} sessions to Pro ⭐';
    return '${5 - _totalSessions} sessions to Rising 🌱';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Level card ────────────────────────────────────
        _levelCard(),
        const SizedBox(height: 20),

        // ── This-week stats ───────────────────────────────
        const Text('Your Stats',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3A5C))),
        const SizedBox(height: 12),
        _statsGrid(),
        const SizedBox(height: 20),

        // ── Next badge ────────────────────────────────────
        _nextBadgeCard(),
        const SizedBox(height: 20),

        // ── Tips to climb ─────────────────────────────────
        _tipsCard(),
      ],
    );
  }

  Widget _levelCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A3A5C), Color(0xFF2E6DA4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_levelEmoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_levelLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    Text('$_totalSessions sessions completed',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Progress bar
            Row(
              children: [
                Text('$_levelMin',
                    style: const TextStyle(color: Colors.white54, fontSize: 11)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _levelProgress,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(Color(0xFFE8944A)),
                        minHeight: 8,
                      ),
                    ),
                  ),
                ),
                Text('$_levelMax',
                    style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 8),
            Text(_nextBadge,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      );

  Widget _statsGrid() {
    final stats = [
      {
        'icon': '⭐',
        'value': _rating.toStringAsFixed(1),
        'label': 'Avg Rating',
        'color': Colors.amber,
      },
      {
        'icon': '✅',
        'value': '${_acceptanceRate.toStringAsFixed(0)}%',
        'label': 'Accept Rate',
        'color': Colors.green,
      },
      {
        'icon': '💬',
        'value': '$_totalReviews',
        'label': 'Reviews',
        'color': const Color(0xFF1A3A5C),
      },
      {
        'icon': '🏅',
        'value': '$_badgeCount',
        'label': 'Badges',
        'color': const Color(0xFFE8944A),
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: stats.map((s) => _statCard(s)).toList(),
    );
  }

  Widget _statCard(Map<String, dynamic> s) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Text(s['icon'] as String, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(s['value'] as String,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: s['color'] as Color)),
                Text(s['label'] as String,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF7A8B9A))),
              ],
            ),
          ],
        ),
      );

  Widget _nextBadgeCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8944A).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFE8944A).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Next Goal',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3A5C))),
                  const SizedBox(height: 2),
                  Text(_nextBadge,
                      style: const TextStyle(
                          color: Color(0xFFE8944A),
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _tipsCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tips to Grow 🚀',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1A3A5C))),
            const SizedBox(height: 12),
            _tip('📸', 'Add a profile photo', 'Helpers with photos get 3x more bookings.'),
            _tip('⚡', 'Reply fast', 'Quick responses boost your acceptance rate.'),
            _tip('🌟', 'Ask for reviews', 'After every session, remind newcomers to rate you.'),
            _tip('🏅', 'Earn badges', 'Verified badges unlock higher-paying requests.'),
          ],
        ),
      );

  Widget _tip(String emoji, String title, String desc) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A3A5C),
                          fontSize: 13)),
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF7A8B9A))),
                ],
              ),
            ),
          ],
        ),
      );
}