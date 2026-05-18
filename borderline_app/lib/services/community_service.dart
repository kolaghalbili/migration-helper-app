import '../models/community_model.dart';

abstract class CommunityService {
  Future<List<CommunityPost>> getPosts({String? city, String? type});
  Future<Map<String, dynamic>?> toggleLike(int postId);
  Future<CommunityPost?> createPost({
    required String postType,
    required String body,
    required String city,
    List<String> tags = const [],
  });
  Future<List<Meetup>> getMeetups({String? city});
  Future<Map<String, dynamic>?> toggleRSVP(int meetupId);
  Future<List<CommunityQuestion>> getQuestions({String? city, String? tab});
  Future<bool> postAnswer(int questionId, String body);
  Future<CommunityQuestion?> askQuestion({
    required String body,
    required String city,
    List<String> tags = const [],
  });
  Future<List<CommunityCircle>> getCircles();
  Future<Map<String, dynamic>?> toggleCircleSubscription(int circleId);
}
