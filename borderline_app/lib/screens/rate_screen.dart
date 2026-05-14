import 'package:flutter/material.dart';
import '../models/helper_model.dart';
import '../services/auth_service.dart';

class RateScreen extends StatefulWidget {
  final Helper helper;

  const RateScreen({super.key, required this.helper});

  @override
  State<RateScreen> createState() => _RateScreenState();
}

class _RateScreenState extends State<RateScreen> {
  final _authService = AuthService();
  final _noteCtrl = TextEditingController();

  int _rating = 0;
  final List<String> _selectedTags = [];
  bool _isLoading = false;

  static const _tags = [
    'patient', 'knowledgeable', 'friendly', 'on time',
    'good listener', 'resourceful', 'warm', 'professional',
  ];

  Helper get h => widget.helper;

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a star rating.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.submitReview(
      userId: h.id,
      rating: _rating,
      tags: _selectedTags,
      note: _noteCtrl.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted! Thank you.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit review. You may have already reviewed this helper.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        foregroundColor: Colors.white,
        title: const Text('Leave a Review', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelperHeader(),
            const SizedBox(height: 32),
            _buildRatingSection(),
            const SizedBox(height: 28),
            _buildTagSection(),
            const SizedBox(height: 28),
            _buildNoteSection(),
            const SizedBox(height: 36),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHelperHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFE8944A).withValues(alpha: 0.2),
            child: Text(
              h.firstName.isNotEmpty ? h.firstName[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFE8944A)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.fullName,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
                const SizedBox(height: 2),
                Text(
                  h.city.isNotEmpty ? h.city : 'Local Helper',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF7A8B9A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('How was it?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final starIndex = i + 1;
            return GestureDetector(
              onTap: () => setState(() => _rating = starIndex),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.star_rounded,
                    key: ValueKey('$starIndex-${starIndex <= _rating}'),
                    size: 48,
                    color: starIndex <= _rating ? Colors.amber : const Color(0xFFDCE5ED),
                  ),
                ),
              ),
            );
          }),
        ),
        if (_rating > 0)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Center(
              child: Text(
                ['', 'Needs improvement', 'It was ok', 'Pretty good', 'Very good', 'The best!'][_rating],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _rating >= 4 ? Colors.green : const Color(0xFFE8944A),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTagSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What stood out?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
        const SizedBox(height: 6),
        const Text('Select all that apply (optional)',
            style: TextStyle(fontSize: 12, color: Color(0xFF7A8B9A))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tags.map((tag) {
            final selected = _selectedTags.contains(tag);
            return GestureDetector(
              onTap: () => setState(() {
                if (selected) {
                  _selectedTags.remove(tag);
                } else {
                  _selectedTags.add(tag);
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF1A3A5C) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? const Color(0xFF1A3A5C) : const Color(0xFFDCE5ED),
                  ),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : const Color(0xFF4A5568),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNoteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Write a note',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
        const SizedBox(height: 6),
        const Text('Optional — your words will be visible on their profile',
            style: TextStyle(fontSize: 12, color: Color(0xFF7A8B9A))),
        const SizedBox(height: 12),
        TextFormField(
          controller: _noteCtrl,
          maxLines: 4,
          maxLength: 300,
          decoration: InputDecoration(
            hintText: '"Reza literally saved my first week..."',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDCE5ED))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDCE5ED))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1A3A5C), width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE8944A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Post Review',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }
}
