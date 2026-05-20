import 'package:flutter/material.dart';
import '../models/helper_model.dart';
import '../services/payment_service.dart';

class CheckoutScreen extends StatefulWidget {
  final HelpRequest request;
  final double amount;

  const CheckoutScreen({
    super.key,
    required this.request,
    required this.amount,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _paymentService = PaymentService();
  bool _paying = false;

  double get _platformFee => widget.amount * 0.15;

  final _packageLabels = const {
    'starter':    '2hr Starter',
    'half_day':   'Half Day',
    'first_week': 'First Week',
    'custom':     'Custom',
    '':           'Session',
  };

  Future<void> _pay() async {
    setState(() => _paying = true);
    final txn = await _paymentService.checkout(
      helpRequestId: widget.request.id,
      amount: widget.amount,
      note: 'Package: ${widget.request.package}',
    );
    setState(() => _paying = false);
    if (!mounted) return;
    if (txn != null) {
      _showSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment failed. Please try again.')));
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5), shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.green, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Payment Successful!',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A5C))),
            const SizedBox(height: 8),
            Text(
              'Your session with ${widget.request.helperName ?? 'your helper'} is confirmed.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF7A8B9A)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context, true); // return to previous screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8944A),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done', style: TextStyle(color: Colors.white)),
              ),
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
        title: const Text('Checkout',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Helper info ──────────────────────────
                _helperCard(),
                const SizedBox(height: 20),

                // ── Breakdown ────────────────────────────
                _sectionTitle('Payment Breakdown'),
                const SizedBox(height: 10),
                _breakdownCard(),
              ],
            ),
          ),

          // ── Pay button ───────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _paying ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8944A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _paying
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        'Pay €${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C)),
      );

  Widget _helperCard() => Container(
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
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  const Color(0xFFE8944A).withValues(alpha: 0.15),
              child: Text(
                (widget.request.helperName?.isNotEmpty == true)
                    ? widget.request.helperName![0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE8944A)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.request.helperName ?? 'Your Helper',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1A3A5C)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.request.category,
                    style: const TextStyle(
                        color: Color(0xFF7A8B9A), fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF1A3A5C).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _packageLabels[widget.request.package] ?? widget.request.package,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A3A5C)),
              ),
            ),
          ],
        ),
      );

  Widget _breakdownCard() => Container(
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
          children: [
            _lineItem('Session fee', '€${widget.amount.toStringAsFixed(2)}'),
            const Divider(height: 20),
            _lineItem(
              'Platform fee (15%)',
              '€${_platformFee.toStringAsFixed(2)}',
              sub: true,
            ),
            _lineItem(
              'Helper receives',
              '€${(widget.amount - _platformFee).toStringAsFixed(2)}',
              sub: true,
              green: true,
            ),
          ],
        ),
      );

  Widget _lineItem(String label, String value,
      {bool sub = false, bool green = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: sub ? const Color(0xFF7A8B9A) : const Color(0xFF1A3A5C),
                    fontSize: sub ? 13 : 15)),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: green ? Colors.green : const Color(0xFF1A3A5C),
                    fontSize: sub ? 13 : 15)),
          ],
        ),
      );
}