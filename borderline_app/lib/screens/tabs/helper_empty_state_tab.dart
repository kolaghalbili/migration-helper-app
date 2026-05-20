import 'package:flutter/material.dart';
import '../set_price_screen.dart';
import '../edit_profile_screen.dart';

class HelperEmptyStateTab extends StatelessWidget {
  final Map<String, dynamic>? me;
  final VoidCallback onRefresh;

  const HelperEmptyStateTab({
    super.key,
    required this.me,
    required this.onRefresh,
  });

  // ── Profile completeness ───────────────────────────────────────────────────

  bool get _hasPhoto {
    final images = me?['profile_images'] as List?;
    return images != null && images.isNotEmpty;
  }

  bool get _hasBio => (me?['bio'] as String? ?? '').trim().length > 10;

  bool get _hasSpecialties {
    final s = me?['specialties'] as List?;
    return s != null && s.isNotEmpty;
  }

  bool get _hasRate => me?['hourly_rate'] != null;

  bool get _isIdVerified => me?['id_verified'] == true;

  List<Map<String, dynamic>> get _steps => [
        {
          'emoji': '🪪',
          'title': 'Verify your ID',
          'desc': 'Required to accept paid sessions.',
          'done': _isIdVerified,
          'action': null, // admin-side, no nav
        },
        {
          'emoji': '📸',
          'title': 'Add photo & bio',
          'desc': 'Let newcomers know who you are.',
          'done': _hasPhoto && _hasBio,
          'action': 'edit_profile',
        },
        {
          'emoji': '🏷️',
          'title': 'Choose your specialties',
          'desc': 'Pick areas where you can help.',
          'done': _hasSpecialties,
          'action': 'edit_profile',
        },
        {
          'emoji': '💰',
          'title': 'Set your rate',
          'desc': 'Free, hourly, or packages.',
          'done': _hasRate,
          'action': 'set_price',
        },
      ];

  int get _completedCount => _steps.where((s) => s['done'] == true).length;
  double get _progress => _completedCount / _steps.length;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Welcome hero ──────────────────────────────────
        _welcomeCard(),
        const SizedBox(height: 24),

        // ── Progress ──────────────────────────────────────
        _progressSection(context),
        const SizedBox(height: 24),

        // ── What happens next ─────────────────────────────
        _whatNextCard(),
      ],
    );
  }

  Widget _welcomeCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A3A5C), Color(0xFF2E6DA4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Text('👋', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Welcome, ${me?['first_name'] ?? 'Helper'}!',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'You\'re about to make a real difference.\nComplete your profile to start receiving requests.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      );

  Widget _progressSection(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Profile Setup',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3A5C))),
              Text('$_completedCount / ${_steps.length}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE8944A))),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: const Color(0xFFDCE5ED),
              valueColor:
                  const AlwaysStoppedAnimation(Color(0xFFE8944A)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          ..._steps.map((step) => _stepRow(context, step)),
        ],
      );

  Widget _stepRow(BuildContext context, Map<String, dynamic> step) {
    final done = step['done'] as bool;
    return GestureDetector(
      onTap: done ? null : () => _navigate(context, step['action'] as String?),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: done
                ? Colors.green.withValues(alpha: 0.3)
                : const Color(0xFFDCE5ED),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // Emoji or check
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: done
                    ? Colors.green.withValues(alpha: 0.1)
                    : const Color(0xFFF5F0EB),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check_circle,
                        color: Colors.green, size: 22)
                    : Text(step['emoji'] as String,
                        style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step['title'] as String,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: done
                              ? const Color(0xFF7A8B9A)
                              : const Color(0xFF1A3A5C),
                          decoration:
                              done ? TextDecoration.lineThrough : null)),
                  Text(step['desc'] as String,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF7A8B9A))),
                ],
              ),
            ),
            if (!done && step['action'] != null)
              const Icon(Icons.chevron_right,
                  color: Color(0xFF7A8B9A), size: 20),
            if (done)
              const Text('Done',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green)),
          ],
        ),
      ),
    );
  }

  Widget _whatNextCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2E8B8B).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF2E8B8B).withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What happens next?',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1A3A5C))),
            const SizedBox(height: 12),
            _nextStep('1️⃣', 'Complete your profile above'),
            _nextStep('2️⃣', 'Borderline reviews & verifies your ID'),
            _nextStep('3️⃣', 'Your profile goes live to newcomers'),
            _nextStep('4️⃣', 'You start receiving help requests! 🎉'),
          ],
        ),
      );

  Widget _nextStep(String num, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Text(num, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF1A3A5C))),
            ),
          ],
        ),
      );

  void _navigate(BuildContext context, String? action) {
    if (action == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID verification is done by the Borderline team.'),
        ),
      );
      return;
    }
    if (action == 'edit_profile') {
      Navigator.push(context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()))
          .then((_) => onRefresh());
    } else if (action == 'set_price') {
      Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SetPriceScreen()))
          .then((_) => onRefresh());
    }
  }
}