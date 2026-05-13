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

class Helper {
  final int id;
  final String firstName;
  final String lastName;
  final String? avatar;
  final String bio;
  final String city;
  final String country;
  final String originCountry;
  final double ratingAvg;
  final int totalReviews;
  final bool isVerified;
  final double? hourlyRate;
  final List<Specialty> specialties;

  Helper({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatar,
    required this.bio,
    required this.city,
    required this.country,
    required this.originCountry,
    required this.ratingAvg,
    required this.totalReviews,
    required this.isVerified,
    this.hourlyRate,
    required this.specialties,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory Helper.fromJson(Map<String, dynamic> json) => Helper(
        id: json['id'] ?? 0,
        firstName: json['first_name'] ?? '',
        lastName: json['last_name'] ?? '',
        avatar: json['avatar'],
        bio: json['bio'] ?? '',
        city: json['city'] ?? '',
        country: json['country'] ?? '',
        originCountry: json['origin_country'] ?? '',
        ratingAvg: double.tryParse(json['rating_avg'].toString()) ?? 0.0,
        totalReviews: json['total_reviews'] ?? 0,
        isVerified: json['is_verified'] ?? false,
        hourlyRate: json['hourly_rate'] != null
            ? double.tryParse(json['hourly_rate'].toString())
            : null,
        specialties: (json['specialties'] as List? ?? [])
            .map((s) => Specialty.fromJson(s))
            .toList(),
      );
}