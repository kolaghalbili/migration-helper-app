import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/helper_model.dart';
import 'login_screen.dart';
import 'helper_detail_screen.dart';
import 'inbox_screen.dart';

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

  final List<String> _specialties = [
    'All', 'Banking', 'Housing', 'SIM Card',
    'Legal & Documents', 'Language Support',
  ];

  @override
  void initState() {
    super.initState();
    _loadHelpers();
  }

  Future<void> _loadHelpers() async {
    setState(() => _isLoading = true);
    final helpers = await _apiService.getHelpers();
    setState(() {
      _allHelpers = helpers;
      _filtered = helpers;
      _isLoading = false;
    });
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _allHelpers.where((h) {
        final matchSearch = query.isEmpty ||
            h.fullName.toLowerCase().contains(query) ||
            h.city.toLowerCase().contains(query);
        final matchSpecialty = _selectedSpecialty == 'All' ||
            h.specialties.any((s) => s.name == _selectedSpecialty);
        return matchSearch && matchSpecialty;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        title: const Text('Borderline', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.inbox, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InboxScreen()),
              ),
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
            )
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Find a Local Helper 🤝',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 4),
          Text('${_filtered.length} helpers available',
              style: const TextStyle(color: Color(0xFF7A8B9A))),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Avatar — shows profile image if available
            _buildAvatar(helper),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(helper.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A3A5C))),
                      if (helper.isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, size: 16, color: Color(0xFF2E8B8B)),
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (helper.city.isNotEmpty)
                    Row(children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF7A8B9A)),
                      const SizedBox(width: 2),
                      Text(helper.city, style: const TextStyle(color: Color(0xFF7A8B9A), fontSize: 13)),
                    ]),
                  const SizedBox(height: 6),
                  if (helper.specialties.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: helper.specialties.take(3).map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8944A).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${s.icon} ${s.name}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFFE8944A))),
                      )).toList(),
                    ),
                ],
              ),
            ),
            // Rating
            Column(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                Text(helper.ratingAvg.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
                Text(helper.hourlyRate != null ? '€${helper.hourlyRate!.toStringAsFixed(0)}/h' : 'Free',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF7A8B9A))),
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
          helper.firstName.isNotEmpty ? helper.firstName[0].toUpperCase() : '?',
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFE8944A)),
        ),
      );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}