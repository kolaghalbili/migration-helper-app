import 'package:flutter/material.dart';
import '../../models/community_model.dart';
import '../../services/community_service.dart';
import '../../services/community_service_factory.dart';
import '../../utils/web_storage.dart';

class CommunityFeedScreen extends StatefulWidget {
  final CommunityService service;

  CommunityFeedScreen({super.key, CommunityService? service})
      : service = service ?? createCommunityService();

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  List<CommunityPost> _posts = [];
  bool _loading = true;
  String _activeTab = 'all';
  String _city = '';
  late final TextEditingController _cityCtrl;

  final _tabs = ['all', 'need', 'offer', 'story'];

  @override
  void initState() {
    super.initState();
    _city = WebStorage.get('city');
    _cityCtrl = TextEditingController(text: _city);
    _fetchPosts();
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchPosts() async {
    setState(() => _loading = true);
    final posts = await widget.service.getPosts(
      city: _city,
      type: _activeTab == 'all' ? null : _activeTab,
    );
    if (!mounted) return;
    setState(() {
      _posts = posts;
      _loading = false;
    });
  }

  Future<void> _toggleLike(int index) async {
    final post = _posts[index];
    final result = await widget.service.toggleLike(post.id);
    if (!mounted || result == null) return;
    setState(() {
      _posts[index] = post.copyWith(
        isLiked: result['liked'] as bool? ?? !post.isLiked,
        likeCount: result['like_count'] as int? ?? post.likeCount,
      );
    });
  }

  void _showCreateSheet() {
    String selectedType = 'need';
    final bodyCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: _city);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create Post',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A5C))),
                const SizedBox(height: 16),
                Row(
                  children: _tabs.where((t) => t != 'all').map((t) {
                    final selected = selectedType == t;
                    return GestureDetector(
                      onTap: () => setModal(() => selectedType = t),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? _typeColor(t) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _typeColor(t)),
                        ),
                        child: Text(t[0].toUpperCase() + t.substring(1),
                            style: TextStyle(
                                color: selected ? Colors.white : _typeColor(t),
                                fontWeight: FontWeight.w600)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'What\'s on your mind?',
                    filled: true,
                    fillColor: const Color(0xFFF5F0EB),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cityCtrl,
                  decoration: InputDecoration(
                    hintText: 'City',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    filled: true,
                    fillColor: const Color(0xFFF5F0EB),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A3A5C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (bodyCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx);
                      await widget.service.createPost(
                        postType: selectedType,
                        body: bodyCtrl.text.trim(),
                        city: cityCtrl.text.trim(),
                      );
                      _fetchPosts();
                    },
                    child: const Text('Post', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'need':  return const Color(0xFFE8944A);
      case 'offer': return const Color(0xFF2E8B8B);
      case 'story': return const Color(0xFF1A3A5C);
      default:      return const Color(0xFF1A3A5C);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        title: const Text('Community',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPosts,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildControls()),
            if (_loading)
              const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()))
            else if (_posts.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text('No posts in this city yet. Be the first!',
                      style: TextStyle(color: Color(0xFF7A8B9A))),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _buildPostCard(i),
                    childCount: _posts.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSheet,
        backgroundColor: const Color(0xFFE8944A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _tabs.map((t) {
                final selected = _activeTab == t;
                final label = t == 'all' ? 'All' : t[0].toUpperCase() + t.substring(1);
                return GestureDetector(
                  onTap: () {
                    setState(() => _activeTab = t);
                    _fetchPosts();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF1A3A5C) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF1A3A5C)),
                    ),
                    child: Text(label,
                        style: TextStyle(
                            color: selected ? Colors.white : const Color(0xFF1A3A5C),
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _cityCtrl,
            onSubmitted: (v) {
              setState(() => _city = v.trim());
              _fetchPosts();
            },
            decoration: InputDecoration(
              hintText: 'Filter by city...',
              prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(int index) {
    final post = _posts[index];
    final initials = post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE8944A).withValues(alpha: 0.2),
                backgroundImage: post.authorImage != null
                    ? NetworkImage(post.authorImage!) : null,
                child: post.authorImage == null
                    ? Text(initials,
                        style: const TextStyle(color: Color(0xFFE8944A),
                            fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3A5C))),
                    Text(post.city,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF7A8B9A))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _typeColor(post.postType).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  post.postType[0].toUpperCase() + post.postType.substring(1),
                  style: TextStyle(fontSize: 11, color: _typeColor(post.postType),
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(post.body, style: const TextStyle(color: Color(0xFF1A3A5C), height: 1.4)),
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: post.tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F0EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('#$tag',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF7A8B9A))),
                  )).toList(),
            ),
          ],
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _toggleLike(index),
            child: Row(
              children: [
                Icon(
                  post.isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: post.isLiked ? Colors.red : const Color(0xFF7A8B9A),
                ),
                const SizedBox(width: 4),
                Text('${post.likeCount}',
                    style: const TextStyle(color: Color(0xFF7A8B9A), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
