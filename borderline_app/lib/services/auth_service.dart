import 'package:dio/dio.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class AuthService {
  final Dio _dio = Dio();
  final String baseUrl = "http://127.0.0.1:8000/api";

  void _saveToken(String key, String value) {
    html.window.localStorage[key] = value;
  }

  String? _getToken(String key) {
    return html.window.localStorage[key];
  }

  void _deleteToken(String key) {
    html.window.localStorage.remove(key);
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '$baseUrl/auth/login/',
        data: {'email': email, 'password': password},
      );
      if (response.statusCode == 200) {
        _saveToken('access', response.data['access']);
        _saveToken('refresh', response.data['refresh']);
        return true;
      }
      return false;
    } catch (e) {
      print("Login error: $e");
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/auth/register/',
        data: {
          'email': email,
          'password': password,
          'password2': password,
          'first_name': firstName,
          'last_name': lastName,
          'role': role,
        },
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Register error: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getMe() async {
    try {
      final token = _getToken('access');
      final response = await _dio.get(
        '$baseUrl/users/me/',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } catch (e) {
      print("GetMe error: $e");
      return null;
    }
  }

  Future<void> logout() async {
    _deleteToken('access');
    _deleteToken('refresh');
  }

  Future<bool> isLoggedIn() async {
    return _getToken('access') != null;
  }
}