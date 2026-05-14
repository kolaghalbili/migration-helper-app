import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../widgets/country_city_picker.dart';
import '../widgets/language_selector.dart';
import '../widgets/profile_image_picker.dart';
import '../widgets/map_location_picker.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _pageController = PageController();
  final _authService = AuthService();
  int _currentStep = 0;
  bool _isLoading = false;

  // ── Step 1 – Basic info ───────────────────────────────────────────────────
  final _step1Key = GlobalKey<FormState>();
  String _selectedRole = 'newcomer';
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  bool _obscurePassword = true;

  // ── Step 2 – Background ───────────────────────────────────────────────────
  final _nationalityCtrl = TextEditingController();
  List<String> _languages = [];
  final _bioCtrl = TextEditingController();

  // ── Step 3 – Location ─────────────────────────────────────────────────────
  final _countryCtrl = TextEditingController();
  final _cityCtrl    = TextEditingController();
  bool _trackLocation = false;
  bool _gettingGps = false;
  double? _latitude;
  double? _longitude;
  LatLng? _pinnedLocation;

  // ── Step 4 – Photos ───────────────────────────────────────────────────────
  List<XFile> _photos = [];

  // ── Navigation ────────────────────────────────────────────────────────────
  void _next() {
    if (_currentStep == 0 && !_step1Key.currentState!.validate()) return;
    if (_currentStep < 3) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    }
  }

  void _back() {
    if (_currentStep > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  // ── GPS helper ────────────────────────────────────────────────────────────
  Future<void> _toggleTracking(bool value) async {
    setState(() => _trackLocation = value);
    if (!value) {
      setState(() { _latitude = null; _longitude = null; });
      return;
    }
    setState(() => _gettingGps = true);
    final pos = await LocationService.getCurrentPosition();
    setState(() => _gettingGps = false);
    if (pos != null) {
      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _pinnedLocation = latLng;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get location. Make sure location is enabled.')),
        );
      }
      setState(() => _trackLocation = false);
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one profile photo.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 1. Register
    final registered = await _authService.register(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      role: _selectedRole,
      nationality: _nationalityCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      languages: _languages,
      bio: _bioCtrl.text.trim(),
    );

    if (!registered) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration failed. Email may already be in use.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    // 2. Auto-login
    final loggedIn = await _authService.login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );

    if (!loggedIn) {
      setState(() => _isLoading = false);
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
      return;
    }

    // 3. Upload location if tracking enabled
    if (_trackLocation && _latitude != null && _longitude != null) {
      await _authService.updateLocation(
        latitude: _latitude!,
        longitude: _longitude!,
        city: _cityCtrl.text.trim(),
        country: _countryCtrl.text.trim(),
        trackingEnabled: true,
      );
    }

    // 4. Upload photos (first is mandatory)
    for (final photo in _photos) {
      await _authService.uploadProfileImage(photo);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final titles = ['Who are you?', 'Your background', 'Your location', 'Your photos'];
    final subtitles = [
      'Choose your role and set up your account',
      'Tell others about yourself',
      _selectedRole == 'newcomer'
          ? 'Where are you headed?'
          : 'Where are you based?',
      'Add photos so people know who you are',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _back,
            child: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A3A5C)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titles[_currentStep],
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3A5C)),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitles[_currentStep],
                  style: const TextStyle(fontSize: 13, color: Color(0xFF7A8B9A)),
                ),
              ],
            ),
          ),
          Text(
            '${_currentStep + 1}/4',
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF7A8B9A), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(4, (i) {
          final done = i <= _currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: done ? const Color(0xFFE8944A) : const Color(0xFFDCE5ED),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLastStep = _currentStep == 3;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isLoading ? null : (isLastStep ? _submit : _next),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE8944A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  isLastStep ? 'Create Account' : 'Continue',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  // ── Step 1: Basic info ────────────────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Form(
        key: _step1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Role selector
            _label('I am a...'),
            const SizedBox(height: 10),
            Row(
              children: [
                _roleButton('newcomer', 'Newcomer', Icons.flight_takeoff_outlined),
                const SizedBox(width: 12),
                _roleButton('helper', 'Local Helper', Icons.handshake_outlined),
              ],
            ),

            const SizedBox(height: 24),
            _label('First Name'),
            _field(_firstNameCtrl, 'Ali', Icons.person_outline,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null),

            const SizedBox(height: 16),
            _label('Last Name'),
            _field(_lastNameCtrl, 'Ahmadi', Icons.person_outline,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null),

            const SizedBox(height: 16),
            _label('Email'),
            _field(_emailCtrl, 'you@example.com', Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null),

            const SizedBox(height: 16),
            _label('Password'),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              decoration: _inputDecoration('••••••••', Icons.lock_outlined).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Background ────────────────────────────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CountryCityPicker(
            controller: _nationalityCtrl,
            label: 'Nationality',
            hint: 'e.g. Iran, Germany...',
            searchCountriesOnly: true,
          ),

          const SizedBox(height: 24),
          LanguageSelector(
            selected: _languages,
            onChanged: (langs) => setState(() => _languages = langs),
          ),

          const SizedBox(height: 24),
          _label(_selectedRole == 'helper' ? 'About you (visible to newcomers)' : 'About you (optional)'),
          TextFormField(
            controller: _bioCtrl,
            maxLines: 4,
            decoration: _inputDecoration(
              _selectedRole == 'helper'
                  ? 'Tell newcomers how you can help, your experience...'
                  : 'A little about yourself...',
              Icons.edit_outlined,
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 3: Location ──────────────────────────────────────────────────────
  Widget _buildStep3() {
    final isNewcomer = _selectedRole == 'newcomer';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CountryCityPicker(
            controller: _countryCtrl,
            label: isNewcomer ? 'Destination country *' : 'Country *',
            hint: 'e.g. Germany, Netherlands...',
            searchCountriesOnly: true,
            validator: (v) => v == null || v.isEmpty ? 'Country is required' : null,
          ),

          const SizedBox(height: 20),
          CountryCityPicker(
            controller: _cityCtrl,
            label: isNewcomer ? 'Destination city (optional)' : 'City *',
            hint: 'e.g. Berlin, Amsterdam...',
            validator: isNewcomer
                ? null
                : (v) => v == null || v.isEmpty ? 'City is required for helpers' : null,
          ),

          const SizedBox(height: 24),

          // GPS / tracking toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCE5ED)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.my_location, color: Color(0xFF1A3A5C), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isNewcomer
                                ? "I'm already in my destination"
                                : 'Use my live location',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A3A5C)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isNewcomer
                                ? 'Enable this once you arrive to appear on local searches'
                                : 'Let newcomers find you based on your real location',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF7A8B9A)),
                          ),
                        ],
                      ),
                    ),
                    _gettingGps
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Switch(
                            value: _trackLocation,
                            activeThumbColor: const Color(0xFFE8944A),
                            activeTrackColor: const Color(0xFFE8944A).withValues(alpha: 0.4),
                            onChanged: _toggleTracking,
                          ),
                  ],
                ),
                if (_trackLocation && _latitude != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Location captured: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF4A5568)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Helpers get the map picker too
          if (_selectedRole == 'helper') ...[
            const SizedBox(height: 24),
            MapLocationPicker(
              initialLocation: _pinnedLocation,
              onLocationSelected: (latLng) {
                setState(() {
                  _pinnedLocation = latLng;
                  _latitude = latLng.latitude;
                  _longitude = latLng.longitude;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  // ── Step 4: Photos ────────────────────────────────────────────────────────
  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        children: [
          ProfileImagePicker(
            onChanged: (photos) => setState(() => _photos = photos),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3A5C).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: Color(0xFF1A3A5C), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your primary photo will be shown on your public profile and in search results.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF4A5568), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text(
                'Already have an account? Login',
                style: TextStyle(color: Color(0xFF1A3A5C), fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _roleButton(String role, String label, IconData icon) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1A3A5C) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A3A5C), width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : const Color(0xFF1A3A5C)),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF1A3A5C),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
      );

  Widget _field(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: _inputDecoration(hint, icon),
        validator: validator,
      );

  InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF7A8B9A)),
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
      );

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nationalityCtrl.dispose();
    _bioCtrl.dispose();
    _countryCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }
}
