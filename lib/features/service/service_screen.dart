import 'package:flutter/material.dart';

import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';
import '../../core/widgets/glass_container.dart';
import 'add_service_dialog.dart';
import 'service_data.dart';
import 'service_widgets.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  final _search = TextEditingController();

  // Filter state
  double _minRating = 0;
  double? _maxPrice;
  bool _onlyFeatured = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openAddService() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => AddServiceDialog(
        onAdded: () => setState(() {}),
      ),
    );
  }

  void _openFilters() {
    final maxCtrl = TextEditingController(text: _maxPrice?.toStringAsFixed(0) ?? '');
    var draftMinRating = _minRating;
    var draftOnlyFeatured = _onlyFeatured;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        final maxH = MediaQuery.of(context).size.height * 0.85;
        return SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 820, maxHeight: maxH),
              child: StatefulBuilder(
                builder: (context, setSheetState) {
                  return GlassContainer(
                    radius: 22,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Search Filter',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setSheetState(() {
                                    draftMinRating = 0;
                                    draftOnlyFeatured = false;
                                    maxCtrl.text = '';
                                  });
                                },
                                child: const Text('Clear'),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close, color: Colors.white70),
                              )
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text('Minimum Rating', style: TextStyle(color: Colors.white70)),
                          Slider(
                            value: draftMinRating,
                            min: 0,
                            max: 5,
                            divisions: 10,
                            onChanged: (v) => setSheetState(() => draftMinRating = v),
                          ),
                          Row(
                            children: [
                              Checkbox(
                                value: draftOnlyFeatured,
                                onChanged: (v) => setSheetState(() => draftOnlyFeatured = v ?? false),
                                activeColor: Colors.white,
                                checkColor: Colors.black,
                              ),
                              const Text('Only featured (recommended)', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('Max Starting Price', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 10),
                          TextField(
                            controller: maxCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'e.g. 200',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.55)),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.06),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.16)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.16)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.28)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _minRating = draftMinRating;
                                  _onlyFeatured = draftOnlyFeatured;
                                  _maxPrice = double.tryParse(maxCtrl.text.trim());
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  List<ServiceCategory> _filteredCategories() {
    final q = _search.text.trim().toLowerCase();
    final all = ServiceCatalog.categories;
    if (q.isEmpty) return all;
    return all
        .where((c) =>
            c.title.toLowerCase().contains(q) || c.subtitle.toLowerCase().contains(q))
        .toList();
  }

  List<DestinationService> _filteredRecommended() {
    final q = _search.text.trim().toLowerCase();
    var items = ServiceCatalog.destinations;

    items = items.where((d) {
      if (_minRating > 0 && d.rating < _minRating) return false;
      if (_maxPrice != null && d.startingPrice > _maxPrice!) return false;
      if (q.isEmpty) return true;
      return d.title.toLowerCase().contains(q) || d.city.toLowerCase().contains(q);
    }).toList();

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final cats = _filteredCategories();
    final rec = _filteredRecommended();
    return MainAppShell(
      currentRoute: AppRoutes.service,
      child: Stack(
        children: [
          // Soft starry overlay similar to your mocks.
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: Image.asset(
                'assets/images/sample.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(onAdd: _openAddService),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      'Services',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.92),
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ServiceSearchBar(
                    hint: 'Search booking services...',
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    onFilter: _openFilters,
                  ),
                  const SizedBox(height: 20),

                  // Category grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth >= 700 ? 3 : 2;
                      final cardHeight = constraints.maxWidth >= 700 ? 180.0 : 140.0;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cats.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: (constraints.maxWidth / crossAxisCount) / cardHeight,
                        ),
                        itemBuilder: (_, i) {
                          final item = cats[i];
                          return ServiceImageCard(
                            title: item.title,
                            subtitle: item.subtitle,
                            imageAsset: item.imageAsset,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                item.route,
                                arguments: {
                                  'entryTitle': item.title,
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 22),

                  Center(
                    child: PrimaryPillButton(
                      label: 'See All Services',
                      onTap: () {
                        // For now, keep same screen but you can connect this to a full catalog.
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('All services coming soon.')),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 26),
                  Text(
                    'Recommended',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.88),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _RecommendedRow(items: rec),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onAdd;

  const _TopBar({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Evening',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.white.withOpacity(0.75)),
                  const SizedBox(width: 4),
                  Text(
                    'Los Angeles, CA',
                    style: TextStyle(color: Colors.white.withOpacity(0.75)),
                  ),
                ],
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onAdd,
          child: GlassContainer(
            radius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
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
          borderRadius: BorderRadius.circular(22),
          child: Image.asset(
            'assets/images/profile.jpg',
            width: 38,
            height: 38,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}

class _RecommendedRow extends StatelessWidget {
  final List<DestinationService> items;

  const _RecommendedRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 135,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final d = items[i];
          return SizedBox(
            width: 260,
            child: ServiceImageCard(
              title: d.title,
              imageAsset: 'assets/images/sample.jpg',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.serviceDestinationDetail,
                  arguments: {'serviceId': d.id},
                );
              },
            ),
          );
        },
      ),
    );
  }
}
