import 'package:flutter/material.dart';
import '../../models/helper_model.dart';

class CalendarTab extends StatefulWidget {
  final List<HelpRequest> requests;

  const CalendarTab({super.key, required this.requests});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime _focusedMonth = DateTime.now();

  DateTime get _today => DateTime.now();

  // Sessions that are accepted or done (= booked days)
  Set<int> get _bookedDays {
    final days = <int>{};
    for (final r in widget.requests) {
      if (r.status == 'accepted' || r.status == 'done') {
        try {
          final d = DateTime.parse(r.createdAt);
          if (d.year == _focusedMonth.year && d.month == _focusedMonth.month) {
            days.add(d.day);
          }
        } catch (_) {}
      }
    }
    return days;
  }

  List<HelpRequest> get _thisWeek {
    final now = _today;
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return widget.requests.where((r) {
      try {
        final d = DateTime.parse(r.createdAt);
        return !d.isBefore(startOfWeek) && !d.isAfter(endOfWeek) &&
            (r.status == 'accepted' || r.status == 'pending');
      } catch (_) {
        return false;
      }
    }).toList();
  }

  void _prevMonth() => setState(() {
        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
      });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _calendarCard(),
        const SizedBox(height: 20),
        _thisWeekSection(),
      ],
    );
  }

  Widget _calendarCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            // ── Month nav ─────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Color(0xFF1A3A5C)),
                  onPressed: _prevMonth,
                ),
                Text(
                  _monthLabel(_focusedMonth),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3A5C)),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Color(0xFF1A3A5C)),
                  onPressed: _nextMonth,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Day-of-week headers ───────────────────────
            Row(
              children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(d,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF7A8B9A))),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),

            // ── Day grid ──────────────────────────────────
            _buildGrid(),
            const SizedBox(height: 12),

            // ── Legend ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(const Color(0xFFE8944A), 'Booked'),
                const SizedBox(width: 16),
                _legendDot(const Color(0xFF1A3A5C), 'Today'),
              ],
            ),
          ],
        ),
      );

  Widget _buildGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    // weekday: Mon=1 … Sun=7
    final startOffset = firstDay.weekday - 1;
    final booked = _bookedDays;

    final cells = <Widget>[];

    // Empty cells before day 1
    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final isToday = _today.year == _focusedMonth.year &&
          _today.month == _focusedMonth.month &&
          _today.day == day;
      final isBooked = booked.contains(day);

      cells.add(_dayCell(day, isToday: isToday, isBooked: isBooked));
    }

    // Fill remaining cells to complete last row
    while (cells.length % 7 != 0) {
      cells.add(const SizedBox());
    }

    final rows = <Widget>[];
    for (int i = 0; i < cells.length; i += 7) {
      rows.add(Row(
        children: cells.sublist(i, i + 7).map((c) => Expanded(child: c)).toList(),
      ));
      rows.add(const SizedBox(height: 6));
    }
    return Column(children: rows);
  }

  Widget _dayCell(int day, {bool isToday = false, bool isBooked = false}) {
    Color? bg;
    Color textColor = const Color(0xFF1A3A5C);

    if (isToday) {
      bg = const Color(0xFF1A3A5C);
      textColor = Colors.white;
    } else if (isBooked) {
      bg = const Color(0xFFE8944A);
      textColor = Colors.white;
    }

    return Container(
      margin: const EdgeInsets.all(2),
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          day.toString(),
          style: TextStyle(
              fontSize: 13,
              fontWeight: isToday || isBooked ? FontWeight.bold : FontWeight.normal,
              color: textColor),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) => Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF7A8B9A))),
        ],
      );

  Widget _thisWeekSection() {
    final list = _thisWeek;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('This Week',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3A5C))),
        const SizedBox(height: 10),
        if (list.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.event_available_outlined,
                    color: Color(0xFFDCE5ED), size: 28),
                SizedBox(width: 12),
                Text('No sessions this week',
                    style: TextStyle(color: Color(0xFF7A8B9A))),
              ],
            ),
          )
        else
          ...list.map(_weekRow),
      ],
    );
  }

  Widget _weekRow(HelpRequest req) {
    DateTime? d;
    try {
      d = DateTime.parse(req.createdAt);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
          // Date badge
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8944A).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  d != null ? _shortDay(d.weekday) : '--',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE8944A)),
                ),
                Text(
                  d != null ? d.day.toString() : '--',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE8944A)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(req.newcomerName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A5C))),
                Text(req.category,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF7A8B9A))),
              ],
            ),
          ),
          _statusChip(req.status),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final map = {
      'pending':  [const Color(0xFFFFF3CD), const Color(0xFF856404)],
      'accepted': [const Color(0xFFD1FAE5), Colors.green.shade800],
    };
    final pair = map[status] ?? map['pending']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: pair[0], borderRadius: BorderRadius.circular(20)),
      child: Text(status,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: pair[1])),
    );
  }

  String _monthLabel(DateTime d) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[d.month]} ${d.year}';
  }

  String _shortDay(int weekday) {
    const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday];
  }
}