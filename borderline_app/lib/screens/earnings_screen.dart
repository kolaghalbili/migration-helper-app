import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final _svc = PaymentService();
  List<MonthlyEarning> _earnings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _svc.getEarnings();
    if (!mounted) return;
    setState(() {
      _earnings = data;
      _loading = false;
    });
  }

  double get _currentMonthNet {
    final now = DateTime.now();
    return _earnings
        .where((e) => e.year == now.year && e.month == now.month)
        .fold(0.0, (s, e) => s + e.totalNet);
  }

  double get _currentMonthTips {
    final now = DateTime.now();
    return _earnings
        .where((e) => e.year == now.year && e.month == now.month)
        .fold(0.0, (s, e) => s + e.totalTips);
  }

  double get _maxNet =>
      _earnings.isEmpty ? 1 : _earnings.map((e) => e.totalNet).reduce((a, b) => a > b ? a : b);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        title: const Text('My Earnings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _earnings.isEmpty ? _emptyState() : _content(),
            ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('💰', style: TextStyle(fontSize: 56)),
            SizedBox(height: 16),
            Text('No earnings yet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A5C))),
            SizedBox(height: 8),
            Text('Complete your first session to start earning.',
                style: TextStyle(color: Color(0xFF7A8B9A))),
          ],
        ),
      );

  Widget _content() => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── This month summary ────────────────────────
          _summaryCard(),
          const SizedBox(height: 24),

          // ── Bar chart ─────────────────────────────────
          const Text('Monthly Earnings',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A5C))),
          const SizedBox(height: 12),
          _barChart(),
          const SizedBox(height: 24),

          // ── Payout list ───────────────────────────────
          const Text('Payout History',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A5C))),
          const SizedBox(height: 12),
          ..._earnings.map(_payoutRow),
        ],
      );

  Widget _summaryCard() => Container(
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
            const Text('This Month',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              '€${_currentMonthNet.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _miniStat('Tips', '€${_currentMonthTips.toStringAsFixed(0)}', '🙏'),
                const SizedBox(width: 16),
                _miniStat(
                  'Sessions',
                  _earnings
                      .where((e) {
                        final now = DateTime.now();
                        return e.year == now.year && e.month == now.month;
                      })
                      .fold(0, (s, e) => s + e.sessionCount)
                      .toString(),
                  '🤝',
                ),
              ],
            ),
          ],
        ),
      );

  Widget _miniStat(String label, String value, String emoji) => Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              Text(label,
                  style: const TextStyle(color: Colors.white60, fontSize: 11)),
            ],
          ),
        ],
      );

  Widget _barChart() {
    final last6 = _earnings.take(6).toList().reversed.toList();
    return Container(
      height: 160,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: last6.map((e) {
          final ratio = _maxNet > 0 ? e.totalNet / _maxNet : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('€${e.totalNet.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 9, color: Color(0xFF7A8B9A))),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    height: (110 * ratio).clamp(4.0, 110.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8944A),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(e.monthName,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF7A8B9A))),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _payoutRow(MonthlyEarning e) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8944A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('💸', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${e.monthName} ${e.year}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3A5C))),
                  Text('${e.sessionCount} sessions · €${e.totalTips.toStringAsFixed(0)} tips',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF7A8B9A))),
                ],
              ),
            ),
            Text(
              '€${e.totalNet.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1A3A5C)),
            ),
          ],
        ),
      );
}