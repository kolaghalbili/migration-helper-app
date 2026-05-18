import 'package:flutter/material.dart';
import '../../models/community_model.dart';
import '../../services/community_service.dart';
import '../../services/community_service_factory.dart';
import '../../utils/web_storage.dart';

String relativeTime(String isoString) {
  final dt = DateTime.tryParse(isoString);
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24)   return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

class QAScreen extends StatefulWidget {
  final CommunityService service;

  QAScreen({super.key, CommunityService? service})
      : service = service ?? createCommunityService();

  @override
  State<QAScreen> createState() => _QAScreenState();
}

class _QAScreenState extends State<QAScreen> {
  List<CommunityQuestion> _questions = [];
  List<CommunityQuestion> _filtered = [];
  bool _loading = true;
  String _activeTab = 'hot';
  String _city = '';
  int? _expandedIndex;
  final _searchCtrl = TextEditingController();
  final Map<int, TextEditingController> _answerCtrls = {};

  @override
  void initState() {
    super.initState();
    _city = WebStorage.get('city');
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final questions = await widget.service.getQuestions(
      city: _city,
      tab: _activeTab == 'hot' ? null : _activeTab,
    );
    if (!mounted) return;
    setState(() {
      _questions = questions;
      _loading = false;
      _applySearch();
    });
  }

  void _applySearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_questions)
          : _questions.where((qu) => qu.body.toLowerCase().contains(q)).toList();
    });
  }

  void _showAskSheet() {
    final bodyCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: _city);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
              const Text('Ask a Question',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3A5C))),
              const SizedBox(height: 16),
              TextField(
                controller: bodyCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'What do you want to know?',
                  filled: true,
                  fillColor: const Color(0xFFF5F0EB),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
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
                    Navigator.pop(context);
                    await widget.service.askQuestion(
                      body: bodyCtrl.text.trim(),
                      city: cityCtrl.text.trim(),
                    );
                    _fetch();
                  },
                  child: const Text('Ask'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    for (final c in _answerCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        automaticallyImplyLeading: false,
        title: const Text('Q&A',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildTopControls(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetch,
                    child: _filtered.isEmpty
                        ? const Center(
                            child: Text('No questions here yet.',
                                style: TextStyle(color: Color(0xFF7A8B9A))))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => _buildQuestionTile(i),
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAskSheet,
        backgroundColor: const Color(0xFFE8944A),
        child: const Icon(Icons.help_outline, color: Colors.white),
      ),
    );
  }

  Widget _buildTopControls() {
    const tabs = ['hot', 'unanswered', 'mine'];
    const labels = {'hot': 'Hot', 'unanswered': 'Unanswered', 'mine': 'My Questions'};
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => _applySearch(),
            decoration: InputDecoration(
              hintText: 'Search questions...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF7A8B9A)),
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF5F0EB),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: tabs.map((t) {
              final selected = _activeTab == t;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _activeTab = t);
                    _fetch();
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: t != tabs.last ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF1A3A5C)
                          : const Color(0xFFF5F0EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(labels[t]!,
                          style: TextStyle(
                              color: selected ? Colors.white : const Color(0xFF1A3A5C),
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionTile(int index) {
    final q = _filtered[index];
    final isExpanded = _expandedIndex == index;
    _answerCtrls.putIfAbsent(index, () => TextEditingController());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(
                () => _expandedIndex = isExpanded ? null : index),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q.body,
                      maxLines: isExpanded ? null : 2,
                      overflow: isExpanded ? null : TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF1A3A5C), height: 1.4)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _chip('${q.answerCount} answers', const Color(0xFF1A3A5C)),
                      const SizedBox(width: 6),
                      _chip(q.city, const Color(0xFF7A8B9A)),
                      if (q.isSolved) ...[
                        const SizedBox(width: 6),
                        _chip('✓ Solved', const Color(0xFF2E8B8B)),
                      ],
                      const Spacer(),
                      Text(relativeTime(q.createdAt),
                          style: const TextStyle(fontSize: 11,
                              color: Color(0xFF7A8B9A))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add an answer',
                      style: TextStyle(fontWeight: FontWeight.w600,
                          color: Color(0xFF1A3A5C))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _answerCtrls[index],
                          decoration: InputDecoration(
                            hintText: 'Write your answer...',
                            isDense: true,
                            filled: true,
                            fillColor: const Color(0xFFF5F0EB),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A3A5C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final text = _answerCtrls[index]?.text.trim() ?? '';
                          if (text.isEmpty) return;
                          await widget.service.postAnswer(q.id, text);
                          _answerCtrls[index]?.clear();
                          _fetch();
                        },
                        child: const Text('Send'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 11, color: color,
                fontWeight: FontWeight.w600)),
      );
}
