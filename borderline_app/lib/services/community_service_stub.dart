import '../models/community_model.dart';
import 'community_service.dart';

class CommunityServiceStub implements CommunityService {
  @override Future<List<CommunityPost>> getPosts({String? city, String? type}) async => [];
  @override Future<Map<String, dynamic>?> toggleLike(int postId) async => null;
  @override Future<CommunityPost?> createPost({required String postType, required String body, required String city, List<String> tags = const []}) async => null;
  @override Future<List<Meetup>> getMeetups({String? city}) async => [];
  @override Future<Map<String, dynamic>?> toggleRSVP(int meetupId) async => null;
  @override Future<List<CommunityQuestion>> getQuestions({String? city, String? tab}) async => [];
  @override Future<bool> postAnswer(int questionId, String body) async => false;
  @override Future<CommunityQuestion?> askQuestion({required String body, required String city, List<String> tags = const []}) async => null;
  @override Future<List<CommunityCircle>> getCircles() async => [];
  @override Future<Map<String, dynamic>?> toggleCircleSubscription(int circleId) async => null;
}
