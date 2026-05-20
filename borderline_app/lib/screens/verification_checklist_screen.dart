// lib/screens/verification_checklist_screen.dart
// A4 · Verification Checklist UI (Wireframe 2D)

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'edit_profile_screen.dart';
import 'set_price_screen.dart';

class VerificationChecklistScreen extends StatefulWidget {
  const VerificationChecklistScreen({super.key});

  @override
  State<VerificationChecklistScreen> createState() =>
      _VerificationChecklistScreenState();
}

class _VerificationChecklistScreenState
    extends State<VerificationChecklistScreen> {
  final _authService = AuthService();

  Map<String, dynamic>? _status;
  bool _isLoading = true;
  bool _isSubmitting = false;

  // ── colour palette (matches the rest of the app) ────────────────────────
  static const _navy   = Color(0xFF1A3A5C);
  static const _orange = Color(0xFFE8944A);
  static const _bg     = Color(0xFFF5F0EB);
  static const _muted  = Color(0xFF7A8B9A);
  static const _teal   = Color(0xFF2E8B8B);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _authService.getVerificationStatus();
      if (mounted) setState(() { _status = data; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── navigation per step route key ────────────────────────────────────────
  Future<void> _navigateTo(String route) async {
    Widget? screen;
    switch (route) {
      case 'edit_profile':
        screen = const EditProfileScreen();
        break;
      case 'set_price':
        screen = const SetPriceScreen();
        break;
      // 'verify_id' and 'intro_video' → future screens; show snackbar for now
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$route coming soon!'),
            backgroundColor: _navy,
          ),
        );
        return;
    }
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => screen!),
    );
    if (updated == true) _load();
  }

  Future<void> _submitForReview() async {
    setState(() => _isSubmitting = true);
    // TODO: wire to POST /users/me/submit-verification/ when backend is ready
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified_outlined, color: _teal),
            SizedBox(width: 8),
            Text('Submitted!', style: TextStyle(color: _navy)),
          ],
        ),
        content: const Text(
          'Your profile has been sent for review. '
          'The Borderline team will verify you within 1-2 business days.',
          style: TextStyle(color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(color: _teal)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _navy,
        title: const Text(
          'Get Verified',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _navy))
          : RefreshIndicator(
              onRefresh: _load,
              color: _orange,
              child: _status == null
                  ? _buildError()
                  : _buildContent(),
            ),
    );
  }

  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: _muted, size: 48),
            const SizedBox(height: 12),
            const Text('Could not load verification status.',
                style: TextStyle(color: _muted)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: _navy),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

  Widget _buildContent() {
    final steps         = _status!['steps'] as List<dynamic>;
    final completedCount = _status!['completed_count'] as int;
    final total          = _status!['total'] as int;
    final isVerified     = _status!['is_verified'] as bool;
    final readyToSubmit  = _status!['ready_to_submit'] as bool;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        // ── Header card ───────────────────────────────────────────────────
        _buildHeaderCard(completedCount, total, isVerified),
        const SizedBox(height: 24),

        // ── Section title ─────────────────────────────────────────────────
        const Text(
          'Verification Steps',
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.bold, color: _navy),
        ),
        const SizedBox(height: 4),
        const Text(
          'Complete all 5 steps so the Borderline team can review your profile.',
          style: TextStyle(fontSize: 13, color: _muted),
        ),
        const SizedBox(height: 16),

        // ── Steps ─────────────────────────────────────────────────────────
        ...steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step  = entry.value as Map<String, dynamic>;
          return _buildStepCard(step, index + 1);
        }),

        const SizedBox(height: 24),

        // ── Submit button ─────────────────────────────────────────────────
        if (!isVerified)
          _buildSubmitButton(readyToSubmit)
        else
          _buildVerifiedBanner(),
      ],
    );
  }

  // ── Header card with progress ring ───────────────────────────────────────

  Widget _buildHeaderCard(int completed, int total, bool isVerified) {
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, Color(0xFF2A5080)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: _navy.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Progress ring
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isVerified ? _teal : _orange,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$completed/$total',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                    const Text(
                      'done',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVerified
                      ? '✅ You\'re Verified!'
                      : completed == total
                          ? 'Ready for Review!'
                          : 'Almost There!',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  isVerified
                      ? 'Your profile is verified. Newcomers can find and trust you.'
                      : completed == total
                          ? 'All steps done — tap Submit below!'
                          : '${total - completed} step${total - completed > 1 ? 's' : ''} left before you can submit for verification.',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step card ─────────────────────────────────────────────────────────────

  Widget _buildStepCard(Map<String, dynamic> step, int index) {
    final completed = step['completed'] as bool;
    final route     = step['route'] as String;
    final sub       = step['sub'] as Map<String, dynamic>?;

    return GestureDetector(
      onTap: completed ? null : () => _navigateTo(route),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: completed
                ? _teal.withValues(alpha: 0.4)
                : const Color(0xFFDCE5ED),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Number / check circle
              _buildStepIndicator(index, completed),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            step['title'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: completed ? _teal : _navy,
                            ),
                          ),
                        ),
                        if (completed)
                          const Icon(Icons.verified_rounded,
                              color: _teal, size: 18)
                        else
                          const Icon(Icons.chevron_right,
                              color: _muted, size: 20),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      step['desc'] as String,
                      style: const TextStyle(fontSize: 12, color: _muted),
                    ),
                    // Sub-step indicators (photo + bio)
                    if (sub != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _subChip('Photo', sub['photo'] as bool),
                          const SizedBox(width: 8),
                          _subChip('Bio', sub['bio'] as bool),
                        ],
                      ),
                    ],
                    // Extra info
                    if (step['count'] != null && !completed) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${step['count']} selected so far',
                        style: const TextStyle(
                            fontSize: 11,
                            color: _orange,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                    if (step['current_rate'] != null && completed) ...[
                      const SizedBox(height: 6),
                      Text(
                        '€${step['current_rate']}/hr',
                        style: const TextStyle(
                            fontSize: 12,
                            color: _teal,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int index, bool completed) {
    if (completed) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _teal.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: _teal, size: 20),
      );
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _navy.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$index',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: _navy, fontSize: 15),
        ),
      ),
    );
  }

  Widget _subChip(String label, bool done) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: done
              ? _teal.withValues(alpha: 0.1)
              : _muted.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              size: 13,
              color: done ? _teal : _muted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: done ? _teal : _muted),
            ),
          ],
        ),
      );

  // ── Submit / verified footer ───────────────────────────────────────────────

  Widget _buildSubmitButton(bool readyToSubmit) => Column(
        children: [
          if (!readyToSubmit)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Complete all steps to unlock the submit button.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: _muted.withValues(alpha: 0.8)),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: readyToSubmit && !_isSubmitting
                  ? _submitForReview
                  : null,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: Text(
                _isSubmitting ? 'Submitting…' : 'Submit for Verification',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: readyToSubmit ? _teal : Colors.grey.shade300,
                foregroundColor: readyToSubmit ? Colors.white : _muted,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: readyToSubmit ? 3 : 0,
              ),
            ),
          ),
        ],
      );

  Widget _buildVerifiedBanner() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _teal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _teal.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.verified_rounded, color: _teal, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Profile Verified',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _teal,
                          fontSize: 15)),
                  SizedBox(height: 2),
                  Text(
                    'You appear as a verified helper to newcomers.',
                    style: TextStyle(fontSize: 12, color: _muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}