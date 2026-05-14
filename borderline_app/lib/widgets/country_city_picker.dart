import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../data/world_data.dart';

class CountryCityPicker extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool searchCountriesOnly;
  final String? Function(String?)? validator;
  final void Function(String)? onSelected;

  const CountryCityPicker({
    super.key,
    required this.controller,
    required this.label,
    this.hint = 'Start typing...',
    this.searchCountriesOnly = false,
    this.validator,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        TypeAheadField<String>(
          controller: controller,
          suggestionsCallback: (pattern) => searchCountriesOnly
              ? WorldData.searchCountries(pattern)
              : WorldData.searchLocations(pattern),
          builder: (context, ctrl, focusNode) => TextFormField(
            controller: ctrl,
            focusNode: focusNode,
            decoration: _decor(hint, Icons.location_on_outlined),
            validator: validator,
          ),
          itemBuilder: (context, suggestion) => ListTile(
            leading: const Icon(Icons.location_on_outlined, color: Color(0xFF7A8B9A), size: 18),
            title: Text(suggestion, style: const TextStyle(fontSize: 14)),
            dense: true,
          ),
          onSelected: (suggestion) {
            final parts = suggestion.split(', ');
            controller.text = parts.first;
            onSelected?.call(suggestion);
          },
          decorationBuilder: (context, child) => Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: child,
          ),
          offset: const Offset(0, 4),
          constraints: const BoxConstraints(maxHeight: 240),
          emptyBuilder: (context) => const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'No suggestions — you can still type any city name',
              style: TextStyle(color: Color(0xFF7A8B9A), fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}

InputDecoration _decor(String hint, IconData icon) => InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF7A8B9A)),
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
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red)),
    );

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C)),
        ),
      );
}
