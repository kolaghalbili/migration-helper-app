import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/helper_model.dart';
import 'login_screen.dart';
import 'helper_detail_screen.dart';
import 'helper_dashboard_screen.dart';
import 'newcomer_profile_screen.dart';
import 'inbox_screen.dart';
import 'edit_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final _searchController = TextEditingController();

  List<Helper> _allHelpers = [];
  List<Helper> _filtered = [];
  bool _isLoading = true;
  String _selectedSpecialty = 'All';

  // Current user (for role routing + nationality/language matching)
  Map<String, dynamic>? _me;

  // Active filters
  double _filterMaxRate = 200;
  double _filterMinRating = 0;
  bool _filterVerifiedOnly = false;
  bool _filterNationalityMatch = false;
  bool _filterLanguageMatch = false;

  final List<String> _specialties = [
    'All', 'Banking', 'Housing', 'SIM Card',
    'Legal & Documents', 'Language Support',
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final me = await AuthService().getMe();
    if (!mounted) return;
    if (me != null && me['role'] == 'helper') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HelperDashboardScreen()),
      );
      return;
    }
    setState(() {
      _me = me;
      // Pre-apply scope preference from user profile
      final scope = me?['helper_scope'] as String? ?? 'any';
      _filterNationalityMatch = scope == 'same_nationality';
      _filterLanguageMatch    = scope == 'language_match';
    });
    await _loadHelpers();
  }

  Future<void> _loadHelpers() async {
    setState(() => _isLoading = true);
    final helpers = await _apiService.getHelpers();
    if (!mounted) return;
    setState(() {
      _allHelpers = helpers;
      _isLoading = false;
    });
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    final myNationality = (_me?['nationality'] as String? ?? '').toLowerCase();
    final myLanguages = (_me?['languages'] as List? ?? [])
        .map((l) => l.toString().toLowerCase())
        .toSet();

    setState(() {
      _filtered = _allHelpers.where((h) {
        // Text search
        if (query.isNotEmpty &&
            !h.fullName.toLowerCase().contains(query) &&
            !h.city.toLowerCase().contains(query)) return false;

        // Specialty chip
        if (_selectedSpecialty != 'All' &&
            !h.specialties.any((s) => s.name == _selectedSpecialty)) {
          return false;
        }

        // Max hourly rate
        if (h.hourlyRate != null && h.hourlyRate! > _filterMaxRate) return false;

        // Min rating
        if (_filterMinRating > 0 && h.ratingAvg < _filterMinRating) return false;

        // Verified only
        if (_filterVerifiedOnly && !h.isVerified) return false;

        // Nationality match
        if (_filterNationalityMatch &&
            myNationality.isNotEmpty &&
            h.nationality.toLowerCase() != myNationality) return false;

        // Language match — at least one common language
        if (_filterLanguageMatch && myLanguages.isNotEmpty) {
          final helperLangs =
              h.languages.map((l) => l.toLowerCase()).toSet();
          if (helperLangs.intersection(myLanguages).isEmpty) return false;
        }

        return true;
      }).toList();
    });
  }

  int get _activeFilterCount {
    int count = 0;
    if (_filterMaxRate < 200) count++;
    if (_filterMinRating > 0) count++;
    if (_filterVerifiedOnly) count++;
    if (_filterNationalityMatch) count++;
    if (_filterLanguageMatch) count++;
    return count;
  }

  void _showFilterSheet() {
    // Temp values so the sheet can be cancelled
    double tmpMaxRate        = _filterMaxRate;
    double tmpMinRating      = _filterMinRating;
    bool   tmpVerifiedOnly   = _filterVerifiedOnly;
    bool   tmpNatMatch       = _filterNationalityMatch;
    bool   tmpLangMatch      = _filterLanguageMatch;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Filter Helpers',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3A5C))),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setModal(() {
                        tmpMaxRate      = 200;
                        tmpMinRating    = 0;
                        tmpVerifiedOnly = false;
                        tmpNatMatch     = false;
                        tmpLangMatch    = false;
                      });
                    },
                    child: const Text('Clear all',
                        style: TextStyle(color: Color(0xFFE8944A))),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Max hourly rate
              Row(
                children: [
                  const Text('Max rate:',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A3A5C))),
                  const Spacer(),
                  Text(
                    tmpMaxRate >= 200
                        ? 'Any'
                        : '€${tmpMaxRate.toInt()}/h',
                    style: const TextStyle(
                        color: Color(0xFFE8944A), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Slider(
                value: tmpMaxRate,
                min: 0,
                max: 200,
                divisions: 20,
                activeColor: const Color(0xFFE8944A),
                onChanged: (v) => setModal(() => tmpMaxRate = v),
              ),

              const SizedBox(height: 8),

              // Min rating
              const Text('Minimum rating:',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (i) {
                  final star = i + 1;
                  final selected = tmpMinRating >= star;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setModal(() =>
                          tmpMinRating = tmpMinRating == star.toDouble()
                              ? 0
                              : star.toDouble()),
                      child: Container(
                        margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.amber
                              : const Color(0xFFF5F0EB),
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
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF1A3A5C))),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              // Toggle rows
              _filterToggle(
                'Verified helpers only',
                Icons.verified_outlined,
                tmpVerifiedOnly,
                (v) => setModal(() => tmpVerifiedOnly = v),
              ),
              const SizedBox(height: 10),
              _filterToggle(
                'Same nationality as me',
                Icons.flag_outlined,
                tmpNatMatch,
                (v) => setModal(() {
                  tmpNatMatch = v;
                  if (v) { tmpLangMatch = false; }
                }),
              ),
              const SizedBox(height: 10),
              _filterToggle(
                'Speaks my language(s)',
                Icons.translate_outlined,
                tmpLangMatch,
                (v) => setModal(() {
                  tmpLangMatch = v;
                  if (v) { tmpNatMatch = false; }
                }),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filterMaxRate        = tmpMaxRate;
                      _filterMinRating      = tmpMinRating;
                      _filterVerifiedOnly   = tmpVerifiedOnly;
                      _filterNationalityMatch = tmpNatMatch;
                      _filterLanguageMatch  = tmpLangMatch;
                    });
                    _applyFilters();
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3A5C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Apply Filters',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterToggle(
      String label, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1A3A5C), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  color: Color(0xFF1A3A5C), fontWeight: FontWeight.w500)),
        ),
        Switch(
          value: value,
          activeThumbColor: const Color(0xFFE8944A),
          activeTrackColor: const Color(0xFFE8944A).withValues(alpha: 0.4),
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        title: const Text('Borderline',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.inbox, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InboxScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            tooltip: 'My Profile',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewcomerProfileScreen()),
              );
              _init();
            },
          ),
          IconButton(
            icon: const Icon(Icons.manage_accounts_outlined, color: Colors.white),
            tooltip: 'Edit Profile',
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
              if (updated == true) _loadHelpers();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadHelpers,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildSpecialtyFilter()),
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()))
                : _filtered.isEmpty
                    ? const SliverFillRemaining(
                        child: Center(child: Text('No helpers found.')))
                    : SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _buildHelperCard(_filtered[i]),
                            childCount: _filtered.length,
                          ),
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Find a Local Helper 🤝',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A5C))),
                const SizedBox(height: 4),
                Text('${_filtered.length} helpers available',
                    style: const TextStyle(color: Color(0xFF7A8B9A))),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.tune_outlined,
                    color: Color(0xFF1A3A5C), size: 26),
                tooltip: 'Filter',
                onPressed: _showFilterSheet,
              ),
              if (_activeFilterCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8944A),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$_activeFilterCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => _applyFilters(),
        decoration: InputDecoration(
          hintText: 'Search by name or city...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF7A8B9A)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSpecialtyFilter() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _specialties.length,
        itemBuilder: (_, i) {
          final s = _specialties[i];
          final selected = s == _selectedSpecialty;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedSpecialty = s);
              _applyFilters();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF1A3A5C) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1A3A5C)),
              ),
              child: Text(s,
                  style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF1A3A5C),
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHelperCard(Helper helper) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => HelperDetailScreen(helper: helper))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            _buildAvatar(helper),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(helper.fullName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1A3A5C))),
                      if (helper.isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified,
                            size: 16, color: Color(0xFF2E8B8B)),
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (helper.city.isNotEmpty)
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: Color(0xFF7A8B9A)),
                      const SizedBox(width: 2),
                      Text(helper.city,
                          style: const TextStyle(
                              color: Color(0xFF7A8B9A), fontSize: 13)),
                    ]),
                  const SizedBox(height: 6),
                  if (helper.specialties.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: helper.specialties.take(3).map((s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8944A).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${s.icon} ${s.name}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFE8944A))),
                          )).toList(),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                Text(helper.ratingAvg.toStringAsFixed(1),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A5C))),
                Text(
                    helper.hourlyRate != null
                        ? '€${helper.hourlyRate!.toStringAsFixed(0)}/h'
                        : 'Free',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF7A8B9A))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Helper helper) {
    final imageUrl = helper.primaryImageUrl;
    if (imageUrl != null) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          placeholder: (_, url) => _avatarFallback(helper),
          errorWidget: (_, url, e) => _avatarFallback(helper),
        ),
      );
    }
    return _avatarFallback(helper);
  }

  Widget _avatarFallback(Helper helper) => CircleAvatar(
        radius: 28,
        backgroundColor: const Color(0xFFE8944A).withValues(alpha: 0.2),
        child: Text(
          helper.firstName.isNotEmpty
              ? helper.firstName[0].toUpperCase()
              : '?',
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE8944A)),
        ),
      );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
