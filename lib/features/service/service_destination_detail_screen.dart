import 'package:flutter/material.dart';

import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';
import '../../core/widgets/glass_container.dart';
import 'service_data.dart';
import 'add_service_dialog.dart';
import 'service_widgets.dart';

class ServiceDestinationDetailScreen extends StatelessWidget {
  final DestinationService service;

  const ServiceDestinationDetailScreen({super.key, required this.service});

  static void _noop() {}

  static ServiceDestinationDetailScreen fromRoute(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map ? args : const {};
    final serviceId = (map['serviceId'] ?? 'paris_photo_tour').toString();
    final service = ServiceCatalog.byId(serviceId);
    return ServiceDestinationDetailScreen(service: service);
  }

  @override
  Widget build(BuildContext context) {
    return MainAppShell(
      currentRoute: AppRoutes.service,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Text(
                    'Destination > ${service.city}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        barrierColor: Colors.black54,
                        builder: (_) => const AddServiceDialog(onAdded: _noop),
                      );
                    },
                    child: const GlassContainer(
                      radius: 18,
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white70, size: 18),
                          SizedBox(width: 6),
                          Text('Add Service', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.notifications_none, color: Colors.white.withOpacity(0.85)),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/images/profile.jpg',
                      width: 34,
                      height: 34,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    Image.asset(
                      service.heroImageAsset,
                      width: double.infinity,
                      height: 230,
                      fit: BoxFit.cover,
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.15),
                              Colors.black.withOpacity(0.55),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.star, size: 18, color: Colors.amber.shade300),
                              const SizedBox(width: 6),
                              Text(
                                '${service.rating.toStringAsFixed(1)}  (${service.reviews})',
                                style: TextStyle(color: Colors.white.withOpacity(0.85)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            service.description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: Text(
                  'Highlighted Photo Spots ✨',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cross = constraints.maxWidth >= 700 ? 3 : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: service.spots.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cross,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.55,
                    ),
                    itemBuilder: (_, i) {
                      final spot = service.spots[i];
                      return ServiceImageCard(
                        title: spot.title,
                        imageAsset: spot.imageAsset,
                        onTap: () {
                          // You can navigate to a dedicated spot page later.
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Selected: ${spot.title}')),
                          );
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Recommended Photographers ✨',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...service.photographers.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: GlassContainer(
                    radius: 20,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            p.avatarAsset,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.star, size: 16, color: Colors.amber.shade300),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${p.rating.toStringAsFixed(1)}  (${p.reviews})',
                                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PrimaryPillButton(
                          label: 'Book Now',
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.serviceBooking,
                              arguments: {
                                'serviceId': service.id,
                                'photographerId': p.id,
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
