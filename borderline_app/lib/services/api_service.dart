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

  Future<List<Helper>> getHelpers() async {
    try {
      final token = _getToken();

      final response = await _dio.get(
        '$baseUrl/helpers/',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      print("=== جواب از جنگو ===");
      print(response.data);

      List<dynamic> data;
      if (response.data is Map && response.data.containsKey('results')) {
        data = response.data['results'];
      } else {
        data = response.data;
      }

      return data.map((json) => Helper.fromJson(json)).toList();
    } catch (e) {
      print("=== ارور ===");
      print(e);
      return [];
    }
  }
}