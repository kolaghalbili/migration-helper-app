import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../models/helper_model.dart';
import 'helper_detail_screen.dart';

class HelperMapScreen extends StatefulWidget {
  const HelperMapScreen({super.key});

  @override
  State<HelperMapScreen> createState() => _HelperMapScreenState();
}

class _HelperMapScreenState extends State<HelperMapScreen> {
  final _mapController = MapController();
  final _apiService    = ApiService();

  List<Helper> _helpers      = [];
  Helper?      _selected;
  LatLng?      _myLocation;
  bool         _isLoading    = true;

  static const _defaultCenter = LatLng(48.2082, 16.3738); // Vienna

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final helpers = await _apiService.getHelpers();
    final pos     = await LocationService.getCurrentPosition();

    if (!mounted) return;

    setState(() {
      _helpers    = helpers.where((h) => h.latitude != null && h.longitude != null).toList();
      _myLocation = pos != null ? LatLng(pos.latitude, pos.longitude) : null;
      _isLoading  = false;
    });

    final center = _myLocation ??
        (_helpers.isNotEmpty
            ? LatLng(_helpers.first.latitude!, _helpers.first.longitude!)
            : _defaultCenter);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(center, 12);
    });
  }

  void _centreOnMe() {
    final target = _myLocation ??
        (_helpers.isNotEmpty
            ? LatLng(_helpers.first.latitude!, _helpers.first.longitude!)
            : _defaultCenter);
    _mapController.move(target, 13);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Full-screen map ──────────────────────────────────────────────
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _defaultCenter,
                    initialZoom: 5,
                    onTap: (tapPos, point) => setState(() => _selected = null),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.borderline.app',
                    ),

                    // My location marker
                    if (_myLocation != null)
                      MarkerLayer(markers: [
                        Marker(
                          point: _myLocation!,
                          width: 22,
                          height: 22,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.4),
                                    blurRadius: 8)
                              ],
                            ),
                          ),
                        ),
                      ]),

                    // Helper markers
                    MarkerLayer(
                      markers: _helpers.map((h) {
                        final isSelected = _selected?.id == h.id;
                        return Marker(
                          point: LatLng(h.latitude!, h.longitude!),
                          width:  isSelected ? 64 : 52,
                          height: isSelected ? 76 : 64,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selected = h);
                              _mapController.move(
                                  LatLng(h.latitude!, h.longitude!), 14);
                            },
                            child: _HelperPin(helper: h, selected: isSelected),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

          // ── AppBar overlay ───────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _mapButton(
                    icon: Icons.arrow_back_ios_new,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8)
                        ],
                      ),
                      child: Text(
                        '${_helpers.length} helpers on map',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A3A5C)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _mapButton(
                    icon: Icons.my_location,
                    onTap: _centreOnMe,
                  ),
                ],
              ),
            ),
          ),

          // ── Helper detail card ───────────────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            bottom: _selected != null ? 0 : -280,
            left: 0,
            right: 0,
            child: _selected != null
                ? _HelperCard(
                    helper: _selected!,
                    onClose: () => setState(() => _selected = null),
                    onViewProfile: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              HelperDetailScreen(helper: _selected!)),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _mapButton({required IconData icon, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12), blurRadius: 8)
            ],
          ),
          child: Icon(icon, color: const Color(0xFF1A3A5C), size: 20),
        ),
      );
}

// ── Helper pin marker ──────────────────────────────────────────────────────────

class _HelperPin extends StatelessWidget {
  final Helper helper;
  final bool selected;

  const _HelperPin({required this.helper, required this.selected});

  @override
  Widget build(BuildContext context) {
    final size = selected ? 52.0 : 42.0;
    final url  = helper.primaryImageUrl;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width:  size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: selected
                    ? const Color(0xFFE8944A)
                    : Colors.white,
                width: selected ? 3 : 2.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: ClipOval(
            child: url != null
                ? CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    errorWidget: (_, u, e) => _fallback(size),
                  )
                : _fallback(size),
          ),
        ),
        // Pin triangle
        CustomPaint(
          size: const Size(12, 7),
          painter: _PinTailPainter(
              color: selected ? const Color(0xFFE8944A) : Colors.white),
        ),
      ],
    );
  }

  Widget _fallback(double size) => Container(
        width: size,
        height: size,
        color: const Color(0xFFE8944A).withValues(alpha: 0.15),
        child: Center(
          child: Text(
            helper.firstName.isNotEmpty
                ? helper.firstName[0].toUpperCase()
                : '?',
            style: TextStyle(
              fontSize: size * 0.38,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFE8944A),
            ),
          ),
        ),
      );
}

class _PinTailPainter extends CustomPainter {
  final Color color;
  const _PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTailPainter old) => old.color != color;
}

// ── Bottom helper card ─────────────────────────────────────────────────────────

class _HelperCard extends StatelessWidget {
  final Helper helper;
  final VoidCallback onClose;
  final VoidCallback onViewProfile;

  const _HelperCard({
    required this.helper,
    required this.onClose,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16)],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: const Color(0xFFDCE5ED),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(helper.fullName,
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A3A5C))),
                        ),
                        if (helper.isVerified)
                          const Icon(Icons.verified,
                              size: 16, color: Color(0xFF2E8B8B)),
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
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 15),
                        const SizedBox(width: 3),
                        Text(helper.ratingAvg.toStringAsFixed(1),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF1A3A5C))),
                        Text(' (${helper.totalReviews})',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF7A8B9A))),
                        const SizedBox(width: 12),
                        Text(
                          helper.hourlyRate != null
                              ? '€${helper.hourlyRate!.toStringAsFixed(0)}/h'
                              : 'Free',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE8944A),
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF7A8B9A)),
                onPressed: onClose,
              ),
            ],
          ),
          if (helper.specialties.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 28,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: helper.specialties.map((s) => Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8944A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${s.icon} ${s.name}',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFE8944A))),
                )).toList(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: onViewProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3A5C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View Full Profile',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final url = helper.primaryImageUrl;
    if (url != null) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorWidget: (_, u, e) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() => CircleAvatar(
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
}
