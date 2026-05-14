class Review {
  final int id;
  final int reviewer;
  final String reviewerName;
  final String? reviewerImage;
  final int rating;
  final List<String> tags;
  final String note;
  final String createdAt;

  Review({
    required this.id,
    required this.reviewer,
    required this.reviewerName,
    this.reviewerImage,
    required this.rating,
    required this.tags,
    required this.note,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] ?? 0,
        reviewer: json['reviewer'] ?? 0,
        reviewerName: json['reviewer_name'] ?? '',
        reviewerImage: json['reviewer_image'],
        rating: json['rating'] ?? 0,
        tags: (json['tags'] as List? ?? []).map((t) => t.toString()).toList(),
        note: json['note'] ?? '',
        createdAt: json['created_at'] ?? '',
      );
}


class HelpRequest {
  final int id;
  final int newcomer;
  final String newcomerName;
  final int? helper;
  final String? helperName;
  final String category;
  final List<String> subTopics;
  final String description;
  final String package;
  final String status;
  final String createdAt;

  HelpRequest({
    required this.id,
    required this.newcomer,
    required this.newcomerName,
    this.helper,
    this.helperName,
    required this.category,
    required this.subTopics,
    required this.description,
    required this.package,
    required this.status,
    required this.createdAt,
  });

  factory HelpRequest.fromJson(Map<String, dynamic> json) => HelpRequest(
        id: json['id'] ?? 0,
        newcomer: json['newcomer'] ?? 0,
        newcomerName: json['newcomer_name'] ?? '',
        helper: json['helper'],
        helperName: json['helper_name'],
        category: json['category'] ?? '',
        subTopics: (json['sub_topics'] as List? ?? []).map((t) => t.toString()).toList(),
        description: json['description'] ?? '',
        package: json['package'] ?? '',
        status: json['status'] ?? 'pending',
        createdAt: json['created_at'] ?? '',
      );
}


class Specialty {
  final int id;
  final String name;
  final String icon;

  Specialty({required this.id, required this.name, required this.icon});

  factory Specialty.fromJson(Map<String, dynamic> json) => Specialty(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        icon: json['icon'] ?? '',
      );
}

class ProfileImage {
  final int id;
  final String? imageUrl;
  final int order;
  final bool isPrimary;

  ProfileImage({
    required this.id,
    this.imageUrl,
    required this.order,
    required this.isPrimary,
  });

  factory ProfileImage.fromJson(Map<String, dynamic> json) => ProfileImage(
        id: json['id'] ?? 0,
        imageUrl: json['image_url'],
        order: json['order'] ?? 0,
        isPrimary: json['is_primary'] ?? false,
      );
}

class Helper {
  final int id;
  final String firstName;
  final String lastName;
  final String? avatar;
  final String bio;
  final String city;
  final String country;
  final String nationality;
  final String originCountry;
  final List<String> languages;
  final double ratingAvg;
  final int totalReviews;
  final bool isVerified;
  final double? hourlyRate;
  final List<Specialty> specialties;
  final List<ProfileImage> profileImages;
  final double? latitude;
  final double? longitude;
  final String role;

  Helper({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatar,
    required this.bio,
    required this.city,
    required this.country,
    this.nationality = '',
    this.originCountry = '',
    this.languages = const [],
    required this.ratingAvg,
    required this.totalReviews,
    required this.isVerified,
    this.hourlyRate,
    required this.specialties,
    this.profileImages = const [],
    this.latitude,
    this.longitude,
    this.role = 'helper',
  });

  String get fullName => '$firstName $lastName'.trim();

  /// URL of the primary profile image, falling back to the legacy avatar field.
  String? get primaryImageUrl {
    final primary = profileImages.where((i) => i.isPrimary).firstOrNull;
    if (primary?.imageUrl != null) return primary!.imageUrl;
    if (profileImages.isNotEmpty) return profileImages.first.imageUrl;
    return avatar;
  }

  factory Helper.fromJson(Map<String, dynamic> json) => Helper(
        id: json['id'] ?? 0,
        firstName: json['first_name'] ?? '',
        lastName: json['last_name'] ?? '',
        avatar: json['avatar'],
        bio: json['bio'] ?? '',
        city: json['city'] ?? '',
        country: json['country'] ?? '',
        nationality: json['nationality'] ?? '',
        originCountry: json['origin_country'] ?? '',
        languages: (json['languages'] as List? ?? []).map((l) => l.toString()).toList(),
        ratingAvg: double.tryParse(json['rating_avg'].toString()) ?? 0.0,
        totalReviews: json['total_reviews'] ?? 0,
        isVerified: json['is_verified'] ?? false,
        hourlyRate: json['hourly_rate'] != null
            ? double.tryParse(json['hourly_rate'].toString())
            : null,
        specialties: (json['specialties'] as List? ?? [])
            .map((s) => Specialty.fromJson(s as Map<String, dynamic>))
            .toList(),
        profileImages: (json['profile_images'] as List? ?? [])
            .map((i) => ProfileImage.fromJson(i as Map<String, dynamic>))
            .toList(),
        latitude: json['latitude'] != null
            ? double.tryParse(json['latitude'].toString())
            : null,
        longitude: json['longitude'] != null
            ? double.tryParse(json['longitude'].toString())
            : null,
        role: json['role'] ?? 'helper',
      );
}
