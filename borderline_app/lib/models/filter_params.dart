class FilterParams {
  final String city;
  final String selectedCategory;
  final double maxRate;
  final double minRating;
  final bool verifiedOnly;
  final String nationalityMatch; // 'any' | 'same' | 'arabic'
  final bool languageMatch;

  const FilterParams({
    this.city             = '',
    this.selectedCategory = '',
    this.maxRate          = 200,
    this.minRating        = 0,
    this.verifiedOnly     = false,
    this.nationalityMatch = 'any',
    this.languageMatch    = false,
  });

  FilterParams copyWith({
    String? city,
    String? selectedCategory,
    double? maxRate,
    double? minRating,
    bool?   verifiedOnly,
    String? nationalityMatch,
    bool?   languageMatch,
  }) => FilterParams(
        city:             city             ?? this.city,
        selectedCategory: selectedCategory ?? this.selectedCategory,
        maxRate:          maxRate          ?? this.maxRate,
        minRating:        minRating        ?? this.minRating,
        verifiedOnly:     verifiedOnly     ?? this.verifiedOnly,
        nationalityMatch: nationalityMatch ?? this.nationalityMatch,
        languageMatch:    languageMatch    ?? this.languageMatch,
      );

  static const FilterParams defaults = FilterParams();

  int get activeCount {
    int n = 0;
    if (city.isNotEmpty)             n++;
    if (selectedCategory.isNotEmpty) n++;
    if (maxRate < 200)               n++;
    if (minRating > 0)               n++;
    if (verifiedOnly)                n++;
    if (nationalityMatch != 'any')   n++;
    if (languageMatch)               n++;
    return n;
  }
}
