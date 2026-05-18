import 'package:flutter/material.dart';
import '../../models/community_model.dart';
import '../../services/community_service.dart';
import '../../services/community_service_factory.dart';

const _flags = {
  'IR': '🇮🇷', 'SY': '🇸🇾', 'TR': '🇹🇷', 'DE': '🇩🇪',
  'CA': '🇨🇦', 'US': '🇺🇸', 'GB': '🇬🇧',
};

class CirclesScreen extends StatefulWidget {
  final CommunityService service;

  CirclesScreen({super.key, CommunityService? service})
      : service = service ?? createCommunityService();

  @override
  State<CirclesScreen> createState() => _CirclesScreenState();
}

class _CirclesScreenState extends State<CirclesScreen> {
  List<CommunityCircle> _circles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final circles = await widget.service.getCircles();
    if (!mounted) return;
    setState(() {
      _circles = circles;
      _loading = false;
    });
  }

  Future<void> _toggleSubscription(int index) async {
    final circle = _circles[index];
    final result = await widget.service.toggleCircleSubscription(circle.id);
    if (!mounted || result == null) return;
    setState(() {
      _circles[index].isSubscribed =
          result['subscribed'] as bool? ?? !circle.isSubscribed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        automaticallyImplyLeading: false,
        title: const Text('My Circles',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetch,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                    child: Text(
                      'Choose who you see · toggle multiple — we blend feeds',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: _circles.isEmpty
                        ? const Center(
                            child: Text('No circles yet.',
                                style: TextStyle(color: Color(0xFF7A8B9A))))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _circles.length,
                            itemBuilder: (_, i) => _buildCircleCard(i),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCircleCard(int index) {
    final c = _circles[index];
    final flag = _flags[c.nationalityCode] ?? '🌍';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF1A3A5C).withValues(alpha: 0.08),
            child: Text(flag, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                    style: const TextStyle(fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A5C), fontSize: 15)),
                if (c.description.isNotEmpty)
                  Text(c.description,
                      style: const TextStyle(color: Color(0xFF7A8B9A), fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${c.memberCount} members',
                    style: const TextStyle(color: Color(0xFF7A8B9A), fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: c.isSubscribed,
            activeThumbColor: const Color(0xFFE8944A),
            activeTrackColor: const Color(0xFFE8944A).withValues(alpha: 0.4),
            onChanged: (_) => _toggleSubscription(index),
          ),
        ],
      ),
    );
  }
}
