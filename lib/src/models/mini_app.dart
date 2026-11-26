class MiniApp {
  const MiniApp({
    required this.id,
    required this.name,
    required this.description,
    required this.launchUrl,
    required this.category,
    this.iconUrl,
    this.developer = 'Independent developer',
    this.rating = 4.5,
    this.featured = false,
    this.coverImageUrl,
    this.shortDescription,
    this.privacyPolicyUrl,
    this.supportUrl,
    this.keywords,
    this.canonicalUrl,
    this.language,
    this.themeColor,
    this.screenshotUrls = const [],
    this.packagePath,
  });

  final String id;
  final String name;
  final String description;
  final String launchUrl;
  final String category;
  final String? iconUrl;
  final String developer;
  final double rating;
  final bool featured;

  // Additional store listing metadata. All are optional for backward compatibility.
  final String? coverImageUrl;
  final String? shortDescription;
  final String? privacyPolicyUrl;
  final String? supportUrl;
  final String? keywords;
  final String? canonicalUrl;
  final String? language;
  final String? themeColor;
  final List<String> screenshotUrls;
  /// Local absolute path to an extracted package index.html (mobile/desktop).
  final String? packagePath;

  MiniApp copyWith({
    String? id,
    String? name,
    String? description,
    String? launchUrl,
    String? category,
    String? iconUrl,
    String? developer,
    double? rating,
    bool? featured,
    String? coverImageUrl,
    String? shortDescription,
    String? privacyPolicyUrl,
    String? supportUrl,
    String? keywords,
    String? canonicalUrl,
    String? language,
    String? themeColor,
    List<String>? screenshotUrls,
    String? packagePath,
  }) =>
      MiniApp(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        launchUrl: launchUrl ?? this.launchUrl,
        category: category ?? this.category,
        iconUrl: iconUrl ?? this.iconUrl,
        developer: developer ?? this.developer,
        rating: rating ?? this.rating,
        featured: featured ?? this.featured,
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
        shortDescription: shortDescription ?? this.shortDescription,
        privacyPolicyUrl: privacyPolicyUrl ?? this.privacyPolicyUrl,
        supportUrl: supportUrl ?? this.supportUrl,
        keywords: keywords ?? this.keywords,
        canonicalUrl: canonicalUrl ?? this.canonicalUrl,
        language: language ?? this.language,
        themeColor: themeColor ?? this.themeColor,
        screenshotUrls: screenshotUrls ?? this.screenshotUrls,
        packagePath: packagePath ?? this.packagePath,
      );
}
