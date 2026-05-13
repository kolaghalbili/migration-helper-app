// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final String helperName;
  final int currentUserId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.helperName,
    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = ChatService();

  List<Map<String, dynamic>> _messages = [];
  html.WebSocket? _webSocket;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    final wsUrl = 'ws://127.0.0.1:8000/ws/chat/${widget.conversationId}/';
    _webSocket = html.WebSocket(wsUrl);

    _webSocket!.onOpen.listen((_) {
      setState(() => _isConnected = true);
    });

    _webSocket!.onMessage.listen((event) {
      final data = json.decode(event.data);
      setState(() {
        _messages.add(data);
      });
      _scrollToBottom();
    });

    _webSocket!.onClose.listen((_) {
      setState(() => _isConnected = false);
    });
  }

  Future<void> _loadMessages() async {
    final msgs = await _chatService.getMessages(widget.conversationId);
    setState(() {
      _messages = msgs.map((m) => Map<String, dynamic>.from(m)).toList();
    });
    _scrollToBottom();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _webSocket == null) return;

    _webSocket!.send(json.encode({
      'message': text,
      'sender_id': widget.currentUserId,
    }));

    _messageController.clear();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE8944A),
              child: Text(
                widget.helperName.isNotEmpty ? widget.helperName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.helperName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  _isConnected ? 'Online' : 'Connecting...',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isConnected ? Colors.greenAccent : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text('No messages yet.\nSay hello! 👋',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF7A8B9A), fontSize: 16)),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _buildMessage(_messages[i]),
                  ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: const Color(0xFFF5F0EB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8944A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final isMe = msg['sender_id'] == widget.currentUserId ||
        (msg['sender'] != null && msg['sender']['id'] == widget.currentUserId);

    final senderName = msg['sender_name'] ??
        (msg['sender'] != null ? msg['sender']['first_name'] : '');

    final content = msg['message'] ?? msg['content'] ?? '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Text(senderName,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF7A8B9A))),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF1A3A5C) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)
                ],
              ),
              child: Text(
                content,
                style: TextStyle(
                  color: isMe ? Colors.white : const Color(0xFF1A3A5C),
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _webSocket?.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}