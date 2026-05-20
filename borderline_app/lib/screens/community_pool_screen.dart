import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

class CommunityPoolScreen extends StatefulWidget {
  const CommunityPoolScreen({super.key});

  @override
  State<CommunityPoolScreen> createState() => _CommunityPoolScreenState();
}

class _CommunityPoolScreenState extends State<CommunityPoolScreen> {
  final _svc = PaymentService();
  CommunityPool? _pool;
  bool _loading = true;
  bool _contributing = false;
  double _selectedAmount = 10.0;

  static const _amounts = [5.0, 10.0, 20.0, 50.0];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final pool = await _svc.getPool();
    if (!mounted) return;
    setState(() {
      _pool = pool;
      _loading = false;
    });
  }

  Future<void> _contribute() async {
    setState(() => _contributing = true);
    final ok = await _svc.contributeToPool(_selectedAmount);
    setState(() => _contributing = false);
    if (!mounted) return;
    if (ok) {
      await _load();
      _showThankYou();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not process. Try again.')));
    }
  }

  void _showThankYou() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Thank you!',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A5C))),
            const SizedBox(height: 8),
            Text(
              'You contributed €${_selectedAmount.toStringAsFixed(0)} to the community pool.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF7A8B9A)),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
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
        title: const Text('Community Pool',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Pool balance ──────────────────────────
                  _balanceCard(),
                  const SizedBox(height: 24),

                  // ── How it works ──────────────────────────
                  const Text('How it works',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3A5C))),
                  const SizedBox(height: 12),
                  _howItWorks(),
                  const SizedBox(height: 24),

                  // ── Contribute ────────────────────────────
                  const Text('Make a contribution',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3A5C))),
                  const SizedBox(height: 12),
                  _amountPicker(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _contributing ? null : _contribute,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E8B8B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _contributing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(
                              'Contribute €${_selectedAmount.toStringAsFixed(0)} 🌍',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _balanceCard() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E8B8B), Color(0xFF1A6B6B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Text('🌍', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            const Text('Community Pool Balance',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 6),
            Text(
              '€${(_pool?.balance ?? 0).toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Total donated: €${(_pool?.totalDonated ?? 0).toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
      );

  Widget _howItWorks() => Container(
        padding: const EdgeInsets.all(16),
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
          children: const [
            _HowItWorksItem(
              emoji: '💙',
              title: 'Helpers contribute',
              desc: 'Helpers and users donate to build a shared fund for newcomers in need.',
            ),
            SizedBox(height: 14),
            _HowItWorksItem(
              emoji: '🆓',
              title: 'Free sessions for newcomers',
              desc: 'Newcomers without funds can request a session paid from the pool.',
            ),
            SizedBox(height: 14),
            _HowItWorksItem(
              emoji: '🔍',
              title: 'Borderline verifies need',
              desc: 'Our team reviews each pool-funded request to ensure fair distribution.',
            ),
            SizedBox(height: 14),
            _HowItWorksItem(
              emoji: '✅',
              title: 'Helpers still get paid',
              desc: 'Pool covers 100% of the helper fee for approved free sessions.',
            ),
          ],
        ),
      );

  Widget _amountPicker() => Container(
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose amount',
                style: TextStyle(color: Color(0xFF7A8B9A), fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              children: _amounts.map((a) {
                final sel = _selectedAmount == a;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedAmount = a),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF2E8B8B)
                            : const Color(0xFFF5F0EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '€${a.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color:
                                  sel ? Colors.white : const Color(0xFF1A3A5C)),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
}

class _HowItWorksItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;

  const _HowItWorksItem({
    required this.emoji,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3A5C),
                      fontSize: 14)),
              const SizedBox(height: 2),
              Text(desc,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF7A8B9A))),
            ],
          ),
        ),
      ],
    );
  }
}