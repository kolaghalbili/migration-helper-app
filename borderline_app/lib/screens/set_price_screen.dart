import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SetPriceScreen extends StatefulWidget {
  const SetPriceScreen({super.key});

  @override
  State<SetPriceScreen> createState() => _SetPriceScreenState();
}

class _SetPriceScreenState extends State<SetPriceScreen> {
  final _auth = AuthService();

  String _mode = 'hourly'; // free | hourly | package
  double _hourlyRate = 25.0;
  bool _saving = false;

  // Package prices (fixed tiers)
  final _packages = [
    {'key': 'starter',    'label': '2hr Starter',  'hours': 2,  'price': 40.0,  'icon': '🚀'},
    {'key': 'half_day',   'label': 'Half Day',      'hours': 4,  'price': 70.0,  'icon': '☀️'},
    {'key': 'first_week', 'label': 'First Week',    'hours': 10, 'price': 150.0, 'icon': '📅'},
  ];

  Future<void> _save() async {
    setState(() => _saving = true);
    double? rate;
    if (_mode == 'hourly') rate = _hourlyRate;
    if (_mode == 'package') rate = _hourlyRate; // packages use hourly as base

    // PATCH /api/me/  (auth_service already has updateProfile)
    final ok = await _auth.updateProfile(hourlyRate: _mode == 'free' ? null : rate);
    setState(() => _saving = false);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Rate saved ✓')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to save. Try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        title: const Text('Set Your Rate',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Mode selector ────────────────────────────
          _sectionTitle('How do you want to charge?'),
          const SizedBox(height: 12),
          _modeCard('free',    '🤝', 'Volunteer',
              'Help newcomers for free. You can always change this later.'),
          const SizedBox(height: 10),
          _modeCard('hourly',  '⏱️', 'Hourly Rate',
              'Set an hourly rate. Newcomers pay per session.'),
          const SizedBox(height: 10),
          _modeCard('package', '📦', 'Packages',
              'Offer preset bundles with clear pricing.'),

          const SizedBox(height: 28),

          // ── Hourly slider ────────────────────────────
          if (_mode == 'hourly') ...[
            _sectionTitle('Your hourly rate'),
            const SizedBox(height: 8),
            _rateSlider(),
            const SizedBox(height: 28),
          ],

          // ── Package list ─────────────────────────────
          if (_mode == 'package') ...[
            _sectionTitle('Available packages'),
            const SizedBox(height: 8),
            ..._packages.map(_packageRow),
            const SizedBox(height: 8),
            const Text(
              'Packages are calculated from your base hourly rate above.',
              style: TextStyle(fontSize: 12, color: Color(0xFF7A8B9A)),
            ),
            const SizedBox(height: 28),
          ],

          // ── Platform fee note ─────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3A5C).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, size: 18, color: Color(0xFF1A3A5C)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Borderline keeps 15% platform fee. You receive 85% of each payment.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF1A3A5C)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Save button ───────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8944A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save Rate',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C)),
      );

  Widget _modeCard(String key, String emoji, String title, String desc) {
    final selected = _mode == key;
    return GestureDetector(
      onTap: () => setState(() => _mode = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A3A5C) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF1A3A5C) : const Color(0xFFDCE5ED),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(
                  color: const Color(0xFF1A3A5C).withValues(alpha: 0.15),
                  blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: selected ? Colors.white : const Color(0xFF1A3A5C))),
                  const SizedBox(height: 2),
                  Text(desc,
                      style: TextStyle(
                          fontSize: 12,
                          color: selected
                              ? Colors.white.withValues(alpha: 0.75)
                              : const Color(0xFF7A8B9A))),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Color(0xFFE8944A)),
          ],
        ),
      ),
    );
  }

  Widget _rateSlider() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '€${_hourlyRate.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A5C)),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(' / hour',
                    style: TextStyle(color: Color(0xFF7A8B9A), fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFE8944A),
              thumbColor: const Color(0xFFE8944A),
              inactiveTrackColor: const Color(0xFFDCE5ED),
              overlayColor: const Color(0xFFE8944A).withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _hourlyRate,
              min: 10,
              max: 100,
              divisions: 18,
              onChanged: (v) => setState(() => _hourlyRate = v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('€10', style: TextStyle(color: Color(0xFF7A8B9A), fontSize: 12)),
              Text('€100', style: TextStyle(color: Color(0xFF7A8B9A), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'You earn: €${(_hourlyRate * 0.85).toStringAsFixed(0)} / hour after fees',
              style: const TextStyle(
                  color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _packageRow(Map<String, dynamic> pkg) {
    final price = pkg['price'] as double;
    final earn = price * 0.85;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE5ED)),
      ),
      child: Row(
        children: [
          Text(pkg['icon'] as String, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pkg['label'] as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
                Text('${pkg['hours']} hours · You earn €${earn.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF7A8B9A))),
              ],
            ),
          ),
          Text('€${price.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFFE8944A))),
        ],
      ),
    );
  }
}