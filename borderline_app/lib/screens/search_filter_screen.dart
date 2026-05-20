import 'package:flutter/material.dart';
import '../models/filter_params.dart';

class SearchFilterScreen extends StatefulWidget {
  final FilterParams initial;
  final int totalHelpers;
  final List<String> categories;

  const SearchFilterScreen({
    super.key,
    required this.initial,
    required this.totalHelpers,
    required this.categories,
  });

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  late FilterParams _params;
  late TextEditingController _cityController;

  static const _primary = Color(0xFF1A3A5C);
  static const _accent  = Color(0xFFE8944A);
  static const _bg      = Color(0xFFF5F0EB);

  @override
  void initState() {
    super.initState();
    _params = widget.initial;
    _cityController = TextEditingController(text: widget.initial.city);
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _params = FilterParams.defaults;
      _cityController.text = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Filters',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _reset,
            child: const Text('Reset',
                style: TextStyle(color: Colors.white, fontSize: 15)),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _params),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Show ${widget.totalHelpers} helpers →',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section(_buildCity()),
            const Divider(height: 1),
            _section(_buildCategories()),
            const Divider(height: 1),
            _section(_buildNationalityMatch()),
            const Divider(height: 1),
            _section(_buildLanguage()),
            const Divider(height: 1),
            _section(_buildPrice()),
            const Divider(height: 1),
            _section(_buildMinRating()),
            const Divider(height: 1),
            _section(_buildVerifiedOnly()),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: child,
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _primary)),
      );

  // ── SECTION 1: City ───────────────────────────────────────────────────────

  Widget _buildCity() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('City'),
          TextField(
            controller: _cityController,
            onChanged: (v) => setState(() => _params = _params.copyWith(city: v)),
            decoration: InputDecoration(
              hintText: 'e.g. Berlin',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      );

  // ── SECTION 2: Categories ─────────────────────────────────────────────────

  Widget _buildCategories() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('I need help with'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.categories.map((cat) {
              final selected = _params.selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _params = _params.copyWith(
                      selectedCategory: selected ? '' : cat,
                    )),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? _accent : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? _accent : _primary,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: selected ? Colors.white : _primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );

  // ── SECTION 3: Nationality match ──────────────────────────────────────────

  Widget _buildNationalityMatch() {
    const options = [
      ('same',   'Same as mine'),
      ('arabic', 'Arabic speakers'),
      ('any',    'Any'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Nationality match'),
        Row(
          children: options.map((opt) {
            final (value, label) = opt;
            final selected = _params.nationalityMatch == value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(
                    () => _params = _params.copyWith(nationalityMatch: value)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? _primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _primary),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : _primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── SECTION 4: Language ───────────────────────────────────────────────────

  Widget _buildLanguage() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Languages'),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Speaks my language(s)',
                  style: const TextStyle(
                      color: _primary, fontWeight: FontWeight.w500),
                ),
              ),
              Switch(
                value: _params.languageMatch,
                activeThumbColor: _accent,
                activeTrackColor: _accent.withValues(alpha: 0.4),
                onChanged: (v) =>
                    setState(() => _params = _params.copyWith(languageMatch: v)),
              ),
            ],
          ),
        ],
      );

  // ── SECTION 5: Price ──────────────────────────────────────────────────────

  Widget _buildPrice() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _label('Max rate')),
              Text(
                _params.maxRate >= 200
                    ? 'Any'
                    : '€${_params.maxRate.toInt()}/h',
                style: const TextStyle(
                    color: _accent, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: _params.maxRate,
            min: 0,
            max: 200,
            divisions: 20,
            activeColor: _accent,
            onChanged: (v) =>
                setState(() => _params = _params.copyWith(maxRate: v)),
          ),
        ],
      );

  // ── SECTION 6: Min rating ─────────────────────────────────────────────────

  Widget _buildMinRating() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Minimum rating'),
          Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              final selected = _params.minRating >= star;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _params = _params.copyWith(
                        minRating: _params.minRating == star.toDouble()
                            ? 0
                            : star.toDouble(),
                      )),
                  child: Container(
                    margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? Colors.amber : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: selected
                              ? Colors.amber
                              : const Color(0xFFDCE5ED)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.star,
                            size: 18,
                            color: selected ? Colors.white : Colors.amber),
                        Text('$star',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : _primary)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      );

  // ── SECTION 7: Verified only ──────────────────────────────────────────────

  Widget _buildVerifiedOnly() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Verified helpers'),
          Row(
            children: [
              const Icon(Icons.verified_outlined, color: _primary, size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Verified helpers only',
                    style: TextStyle(
                        color: _primary, fontWeight: FontWeight.w500)),
              ),
              Switch(
                value: _params.verifiedOnly,
                activeThumbColor: _accent,
                activeTrackColor: _accent.withValues(alpha: 0.4),
                onChanged: (v) => setState(
                    () => _params = _params.copyWith(verifiedOnly: v)),
              ),
            ],
          ),
        ],
      );
}
