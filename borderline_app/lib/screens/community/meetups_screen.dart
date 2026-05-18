import 'package:flutter/material.dart';
import '../../models/community_model.dart';
import '../../services/community_service.dart';
import '../../services/community_service_factory.dart';
import '../../utils/web_storage.dart';

class MeetupsScreen extends StatefulWidget {
  final CommunityService service;

  MeetupsScreen({super.key, CommunityService? service})
      : service = service ?? createCommunityService();

  @override
  State<MeetupsScreen> createState() => _MeetupsScreenState();
}

class _MeetupsScreenState extends State<MeetupsScreen> {
  List<Meetup> _meetups = [];
  bool _loading = true;
  String _city = '';
  bool _isHelper = false;

  @override
  void initState() {
    super.initState();
    _city = WebStorage.get('city');
    _isHelper = WebStorage.get('role') == 'helper';
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final meetups = await widget.service.getMeetups(city: _city);
    if (!mounted) return;
    setState(() {
      _meetups = meetups;
      _loading = false;
    });
  }

  Future<void> _toggleRSVP(int index) async {
    final meetup = _meetups[index];
    final result = await widget.service.toggleRSVP(meetup.id);
    if (!mounted || result == null) return;
    setState(() {
      _meetups[index] = meetup.copyWith(
        isAttending: result['attending'] as bool? ?? !meetup.isAttending,
        attendeeCount: result['attendee_count'] as int? ?? meetup.attendeeCount,
      );
    });
  }

  Map<String, List<Meetup>> _groupByDate() {
    final map = <String, List<Meetup>>{};
    for (final m in _meetups) {
      map.putIfAbsent(m.date, () => []).add(m);
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Map.fromEntries(sorted);
  }

  void _showCreateSheet() {
    final titleCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: _city);
    final locationCtrl = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create Meetup',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A5C))),
                const SizedBox(height: 16),
                _sheetField(titleCtrl, 'Title'),
                const SizedBox(height: 10),
                _sheetField(cityCtrl, 'City'),
                const SizedBox(height: 10),
                _sheetField(locationCtrl, 'Location / address'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(selectedDate == null
                            ? 'Pick date'
                            : '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (d != null) setModal(() => selectedDate = d);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text(selectedTime == null
                            ? 'Pick time'
                            : selectedTime!.format(ctx)),
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.now(),
                          );
                          if (t != null) setModal(() => selectedTime = t);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A3A5C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _fetch();
                    },
                    child: const Text('Create Meetup'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetField(TextEditingController ctrl, String hint) => TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF5F0EB),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Meetups',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            if (_city.isNotEmpty)
              Text(_city,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetch,
              child: _meetups.isEmpty
                  ? const Center(
                      child: Text('No meetups this week.',
                          style: TextStyle(color: Color(0xFF7A8B9A))))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: _groupByDate().entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(entry.key,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE8944A),
                                      fontSize: 13)),
                            ),
                            ...entry.value.map((m) {
                              final i = _meetups.indexOf(m);
                              return _buildMeetupCard(i);
                            }),
                          ],
                        );
                      }).toList(),
                    ),
            ),
      floatingActionButton: _isHelper
          ? FloatingActionButton(
              onPressed: _showCreateSheet,
              backgroundColor: const Color(0xFFE8944A),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildMeetupCard(int index) {
    final m = _meetups[index];
    final dateParts = m.date.split('-');
    final day = dateParts.length >= 3 ? dateParts[2] : m.date;
    final dt = DateTime.tryParse(m.date);
    final dayName = dt != null
        ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dt.weekday - 1]
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8944A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(day,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                        color: Color(0xFFE8944A))),
                Text(dayName,
                    style: const TextStyle(fontSize: 11, color: Color(0xFFE8944A))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.title,
                    style: const TextStyle(fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A5C), fontSize: 15)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 13,
                      color: Color(0xFF7A8B9A)),
                  const SizedBox(width: 2),
                  Expanded(child: Text(m.location,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF7A8B9A)))),
                ]),
                const SizedBox(height: 2),
                Text('by ${m.organizerName}  ·  ${m.attendeeCount} going',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF7A8B9A))),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _toggleRSVP(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: m.isAttending ? const Color(0xFF2E8B8B) : Colors.transparent,
                      border: Border.all(color: const Color(0xFF2E8B8B)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      m.isAttending ? 'Going' : 'Join',
                      style: TextStyle(
                          color: m.isAttending ? Colors.white : const Color(0xFF2E8B8B),
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
