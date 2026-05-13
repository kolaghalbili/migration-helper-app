// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:dio/dio.dart';

class ChatService {
  final Dio _dio = Dio();
  final String baseUrl = "http://127.0.0.1:8000/api";
  final String wsUrl = "ws://127.0.0.1:8000/ws";

  String? _getToken() => html.window.localStorage['access'];

  // Get or create conversation with a helper
  Future<Map<String, dynamic>?> getOrCreateConversation(int otherUserId) async {
    try {
      final response = await _dio.post(
        '$baseUrl/conversations/create/',
        data: {'other_user_id': otherUserId},
        options: Options(headers: {'Authorization': 'Bearer ${_getToken()}'}),
      );
      return response.data;
    } catch (e) {
      print('Conversation error: $e');
      return null;
    }
  }

  // Get all conversations
  Future<List<dynamic>> getConversations() async {
    try {
      final response = await _dio.get(
        '$baseUrl/conversations/',
        options: Options(headers: {'Authorization': 'Bearer ${_getToken()}'}),
      );
      return response.data;
    } catch (e) {
      print('Conversations error: $e');
      return [];
    }
  }

  // Get messages for a conversation
  Future<List<dynamic>> getMessages(int conversationId) async {
    try {
      final response = await _dio.get(
        '$baseUrl/conversations/$conversationId/messages/',
        options: Options(headers: {'Authorization': 'Bearer ${_getToken()}'}),
      );
      return response.data;
    } catch (e) {
      print('Messages error: $e');
      return [];
    }
  }
}