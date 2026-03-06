class GiftProduct {
  final String id;
  final String category;
  final String title;
  /// Original price (before discount)
  final int price;

  /// Discounted price (optional). If null, [price] is used.
  final int? discountedPrice;

  /// Optional seller/location (city/state) if you want to show where it ships from.
  final String? location;

  /// Multiple images for the gift (assets or network urls).
  final List<String> images;
  final double rating;

  const GiftProduct({
    required this.id,
    required this.category,
    required this.title,
    required this.price,
    this.discountedPrice,
    this.location,
    this.images = const [],
    required this.rating,
  });

  int get effectivePrice => discountedPrice ?? price;

  String get primaryImage => images.isNotEmpty ? images.first : 'assets/images/sample.jpg';
}
