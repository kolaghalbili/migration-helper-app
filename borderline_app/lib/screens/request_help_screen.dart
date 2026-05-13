import 'package:flutter/material.dart';

class RequestHelpScreen extends StatefulWidget {
  const RequestHelpScreen({super.key});

  @override
  State<RequestHelpScreen> createState() => _RequestHelpScreenState();
}

class _RequestHelpScreenState extends State<RequestHelpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();

  String? _selectedCategory;
  String _mode = 'guided'; // 'guided' or 'free'
  bool _isLoading = false;

  final List<Map<String, String>> _categories = [
    {'name': 'Banking', 'icon': '🏦'},
    {'name': 'Housing', 'icon': '🏠'},
    {'name': 'SIM Card', 'icon': '📱'},
    {'name': 'Legal & Documents', 'icon': '📄'},
    {'name': 'Healthcare', 'icon': '🏥'},
    {'name': 'Language Support', 'icon': '💬'},
    {'name': 'Job Search', 'icon': '💼'},
    {'name': 'General Guidance', 'icon': '🧭'},
  ];

  // Guided mode questions
  final Map<String, List<String>> _guidedQuestions = {
    'Banking': ['Open a bank account', 'Transfer money abroad', 'Get a credit card', 'Online banking setup'],
    'Housing': ['Find an apartment', 'Understand rental contract', 'Register my address', 'Utility setup'],
    'SIM Card': ['Buy a SIM card', 'Set up mobile data', 'International calling', 'Switch provider'],
    'Legal & Documents': ['Residence permit', 'Work permit', 'Tax registration', 'Health insurance'],
    'Healthcare': ['Find a doctor', 'Health insurance', 'Emergency services', 'Pharmacy'],
    'Language Support': ['Translation help', 'Language classes', 'Document translation', 'Phone call support'],
    'Job Search': ['Write a CV', 'Job interview prep', 'Work permit info', 'Find job listings'],
    'General Guidance': ['Orientation tour', 'Local tips', 'Cultural guidance', 'Transport & maps'],
  };

  List<String> _selectedSubTopics = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        foregroundColor: Colors.white,
        title: const Text('Request Help', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text('What do you need help with?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
              const SizedBox(height: 6),
              const Text('Choose a category and describe your situation.',
                  style: TextStyle(color: Color(0xFF7A8B9A))),

              const SizedBox(height: 24),

              // Category grid
              const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _categories.length,
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final selected = _selectedCategory == cat['name'];
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedCategory = cat['name'];
                      _selectedSubTopics = [];
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF1A3A5C) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? const Color(0xFF1A3A5C) : const Color(0xFFDCE5ED),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(cat['icon']!, style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(
                            cat['name']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : const Color(0xFF1A3A5C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Mode toggle
              const Text('How would you like to describe your need?',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
              const SizedBox(height: 12),
              Row(
                children: [
                  _modeButton('guided', '📋 Guided Form'),
                  const SizedBox(width: 12),
                  _modeButton('free', '✏️ Free Text'),
                ],
              ),

              const SizedBox(height: 20),

              // Guided mode
              if (_mode == 'guided' && _selectedCategory != null) ...[
                const Text('Select what you need:',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (_guidedQuestions[_selectedCategory] ?? []).map((q) {
                    final selected = _selectedSubTopics.contains(q);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (selected) {
                          _selectedSubTopics.remove(q);
                        } else {
                          _selectedSubTopics.add(q);
                        }
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFFE8944A) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? const Color(0xFFE8944A) : const Color(0xFFDCE5ED),
                          ),
                        ),
                        child: Text(q,
                            style: TextStyle(
                              color: selected ? Colors.white : const Color(0xFF1A3A5C),
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            )),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Free text mode
              if (_mode == 'free') ...[
                const Text('Describe your situation:',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'e.g. I just arrived in Vienna and need help opening a bank account...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFDCE5ED)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFDCE5ED)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1A3A5C), width: 2),
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Please describe your need' : null,
                ),
              ],

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8944A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Find Matching Helpers →',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeButton(String mode, String label) {
    final selected = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1A3A5C) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A3A5C), width: 1.5),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF1A3A5C),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              )),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category first.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (_mode == 'guided' && _selectedSubTopics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one topic.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (_mode == 'free' && !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate loading
    Future.delayed(const Duration(seconds: 1), () {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request sent! Looking for $_selectedCategory helpers...'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }
}