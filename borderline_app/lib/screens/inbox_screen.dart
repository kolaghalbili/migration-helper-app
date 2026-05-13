// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final _chatService = ChatService();
  final _authService = AuthService();
  List<dynamic> _conversations = [];
  bool _isLoading = true;
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final me = await _authService.getMe();
    final conversations = await _chatService.getConversations();
    setState(() {
      _currentUser = me;
      _conversations = conversations;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        foregroundColor: Colors.white,
        title: const Text('Inbox 💬', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('📭', style: TextStyle(fontSize: 64)),
                      SizedBox(height: 16),
                      Text('No conversations yet.',
                          style: TextStyle(fontSize: 18, color: Color(0xFF7A8B9A))),
                      SizedBox(height: 8),
                      Text('Find a helper and request help!',
                          style: TextStyle(color: Color(0xFF7A8B9A))),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _conversations.length,
                    itemBuilder: (_, i) => _buildConversationCard(_conversations[i]),
                  ),
                ),
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> conversation) {
    final participants = conversation['participants'] as List? ?? [];
    final myId = _currentUser?['id'];

    // پیدا کردن طرف مقابل
    final other = participants.firstWhere(
      (p) => p['id'] != myId,
      orElse: () => participants.isNotEmpty ? participants[0] : {},
    );

    final otherName = '${other['first_name'] ?? ''} ${other['last_name'] ?? ''}'.trim();
    final lastMessage = conversation['last_message'];
    final lastContent = lastMessage != null ? lastMessage['content'] : 'No messages yet';
    final lastSender = lastMessage != null ? lastMessage['sender'] : '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversation['id'],
            helperName: otherName,
            currentUserId: myId ?? 0,
          ),
        ),
      ).then((_) => _loadData()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF1A3A5C).withOpacity(0.15),
              child: Text(
                otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C)),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherName.isNotEmpty ? otherName : 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A3A5C)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage != null ? '$lastSender: $lastContent' : 'No messages yet',
                    style: const TextStyle(color: Color(0xFF7A8B9A), fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right, color: Color(0xFF7A8B9A)),
          ],
        ),
      ),
    );
  }
}