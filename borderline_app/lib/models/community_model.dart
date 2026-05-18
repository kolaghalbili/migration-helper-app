class CommunityPost {
  final int id;
  final int author;
  final String authorName;
  final String? authorImage;
  final String postType;
  final String body;
  final List<String> tags;
  final String city;
  final int likeCount;
  final bool isLiked;
  final String createdAt;

  const CommunityPost({
    required this.id,
    required this.author,
    required this.authorName,
    this.authorImage,
    required this.postType,
    required this.body,
    required this.tags,
    required this.city,
    required this.likeCount,
    required this.isLiked,
    required this.createdAt,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> j) => CommunityPost(
        id:          j['id'] ?? 0,
        author:      j['author'] ?? 0,
        authorName:  j['author_name'] ?? '',
        authorImage: j['author_image'],
        postType:    j['post_type'] ?? 'need',
        body:        j['body'] ?? '',
        tags:        (j['tags'] as List? ?? []).map((t) => t.toString()).toList(),
        city:        j['city'] ?? '',
        likeCount:   j['like_count'] ?? 0,
        isLiked:     j['is_liked'] ?? false,
        createdAt:   j['created_at'] ?? '',
      );

  CommunityPost copyWith({int? likeCount, bool? isLiked}) => CommunityPost(
        id: id, author: author, authorName: authorName, authorImage: authorImage,
        postType: postType, body: body, tags: tags, city: city,
        createdAt: createdAt,
        likeCount: likeCount ?? this.likeCount,
        isLiked:   isLiked   ?? this.isLiked,
      );
}

class Meetup {
  final int id;
  final String title;
  final String city;
  final String location;
  final String date;
  final String time;
  final String organizerName;
  final int attendeeCount;
  final bool isAttending;

  const Meetup({
    required this.id,
    required this.title,
    required this.city,
    required this.location,
    required this.date,
    required this.time,
    required this.organizerName,
    required this.attendeeCount,
    required this.isAttending,
  });

  factory Meetup.fromJson(Map<String, dynamic> j) => Meetup(
        id:            j['id'] ?? 0,
        title:         j['title'] ?? '',
        city:          j['city'] ?? '',
        location:      j['location'] ?? '',
        date:          j['date'] ?? '',
        time:          j['time'] ?? '',
        organizerName: j['organizer_name'] ?? '',
        attendeeCount: j['attendee_count'] ?? 0,
        isAttending:   j['is_attending'] ?? false,
      );

  Meetup copyWith({int? attendeeCount, bool? isAttending}) => Meetup(
        id: id, title: title, city: city, location: location,
        date: date, time: time, organizerName: organizerName,
        attendeeCount: attendeeCount ?? this.attendeeCount,
        isAttending:   isAttending   ?? this.isAttending,
      );
}

class CommunityQuestion {
  final int id;
  final String authorName;
  final String body;
  final String city;
  final List<String> tags;
  final bool isSolved;
  final int answerCount;
  final String createdAt;

  const CommunityQuestion({
    required this.id,
    required this.authorName,
    required this.body,
    required this.city,
    required this.tags,
    required this.isSolved,
    required this.answerCount,
    required this.createdAt,
  });

  factory CommunityQuestion.fromJson(Map<String, dynamic> j) => CommunityQuestion(
        id:          j['id'] ?? 0,
        authorName:  j['author_name'] ?? '',
        body:        j['body'] ?? '',
        city:        j['city'] ?? '',
        tags:        (j['tags'] as List? ?? []).map((t) => t.toString()).toList(),
        isSolved:    j['is_solved'] ?? false,
        answerCount: j['answer_count'] ?? 0,
        createdAt:   j['created_at'] ?? '',
      );
}

class CommunityCircle {
  final int id;
  final String name;
  final String description;
  final String nationalityCode;
  final String languageCode;
  final int memberCount;
  bool isSubscribed;

  CommunityCircle({
    required this.id,
    required this.name,
    required this.description,
    required this.nationalityCode,
    required this.languageCode,
    required this.memberCount,
    required this.isSubscribed,
  });

  factory CommunityCircle.fromJson(Map<String, dynamic> j) => CommunityCircle(
        id:              j['id'] ?? 0,
        name:            j['name'] ?? '',
        description:     j['description'] ?? '',
        nationalityCode: j['nationality_code'] ?? '',
        languageCode:    j['language_code'] ?? '',
        memberCount:     j['member_count'] ?? 0,
        isSubscribed:    j['is_subscribed'] ?? false,
      );
}
