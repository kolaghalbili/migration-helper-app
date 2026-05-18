import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:borderline_app/models/community_model.dart';
import 'package:borderline_app/services/community_service.dart';
import 'package:borderline_app/screens/community/community_feed_screen.dart';
import 'package:borderline_app/screens/community/circles_screen.dart';

class _FakeCommunityService implements CommunityService {
  @override
  Future<List<CommunityPost>> getPosts({String? city, String? type}) async => [
        CommunityPost(
          id: 1, author: 1, authorName: 'Ali', postType: 'need',
          body: 'I need help with banking', tags: ['banking'],
          city: 'Berlin', likeCount: 2, isLiked: false,
          createdAt: '2026-01-01T00:00:00Z',
        ),
      ];

  @override
  Future<List<CommunityCircle>> getCircles() async => [
        CommunityCircle(
          id: 1, name: 'Iranians in Berlin', description: '',
          nationalityCode: 'IR', languageCode: 'fa',
          memberCount: 342, isSubscribed: true,
        ),
      ];

  @override
  Future<Map<String, dynamic>?> toggleLike(int postId) async =>
      {'liked': true, 'like_count': 3};

  @override
  Future<Map<String, dynamic>?> toggleCircleSubscription(int id) async =>
      {'subscribed': false, 'member_count': 341};

  @override
  Future<List<Meetup>> getMeetups({String? city}) async => [];

  @override
  Future<List<CommunityQuestion>> getQuestions(
      {String? city, String? tab}) async => [];

  @override
  Future<bool> postAnswer(int qId, String body) async => true;

  @override
  Future<CommunityPost?> createPost({
    required String postType,
    required String body,
    required String city,
    List<String> tags = const [],
  }) async => null;

  @override
  Future<CommunityQuestion?> askQuestion({
    required String body,
    required String city,
    List<String> tags = const [],
  }) async => null;

  @override
  Future<Map<String, dynamic>?> toggleRSVP(int id) async => null;
}

void main() {
  testWidgets('CommunityFeedScreen shows post body', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CommunityFeedScreen(service: _FakeCommunityService()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('I need help with banking'), findsOneWidget);
  });

  testWidgets('CirclesScreen shows circle name', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CirclesScreen(service: _FakeCommunityService()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Iranians in Berlin'), findsOneWidget);
  });

  testWidgets('Like button updates count optimistically', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CommunityFeedScreen(service: _FakeCommunityService()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pump();
    expect(find.text('3'), findsOneWidget);
  });
}
