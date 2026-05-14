import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../data/world_data.dart';

class LanguageSelector extends StatefulWidget {
  final List<String> selected;
  final void Function(List<String>) onChanged;

  const LanguageSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  final _controller = TextEditingController();

  void _add(String lang) {
    if (lang.trim().isEmpty) return;
    final normalized = lang.trim();
    if (!widget.selected.contains(normalized)) {
      final updated = [...widget.selected, normalized];
      widget.onChanged(updated);
    }
    _controller.clear();
  }

  void _remove(String lang) {
    final updated = widget.selected.where((l) => l != lang).toList();
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Languages you speak',
            style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C)),
          ),
        ),

        // Selected chips
        if (widget.selected.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: widget.selected
                .map((lang) => Chip(
                      label: Text(lang, style: const TextStyle(fontSize: 13)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _remove(lang),
                      backgroundColor: const Color(0xFF1A3A5C).withValues(alpha: 0.1),
                      labelStyle: const TextStyle(color: Color(0xFF1A3A5C)),
                      deleteIconColor: const Color(0xFF1A3A5C),
                      side: BorderSide.none,
                    ))
                .toList(),
          ),

        const SizedBox(height: 8),

        // Typeahead input
        TypeAheadField<String>(
          controller: _controller,
          suggestionsCallback: WorldData.searchLanguages,
          builder: (context, ctrl, focusNode) => TextField(
            controller: ctrl,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: 'Add a language...',
              prefixIcon: const Icon(Icons.language, color: Color(0xFF7A8B9A)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFFE8944A)),
                onPressed: () => _add(_controller.text),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            onSubmitted: _add,
          ),
          itemBuilder: (context, suggestion) => ListTile(
            leading: const Icon(Icons.language, color: Color(0xFF7A8B9A), size: 18),
            title: Text(suggestion, style: const TextStyle(fontSize: 14)),
            dense: true,
          ),
          onSelected: _add,
          decorationBuilder: (context, child) => Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: child,
          ),
          offset: const Offset(0, 4),
          constraints: const BoxConstraints(maxHeight: 220),
          emptyBuilder: (context) => const Padding(
            padding: EdgeInsets.all(12),
            child: Text('No suggestions', style: TextStyle(color: Color(0xFF7A8B9A))),
          ),
        ),

        const SizedBox(height: 6),
        const Text(
          'Tap a suggestion or press Enter to add',
          style: TextStyle(fontSize: 11, color: Color(0xFF7A8B9A)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
