import 'package:dio/dio.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../models/helper_model.dart';

class ApiService {
  final Dio _dio = Dio();
  final String baseUrl = "http://127.0.0.1:8000/api";

  String? _getToken() {
    return html.window.localStorage['access'];
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
}