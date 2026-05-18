import 'package:dio/dio.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../models/community_model.dart';
import 'community_service.dart';

class CommunityServiceImpl implements CommunityService {
  final _dio = Dio();
  final String _base = 'http://127.0.0.1:8000/api';

  Options get _auth => Options(
    headers: {'Authorization': 'Bearer ${html.window.localStorage['access']}'},
  );

  @override
  Future<List<CommunityPost>> getPosts({String? city, String? type}) async {
    try {
      final params = <String, dynamic>{};
      if (city != null && city.isNotEmpty) params['city'] = city;
      if (type != null && type != 'all')  params['type'] = type;
      final r = await _dio.get('$_base/community/posts/',
          queryParameters: params, options: _auth);
      final list = r.data is List ? r.data as List : r.data['results'] as List;
      return list.map((j) => CommunityPost.fromJson(j)).toList();
    } catch (_) { return []; }
  }

  @override
  Future<Map<String, dynamic>?> toggleLike(int postId) async {
    try {
      final r = await _dio.post('$_base/community/posts/$postId/like/', options: _auth);
      return r.data as Map<String, dynamic>;
    } catch (_) { return null; }
  }

  @override
  Future<CommunityPost?> createPost({
    required String postType,
    required String body,
    required String city,
    List<String> tags = const [],
  }) async {
    try {
      final r = await _dio.post('$_base/community/posts/',
          data: {'post_type': postType, 'body': body, 'city': city, 'tags': tags},
          options: _auth);
      return CommunityPost.fromJson(r.data);
    } catch (_) { return null; }
  }

  @override
  Future<List<Meetup>> getMeetups({String? city}) async {
    try {
      final params = city != null && city.isNotEmpty ? {'city': city} : null;
      final r = await _dio.get('$_base/community/meetups/',
          queryParameters: params, options: _auth);
      final list = r.data is List ? r.data as List : r.data['results'] as List;
      return list.map((j) => Meetup.fromJson(j)).toList();
    } catch (_) { return []; }
  }

  @override
  Future<Map<String, dynamic>?> toggleRSVP(int meetupId) async {
    try {
      final r = await _dio.post('$_base/community/meetups/$meetupId/rsvp/', options: _auth);
      return r.data as Map<String, dynamic>;
    } catch (_) { return null; }
  }

  @override
  Future<List<CommunityQuestion>> getQuestions({String? city, String? tab}) async {
    try {
      final params = <String, dynamic>{};
      if (city != null && city.isNotEmpty) params['city'] = city;
      if (tab  != null && tab  != 'hot')   params['tab']  = tab;
      final r = await _dio.get('$_base/community/questions/',
          queryParameters: params, options: _auth);
      final list = r.data is List ? r.data as List : r.data['results'] as List;
      return list.map((j) => CommunityQuestion.fromJson(j)).toList();
    } catch (_) { return []; }
  }

  @override
  Future<bool> postAnswer(int questionId, String body) async {
    try {
      await _dio.post('$_base/community/questions/$questionId/answers/',
          data: {'body': body}, options: _auth);
      return true;
    } catch (_) { return false; }
  }

  @override
  Future<CommunityQuestion?> askQuestion({
    required String body,
    required String city,
    List<String> tags = const [],
  }) async {
    try {
      final r = await _dio.post('$_base/community/questions/',
          data: {'body': body, 'city': city, 'tags': tags}, options: _auth);
      return CommunityQuestion.fromJson(r.data);
    } catch (_) { return null; }
  }

  @override
  Future<List<CommunityCircle>> getCircles() async {
    try {
      final r = await _dio.get('$_base/community/circles/', options: _auth);
      final list = r.data is List ? r.data as List : r.data['results'] as List;
      return list.map((j) => CommunityCircle.fromJson(j)).toList();
    } catch (_) { return []; }
  }

  @override
  Future<Map<String, dynamic>?> toggleCircleSubscription(int circleId) async {
    try {
      final r = await _dio.patch(
          '$_base/community/circles/$circleId/subscribe/', options: _auth);
      return r.data as Map<String, dynamic>;
    } catch (_) { return null; }
  }
}
