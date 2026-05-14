import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import '../widgets/country_city_picker.dart';
import '../widgets/language_selector.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _authService = AuthService();

  // form controllers
  final _firstNameCtrl  = TextEditingController();
  final _lastNameCtrl   = TextEditingController();
  final _bioCtrl        = TextEditingController();
  final _nationalityCtrl = TextEditingController();
  final _countryCtrl    = TextEditingController();
  final _cityCtrl       = TextEditingController();
  final _rateCtrl       = TextEditingController();

  List<String> _languages = [];
  bool _isAvailable = true;
  bool _isHelper = false;
  bool _isLoading = false;
  bool _isSaving = false;

  // current profile images loaded from backend
  List<Map<String, dynamic>> _images = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final me = await _authService.getMe();
    if (me == null || !mounted) return;

    setState(() {
      _firstNameCtrl.text  = me['first_name'] ?? '';
      _lastNameCtrl.text   = me['last_name'] ?? '';
      _bioCtrl.text        = me['bio'] ?? '';
      _nationalityCtrl.text = me['nationality'] ?? '';
      _countryCtrl.text    = me['country'] ?? '';
      _cityCtrl.text       = me['city'] ?? '';
      _rateCtrl.text       = me['hourly_rate'] != null ? me['hourly_rate'].toString() : '';
      _languages           = List<String>.from(me['languages'] ?? []);
      _isAvailable         = me['is_available'] ?? true;
      _isHelper            = me['role'] == 'helper';
      _images              = List<Map<String, dynamic>>.from(me['profile_images'] ?? []);
      _isLoading           = false;
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final rate = double.tryParse(_rateCtrl.text.trim());

    final ok = await _authService.updateProfile(
      firstName:   _firstNameCtrl.text.trim(),
      lastName:    _lastNameCtrl.text.trim(),
      bio:         _bioCtrl.text.trim(),
      nationality: _nationalityCtrl.text.trim(),
      country:     _countryCtrl.text.trim(),
      city:        _cityCtrl.text.trim(),
      languages:   _languages,
      hourlyRate:  rate,
      isAvailable: _isAvailable,
    );

    setState(() => _isSaving = false);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _addPhoto() async {
    if (_images.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 3 photos allowed.')),
      );
      return;
    }
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;

    setState(() => _isLoading = true);
    final result = await _authService.uploadProfileImage(file);
    if (result != null && mounted) {
      setState(() => _images.add(result));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deletePhoto(int imageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove photo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await _authService.deleteProfileImage(imageId);
    if (ok && mounted) {
      setState(() => _images.removeWhere((img) => img['id'] == imageId));
    }
  }

  Future<void> _setPrimary(int imageId) async {
    await _authService.setProfileImagePrimary(imageId);
    if (!mounted) return;
    setState(() {
      for (final img in _images) {
        img['is_primary'] = img['id'] == imageId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        foregroundColor: Colors.white,
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhotosSection(),
                  const SizedBox(height: 28),
                  _sectionTitle('Basic Info'),
                  const SizedBox(height: 16),
                  _buildBasicInfo(),
                  const SizedBox(height: 28),
                  _sectionTitle('Background'),
                  const SizedBox(height: 16),
                  _buildBackground(),
                  const SizedBox(height: 28),
                  _sectionTitle('Location'),
                  const SizedBox(height: 16),
                  _buildLocation(),
                  if (_isHelper) ...[
                    const SizedBox(height: 28),
                    _sectionTitle('Helper Settings'),
                    const SizedBox(height: 16),
                    _buildHelperSettings(),
                  ],
                  const SizedBox(height: 40),
                  _buildSaveButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // ── Photos ────────────────────────────────────────────────────────────────

  Widget _buildPhotosSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Photos',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A3A5C))),
              const Spacer(),
              Text('${_images.length}/3',
                  style: const TextStyle(color: Color(0xFF7A8B9A), fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ..._images.map((img) => _photoSlot(img)),
              if (_images.length < 3) _addPhotoSlot(),
            ],
          ),
          if (_images.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'Tap a photo to set as primary. Long-press to remove.',
                style: TextStyle(fontSize: 11, color: Color(0xFF7A8B9A)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _photoSlot(Map<String, dynamic> img) {
    final isPrimary = img['is_primary'] == true;
    final url = img['image_url'] as String?;

    return GestureDetector(
      onTap: () => _setPrimary(img['id'] as int),
      onLongPress: () => _deletePhoto(img['id'] as int),
      child: Container(
        width: 90,
        height: 90,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary ? const Color(0xFFE8944A) : const Color(0xFFDCE5ED),
            width: isPrimary ? 2.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: url != null
                  ? CachedNetworkImage(
                      imageUrl: url,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      placeholder: (_, url) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      errorWidget: (_, url, err) => const Icon(Icons.broken_image),
                    )
                  : const Center(child: Icon(Icons.image, color: Color(0xFF7A8B9A))),
            ),
            if (isPrimary)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8944A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('main',
                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _addPhotoSlot() => GestureDetector(
        onTap: _addPhoto,
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F0EB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDCE5ED), style: BorderStyle.solid),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, color: Color(0xFF7A8B9A), size: 24),
              SizedBox(height: 4),
              Text('Add', style: TextStyle(fontSize: 11, color: Color(0xFF7A8B9A))),
            ],
          ),
        ),
      );

  // ── Basic Info ────────────────────────────────────────────────────────────

  Widget _buildBasicInfo() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _field(_firstNameCtrl, 'First name', Icons.person_outline)),
            const SizedBox(width: 12),
            Expanded(child: _field(_lastNameCtrl, 'Last name', Icons.person_outline)),
          ],
        ),
        const SizedBox(height: 16),
        _label('Bio'),
        TextFormField(
          controller: _bioCtrl,
          maxLines: 4,
          decoration: _decor(
            _isHelper
                ? 'Tell newcomers how you can help...'
                : 'A little about yourself...',
            Icons.edit_outlined,
          ),
        ),
      ],
    );
  }

  // ── Background ────────────────────────────────────────────────────────────

  Widget _buildBackground() {
    return Column(
      children: [
        CountryCityPicker(
          controller: _nationalityCtrl,
          label: 'Nationality',
          hint: 'e.g. Iran, Germany...',
          searchCountriesOnly: true,
        ),
        const SizedBox(height: 20),
        LanguageSelector(
          selected: _languages,
          onChanged: (langs) => setState(() => _languages = langs),
        ),
      ],
    );
  }

  // ── Location ──────────────────────────────────────────────────────────────

  Widget _buildLocation() {
    return Column(
      children: [
        CountryCityPicker(
          controller: _countryCtrl,
          label: _isHelper ? 'Country *' : 'Destination country',
          hint: 'e.g. Austria, Germany...',
          searchCountriesOnly: true,
        ),
        const SizedBox(height: 16),
        CountryCityPicker(
          controller: _cityCtrl,
          label: _isHelper ? 'City *' : 'Destination city',
          hint: 'e.g. Vienna, Berlin...',
        ),
      ],
    );
  }

  // ── Helper Settings ───────────────────────────────────────────────────────

  Widget _buildHelperSettings() {
    return Column(
      children: [
        _label('Hourly Rate (€)'),
        TextFormField(
          controller: _rateCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _decor('e.g. 15 (leave blank if free)', Icons.euro_outlined),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDCE5ED)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Color(0xFF1A3A5C), size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Available for requests',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
                    SizedBox(height: 2),
                    Text('Turn off to pause incoming requests',
                        style: TextStyle(fontSize: 12, color: Color(0xFF7A8B9A))),
                  ],
                ),
              ),
              Switch(
                value: _isAvailable,
                activeThumbColor: const Color(0xFFE8944A),
                activeTrackColor: const Color(0xFFE8944A).withValues(alpha: 0.4),
                onChanged: (v) => setState(() => _isAvailable = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Save Button ───────────────────────────────────────────────────────────

  Widget _buildSaveButton() => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE8944A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isSaving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Save Changes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C)),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
      );

  Widget _field(TextEditingController ctrl, String hint, IconData icon) => TextFormField(
        controller: ctrl,
        decoration: _decor(hint, icon),
      );

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
      );

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _bioCtrl.dispose();
    _nationalityCtrl.dispose();
    _countryCtrl.dispose();
    _cityCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }
}
