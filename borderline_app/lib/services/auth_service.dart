import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class AuthService {
  final Dio _dio = Dio();
  final String baseUrl = 'http://127.0.0.1:8000/api';

  // ── Token helpers ──────────────────────────────────────────────────────────

  void _saveToken(String key, String value) =>
      html.window.localStorage[key] = value;

  String? _getToken(String key) => html.window.localStorage[key];

  void _deleteToken(String key) => html.window.localStorage.remove(key);

  String? get _accessToken => _getToken('access');

  Options get _authHeader =>
      Options(headers: {'Authorization': 'Bearer $_accessToken'});

  // ── Auth ───────────────────────────────────────────────────────────────────

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
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    String nationality = '',
    String country = '',
    String city = '',
    List<String> languages = const [],
    String bio = '',
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
          'nationality': nationality,
          'country': country,
          'city': city,
          'languages': languages,
          'bio': bio,
        },
      );
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getMe() async {
    try {
      final response = await _dio.get(
        '$baseUrl/users/me/',
        options: _authHeader,
      );
      return response.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    _deleteToken('access');
    _deleteToken('refresh');
  }

  Future<bool> isLoggedIn() async => _accessToken != null;

  // ── Profile images ─────────────────────────────────────────────────────────

  /// Upload one profile image. Returns the created image data or null on error.
  Future<Map<String, dynamic>?> uploadProfileImage(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          bytes,
          filename: file.name.isNotEmpty ? file.name : 'photo.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        ),
      });
      final response = await _dio.post(
        '$baseUrl/users/me/images/',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $_accessToken'}),
      );
      return response.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteProfileImage(int imageId) async {
    try {
      final response = await _dio.delete(
        '$baseUrl/users/me/images/$imageId/',
        options: _authHeader,
      );
      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setProfileImagePrimary(int imageId) async {
    try {
      final response = await _dio.patch(
        '$baseUrl/users/me/images/$imageId/set-primary/',
        options: _authHeader,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Location ───────────────────────────────────────────────────────────────

  Future<bool> updateLocation({
    double? latitude,
    double? longitude,
    String city = '',
    String country = '',
    bool? trackingEnabled,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (latitude != null) data['latitude'] = latitude;
      if (longitude != null) data['longitude'] = longitude;
      if (city.isNotEmpty) data['city'] = city;
      if (country.isNotEmpty) data['country'] = country;
      if (trackingEnabled != null) data['location_tracking_enabled'] = trackingEnabled;

      final response = await _dio.patch(
        '$baseUrl/users/me/location/',
        data: data,
        options: _authHeader,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Public profile ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getUserProfile(int userId) async {
    try {
      final response = await _dio.get('$baseUrl/users/$userId/');
      return response.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Nearby users ───────────────────────────────────────────────────────────

  Future<List<dynamic>> getNearbyUsers({
    required double lat,
    required double lng,
    double radiusKm = 50,
    String? role,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'lat': lat,
        'lng': lng,
        'radius': radiusKm,
      };
      if (role != null) params['role'] = role;

      final response = await _dio.get(
        '$baseUrl/users/nearby/',
        queryParameters: params,
        options: _authHeader,
      );
      return response.data as List<dynamic>;
    } catch (_) {
      return [];
    }
  }

  // ── Update profile ─────────────────────────────────────────────────────────

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? bio,
    String? nationality,
    String? country,
    String? city,
    List<String>? languages,
    double? hourlyRate,
    bool? isAvailable,
    List<int>? specialtyIds,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (firstName != null)   data['first_name']   = firstName;
      if (lastName != null)    data['last_name']     = lastName;
      if (bio != null)         data['bio']           = bio;
      if (nationality != null) data['nationality']   = nationality;
      if (country != null)     data['country']       = country;
      if (city != null)        data['city']          = city;
      if (languages != null)   data['languages']     = languages;
      if (hourlyRate != null)  data['hourly_rate']   = hourlyRate;
      if (isAvailable != null) data['is_available']  = isAvailable;
      if (specialtyIds != null) data['specialty_ids'] = specialtyIds;

      final response = await _dio.patch(
        '$baseUrl/users/me/',
        data: data,
        options: _authHeader,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Reviews ────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getReviews(int userId) async {
    try {
      final response = await _dio.get('$baseUrl/users/$userId/reviews/');
      return response.data as List<dynamic>;
    } catch (_) {
      return [];
    }
  }

  Future<bool> hasReviewed(int userId) async {
    try {
      final response = await _dio.get(
        '$baseUrl/users/$userId/review/',
        options: _authHeader,
      );
      return (response.data as Map<String, dynamic>)['has_reviewed'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> submitReview({
    required int userId,
    required int rating,
    required List<String> tags,
    required String note,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/users/$userId/review/',
        data: {'rating': rating, 'tags': tags, 'note': note},
        options: _authHeader,
      );
      return response.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Help requests ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> createHelpRequest({
    required String category,
    required List<String> subTopics,
    required String description,
    required String package,
    int? helperId,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'category':    category,
        'sub_topics':  subTopics,
        'description': description,
        'package':     package,
      };
      if (helperId != null) data['helper'] = helperId;

      final response = await _dio.post(
        '$baseUrl/requests/',
        data: data,
        options: _authHeader,
      );
      return response.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<List<dynamic>> getMyRequests() async {
    try {
      final response = await _dio.get(
        '$baseUrl/requests/',
        options: _authHeader,
      );
      return response.data as List<dynamic>;
    } catch (_) {
      return [];
    }
  }

  Future<bool> updateRequestStatus(int requestId, String status) async {
    try {
      final response = await _dio.patch(
        '$baseUrl/requests/$requestId/status/',
        data: {'status': status},
        options: _authHeader,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
