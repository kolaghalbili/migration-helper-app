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
