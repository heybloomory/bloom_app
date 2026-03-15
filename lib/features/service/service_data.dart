import '../../routes/app_routes.dart';

class ServiceCategory {
  final String id;
  final String title;
  final String subtitle;
  final String imageAsset;
  final String route;

  const ServiceCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.route,
  });
}

class DestinationService {
  final String id;
  final String city;
  final String title;
  final String description;
  final double rating;
  final int reviews;
  final String heroImageAsset;
  final List<ServiceSpot> spots;
  final List<ServicePhotographer> photographers;
  final double startingPrice;

  const DestinationService({
    required this.id,
    required this.city,
    required this.title,
    required this.description,
    required this.rating,
    required this.reviews,
    required this.heroImageAsset,
    required this.spots,
    required this.photographers,
    required this.startingPrice,
  });
}

class ServiceSpot {
  final String id;
  final String title;
  final String imageAsset;
  const ServiceSpot({
    required this.id,
    required this.title,
    required this.imageAsset,
  });
}

class ServicePhotographer {
  final String id;
  final String name;
  final double rating;
  final int reviews;
  final String avatarAsset;
  const ServicePhotographer({
    required this.id,
    required this.name,
    required this.rating,
    required this.reviews,
    required this.avatarAsset,
  });
}

// Demo content (keeps UI fully working).
// Replace with real API / Firestore data later.

class ServiceCatalog {
  static const String sampleImage = 'assets/images/sample.jpg';
  static const String profileImage = 'assets/images/profile.jpg';

  /// Mutable in-memory catalog (so "Add Service" can work without a backend).
  static final List<ServiceCategory> categories = [
    const ServiceCategory(
      id: 'photographers',
      title: 'Photographers',
      subtitle: 'Book a shoot',
      imageAsset: sampleImage,
      route: AppRoutes.serviceDestination,
    ),
    const ServiceCategory(
      id: 'destination',
      title: 'Destination',
      subtitle: 'Spot for Shoot',
      imageAsset: sampleImage,
      route: AppRoutes.serviceDestination,
    ),
    const ServiceCategory(
      id: 'vacation',
      title: 'Trips & Vacations',
      subtitle: 'Plan your getaway',
      imageAsset: sampleImage,
      route: AppRoutes.serviceDestination,
    ),
    const ServiceCategory(
      id: 'restaurant',
      title: 'Restaurants',
      subtitle: 'Dine & reserve',
      imageAsset: sampleImage,
      route: AppRoutes.serviceDestination,
    ),
    const ServiceCategory(
      id: 'beauty',
      title: 'Beauty & Wellness',
      subtitle: 'Spa, salon, more',
      imageAsset: sampleImage,
      route: AppRoutes.serviceDestination,
    ),
  ];

  static final List<DestinationService> destinations = [
    const DestinationService(
      id: 'paris_photo_tour',
      city: 'Paris',
      title: 'Paris Photo Tour',
      description:
          'Capture romantic moments with a professional photographer at iconic Parisian locations.',
      rating: 4.9,
      reviews: 832,
      heroImageAsset: sampleImage,
      spots: [
        ServiceSpot(id: 'pont', title: 'Pont de Bir-Hakeim', imageAsset: sampleImage),
        ServiceSpot(id: 'eiffel', title: 'Eiffel Tower', imageAsset: sampleImage),
        ServiceSpot(id: 'louvre', title: 'Louvre Museum', imageAsset: sampleImage),
        ServiceSpot(id: 'mont', title: 'Montmartre', imageAsset: sampleImage),
        ServiceSpot(id: 'sacre', title: 'Sacré-Cœur', imageAsset: sampleImage),
      ],
      photographers: [
        ServicePhotographer(
          id: 'alex_moreau',
          name: 'Alex Moreau',
          rating: 4.8,
          reviews: 412,
          avatarAsset: profileImage,
        ),
      ],
      startingPrice: 150.0,
    ),
  ];

  static DestinationService byId(String id) {
    return destinations.firstWhere((d) => d.id == id, orElse: () => destinations.first);
  }

  static void addDestination(DestinationService service) {
    destinations.insert(0, service);
  }
}
