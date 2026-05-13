import 'package:flutter/material.dart';
import '../models/helper_model.dart';
import 'request_help_screen.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';

class HelperDetailScreen extends StatelessWidget {
  final Helper helper;
  const HelperDetailScreen({super.key, required this.helper});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF1A3A5C),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A3A5C), Color(0xFF2E8B8B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: const Color(0xFFE8944A),
                        child: Text(
                          helper.firstName.isNotEmpty ? helper.firstName[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(helper.fullName,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          if (helper.isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, color: Colors.lightBlueAccent, size: 20),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(
                    children: [
                      _statCard('⭐', helper.ratingAvg.toStringAsFixed(1), 'Rating'),
                      const SizedBox(width: 12),
                      _statCard('✅', '${helper.totalReviews}', 'Reviews'),
                      const SizedBox(width: 12),
                      _statCard('💰', helper.hourlyRate != null ? '€${helper.hourlyRate!.toStringAsFixed(0)}/h' : 'Free', 'Rate'),
                    ],
                  ),

                  const SizedBox(height: 20),

                  if (helper.city.isNotEmpty)
                    _infoRow(Icons.location_on_outlined, '${helper.city}, ${helper.country}'),
                  if (helper.originCountry.isNotEmpty)
                    _infoRow(Icons.flag_outlined, 'From: ${helper.originCountry}'),

                  const SizedBox(height: 20),

                  if (helper.bio.isNotEmpty) ...[
                    const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
                    const SizedBox(height: 8),
                    Text(helper.bio, style: const TextStyle(color: Color(0xFF4A5568), height: 1.6)),
                    const SizedBox(height: 20),
                  ],

                  if (helper.specialties.isNotEmpty) ...[
                    const Text('Specialties', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: helper.specialties.map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8944A).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE8944A).withOpacity(0.3)),
                        ),
                        child: Text('${s.icon} ${s.name}',
                            style: const TextStyle(color: Color(0xFFE8944A), fontWeight: FontWeight.w600)),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Request Help button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                        onPressed: () async {
                        final chatService = ChatService();
                        final authService = AuthService();
                        final me = await authService.getMe();
                        if (me == null) return;
                        final conversation = await chatService.getOrCreateConversation(helper.id);
                        if (conversation == null) return;
                        if (context.mounted) {
                            Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                conversationId: conversation['id'],
                                helperName: helper.fullName,
                                currentUserId: me['id'],
                                ),
                            ),
                            );
                        }
                        },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Request Help', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8944A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A3A5C))),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF7A8B9A))),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF7A8B9A)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Color(0xFF4A5568))),
        ],
      ),
    );
  }
}