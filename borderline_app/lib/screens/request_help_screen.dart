import 'package:flutter/material.dart';
import '../models/helper_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class RequestHelpScreen extends StatefulWidget {
  final Helper? helper;

  const RequestHelpScreen({super.key, this.helper});

  @override
  State<RequestHelpScreen> createState() => _RequestHelpScreenState();
}

class _RequestHelpScreenState extends State<RequestHelpScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();

  String? _selectedCategory;
  String _mode = 'guided';
  String _selectedPackage = 'starter';
  bool _isLoading = false;
  List<String> _selectedSubTopics = [];

  static const _categories = [
    {'name': 'Banking',          'icon': '🏦'},
    {'name': 'Housing',          'icon': '🏠'},
    {'name': 'SIM Card',         'icon': '📱'},
    {'name': 'Legal & Documents','icon': '📄'},
    {'name': 'Healthcare',       'icon': '🏥'},
    {'name': 'Language Support', 'icon': '💬'},
    {'name': 'Job Search',       'icon': '💼'},
    {'name': 'General Guidance', 'icon': '🧭'},
  ];

  static const _guidedQuestions = {
    'Banking':           ['Open a bank account', 'Transfer money abroad', 'Get a credit card', 'Online banking setup'],
    'Housing':           ['Find an apartment', 'Understand rental contract', 'Register my address', 'Utility setup'],
    'SIM Card':          ['Buy a SIM card', 'Set up mobile data', 'International calling', 'Switch provider'],
    'Legal & Documents': ['Residence permit', 'Work permit', 'Tax registration', 'Health insurance'],
    'Healthcare':        ['Find a doctor', 'Health insurance', 'Emergency services', 'Pharmacy'],
    'Language Support':  ['Translation help', 'Language classes', 'Document translation', 'Phone call support'],
    'Job Search':        ['Write a CV', 'Job interview prep', 'Work permit info', 'Find job listings'],
    'General Guidance':  ['Orientation tour', 'Local tips', 'Cultural guidance', 'Transport & maps'],
  };

  static const _packages = [
    {'value': 'starter',    'label': '2hr Starter',  'price': '€30',  'desc': 'Coffee + one errand'},
    {'value': 'half_day',   'label': 'Half Day',     'price': '€60',  'desc': 'Bank + SIM + one task'},
    {'value': 'first_week', 'label': 'First Week',   'price': '€180', 'desc': 'Unlimited, 5 days'},
    {'value': 'custom',     'label': 'Custom Hours', 'price': '/hr',  'desc': 'You decide the scope'},
  ];

  Future<void> _handleSubmit() async {
    if (_selectedCategory == null) {
      _snack('Please select a category first.', isError: true);
      return;
    }
    if (_mode == 'guided' && _selectedSubTopics.isEmpty) {
      _snack('Please select at least one topic.', isError: true);
      return;
    }
    if (_mode == 'free' && !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final description = _mode == 'guided'
        ? _selectedSubTopics.join(', ')
        : _descController.text.trim();

    final result = await _authService.createHelpRequest(
      category:    _selectedCategory!,
      subTopics:   _mode == 'guided' ? _selectedSubTopics : [],
      description: description,
      package:     _selectedPackage,
      helperId:    widget.helper?.id,
    );

    if (!mounted) return;

    if (result == null) {
      setState(() => _isLoading = false);
      _snack('Failed to submit request. Please try again.', isError: true);
      return;
    }

    // If a specific helper is selected, open a chat with a booking context message
    if (widget.helper != null) {
      final me = await _authService.getMe();
      final conversation = await ChatService().getOrCreateConversation(widget.helper!.id);
      setState(() => _isLoading = false);
      if (!mounted) return;
      if (conversation != null && me != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: conversation['id'],
              helperName: widget.helper!.fullName,
              currentUserId: me['id'],
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = false);
    _snack('Request submitted! Helpers will reach out soon.', isError: false);
    Navigator.pop(context, true);
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
    ));
  }

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
              if (widget.helper != null) _buildHelperBadge(),
              const Text('What do you need help with?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
              const SizedBox(height: 6),
              const Text('Choose a category and describe your situation.',
                  style: TextStyle(color: Color(0xFF7A8B9A))),
              const SizedBox(height: 24),
              _buildCategoryGrid(),
              const SizedBox(height: 24),
              _buildModeToggle(),
              const SizedBox(height: 20),
              if (_mode == 'guided' && _selectedCategory != null) _buildGuidedTopics(),
              if (_mode == 'free') _buildFreeText(),
              const SizedBox(height: 28),
              _buildPackageSection(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelperBadge() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3A5C).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_pin_outlined, color: Color(0xFF1A3A5C), size: 18),
          const SizedBox(width: 8),
          Text(
            'Requesting from ${widget.helper!.fullName}',
            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category',
            style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
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
      ],
    );
  }

  Widget _buildModeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
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

  Widget _buildGuidedTopics() {
    final topics = _guidedQuestions[_selectedCategory] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select what you need:',
            style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: topics.map((q) {
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
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildFreeText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Describe your situation:',
            style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'e.g. I just arrived and need help opening a bank account...',
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
          validator: (v) => v == null || v.isEmpty ? 'Please describe your need' : null,
        ),
      ],
    );
  }

  Widget _buildPackageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pick a package',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF1A3A5C))),
        const SizedBox(height: 4),
        const Text('You can adjust details with your helper later.',
            style: TextStyle(fontSize: 12, color: Color(0xFF7A8B9A))),
        const SizedBox(height: 12),
        ..._packages.map((pkg) {
          final selected = _selectedPackage == pkg['value'];
          return GestureDetector(
            onTap: () => setState(() => _selectedPackage = pkg['value']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF1A3A5C) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? const Color(0xFF1A3A5C) : const Color(0xFFDCE5ED),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pkg['label']!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: selected ? Colors.white : const Color(0xFF1A3A5C),
                            )),
                        const SizedBox(height: 2),
                        Text(pkg['desc']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: selected
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : const Color(0xFF7A8B9A),
                            )),
                      ],
                    ),
                  ),
                  Text(pkg['price']!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: selected ? const Color(0xFFE8944A) : const Color(0xFF1A3A5C),
                      )),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSubmitButton() => SizedBox(
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
              : Text(
                  widget.helper != null
                      ? 'Send Request to ${widget.helper!.firstName}'
                      : 'Find Matching Helpers →',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      );

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }
}
