import 'package:dio/dio.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../models/helper_model.dart';

class ApiService {
  final Dio _dio = Dio();
  final String baseUrl = "http://127.0.0.1:8000/api";

  String? _getToken() {
    try {
      return html.window.localStorage['access'];
    } catch (_) {
      return null;
    }
  }

  Future<List<Helper>> getHelpers({
    String? city,
    String? search,
  }) async {
    try {
      final token = _getToken();
      final Map<String, dynamic> params = {};
      if (city != null && city.isNotEmpty) params['city'] = city;
      if (search != null && search.isNotEmpty) params['search'] = search;

      final response = await _dio.get(
        '$baseUrl/helpers/',
        queryParameters: params.isEmpty ? null : params,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      List<dynamic> data;
      if (response.data is Map && response.data.containsKey('results')) {
        data = response.data['results'];
      } else {
        data = response.data;
      }

      return data.map((json) => Helper.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> createConversation(int helperId) async {
    try {
      final token = _getToken();
      final response = await _dio.post(
        '$baseUrl/conversations/create/',
        data: {'helper_id': helperId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateRequestStatus(int requestId, String newStatus) async {
    try {
      final token = _getToken();
      await _dio.patch(
        '$baseUrl/requests/$requestId/status/',
        data: {'status': newStatus},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<int?> getOrCreateConversation(int userId) async {
    try {
      final token = _getToken();
      final r = await _dio.post(
        '$baseUrl/conversations/create/',
        data: {'user_id': userId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return r.data['id'] as int?;
    } catch (_) {
      return null;
    }
  }
}