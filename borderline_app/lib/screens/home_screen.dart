import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/helper_model.dart';
import '../models/filter_params.dart';
import 'login_screen.dart';
import 'helper_detail_screen.dart';
import 'helper_dashboard_screen.dart';
import 'map_screen.dart';
import 'edit_profile_screen.dart';
import 'search_filter_screen.dart';
import 'quick_match_screen.dart';
import 'my_requests_screen.dart';
import 'notifications_screen.dart';
import '../services/notification_service.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final _notifService = NotificationService();
  final _searchController = TextEditingController();

  List<Helper> _allHelpers = [];
  List<Helper> _filtered = [];
  bool _isLoading = true;
  String _selectedSpecialty = 'All';
  int _unreadNotifCount = 0;
  Timer? _notifTimer;

  // Current user (for role routing + nationality/language matching)
  Map<String, dynamic>? _me;

  FilterParams _filters = FilterParams.defaults;

  List<String> _specialties = ['All'];

  @override
  void initState() {
    super.initState();
    _init();
    _fetchUnreadCount();
    _notifTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetchUnreadCount(),
    );
  }

  Future<void> _fetchUnreadCount() async {
    final count = await _notifService.getUnreadCount();
    if (mounted) setState(() => _unreadNotifCount = count);
  }

  Future<void> _init() async {
    final authService = AuthService();
    final meFuture = authService.getMe();
    final specialtiesFuture = authService.getSpecialties();

    final me = await meFuture;
    if (!mounted) return;
    if (me != null && me['role'] == 'helper') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HelperDashboardScreen()),
      );
      return;
    }

    final specialties = await specialtiesFuture;
    if (!mounted) return;

    setState(() {
      _me = me;
      final scope = me?['helper_scope'] as String? ?? 'any';
      _filters = FilterParams(
        nationalityMatch: scope == 'same_nationality' ? 'same' : 'any',
        languageMatch: scope == 'language_match',
      );
      _specialties = [
        'All',
        ...specialties.map((s) => s['name'] as String),
      ];
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
            !h.city.toLowerCase().contains(query)) { return false; }

        // Specialty chip
        if (_selectedSpecialty != 'All' &&
            !h.specialties.any((s) => s.name == _selectedSpecialty)) {
          return false;
        }

        // City filter
        if (_filters.city.isNotEmpty &&
            !h.city.toLowerCase().contains(_filters.city.toLowerCase())) {
          return false;
        }

        // Category filter
        if (_filters.selectedCategory.isNotEmpty &&
            !h.specialties.any((s) =>
                s.name.toLowerCase().contains(
                    _filters.selectedCategory.toLowerCase()))) {
          return false;
        }

        // Max hourly rate
        if (h.hourlyRate != null && h.hourlyRate! > _filters.maxRate) return false;

        // Min rating
        if (_filters.minRating > 0 && h.ratingAvg < _filters.minRating) return false;

        // Verified only
        if (_filters.verifiedOnly && !h.isVerified) return false;

        // Nationality match
        if (_filters.nationalityMatch == 'same' &&
            myNationality.isNotEmpty &&
            h.nationality.toLowerCase() != myNationality) { return false; }
        if (_filters.nationalityMatch == 'arabic') {
          final helperLangs = h.languages.map((l) => l.toLowerCase()).toSet();
          final helperNat = h.nationality.toLowerCase();
          if (!helperLangs.contains('arabic') &&
              !helperNat.contains('arab') &&
              !helperNat.contains('saudi') &&
              !helperNat.contains('egypt') &&
              !helperNat.contains('syria') &&
              !helperNat.contains('iraq') &&
              !helperNat.contains('jordan') &&
              !helperNat.contains('lebanon') &&
              !helperNat.contains('morocco') &&
              !helperNat.contains('tunisia') &&
              !helperNat.contains('libya') &&
              !helperNat.contains('algeria')) { return false; }
        }

        // Language match — at least one common language
        if (_filters.languageMatch && myLanguages.isNotEmpty) {
          final helperLangs =
              h.languages.map((l) => l.toLowerCase()).toSet();
          if (helperLangs.intersection(myLanguages).isEmpty) return false;
        }

        return true;
      }).toList();
    });
  }

  int get _activeFilterCount => _filters.activeCount;

  Future<void> _openFilterScreen() async {
    final result = await Navigator.push<FilterParams>(
      context,
      MaterialPageRoute(
        builder: (_) => SearchFilterScreen(
          initial:      _filters,
          totalHelpers: _filtered.length,
          categories:   _specialties.where((s) => s != 'All').toList(),
        ),
      ),
    );
    if (result != null) {
      setState(() => _filters = result);
      _applyFilters();
    }
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
            icon: const Icon(Icons.map_outlined, color: Colors.white),
            tooltip: 'Map view',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelperMapScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.assignment_outlined, color: Colors.white),
            tooltip: 'My Requests',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
            ),
          ),
          _bellIcon(),
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
                onPressed: _openFilterScreen,
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
    return Column(
      children: [
        Padding(
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
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QuickMatchScreen()),
          ),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3A5C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.bolt, color: Color(0xFFE8944A), size: 18),
                SizedBox(width: 6),
                Text('Quick Match',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                Spacer(),
                Text('tinder-style →',
                    style:
                        TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
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
                      ],
                      if (helper.badges.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E8B8B).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${helper.badges.length} badge${helper.badges.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF2E8B8B),
                                fontWeight: FontWeight.w600),
                          ),
                        ),
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

  Widget _bellIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          tooltip: 'Notifications',
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationsScreen()),
            );
            _fetchUnreadCount();
          },
        ),
        if (_unreadNotifCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 17,
              height: 17,
              decoration: const BoxDecoration(
                color: Color(0xFFE8944A),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _unreadNotifCount > 9 ? '9+' : '$_unreadNotifCount',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}
