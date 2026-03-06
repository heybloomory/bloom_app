import 'package:flutter/material.dart';

import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';
import '../../core/widgets/glass_container.dart';
import 'service_data.dart';
import 'add_service_dialog.dart';
import 'service_widgets.dart';

class ServiceDestinationScreen extends StatefulWidget {
  final String entryTitle;

  const ServiceDestinationScreen({super.key, required this.entryTitle});

  static ServiceDestinationScreen fromRoute(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map ? args : const {};
    final title = (map['entryTitle'] ?? 'Destination').toString();
    return ServiceDestinationScreen(entryTitle: title);
  }

  @override
  State<ServiceDestinationScreen> createState() => _ServiceDestinationScreenState();
}

class _ServiceDestinationScreenState extends State<ServiceDestinationScreen> {
  final _search = TextEditingController();
  double _minRating = 0;
  double? _maxPrice;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openAddService() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => AddServiceDialog(onAdded: () => setState(() {})),
    );
  }

  void _openFilters() {
    final maxCtrl = TextEditingController(text: _maxPrice?.toStringAsFixed(0) ?? '');
    var draftMinRating = _minRating;

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

  List<DestinationService> _filtered() {
    final q = _search.text.trim().toLowerCase();
    return ServiceCatalog.destinations.where((d) {
      if (_minRating > 0 && d.rating < _minRating) return false;
      if (_maxPrice != null && d.startingPrice > _maxPrice!) return false;
      if (q.isEmpty) return true;
      return d.city.toLowerCase().contains(q) || d.title.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered();
    return MainAppShell(
      // Keep Services tab active for the whole services flow
      currentRoute: AppRoutes.service,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.entryTitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _openAddService,
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
                ],
              ),
              const SizedBox(height: 10),
              ServiceSearchBar(
                hint: 'Search destinations...',
                controller: _search,
                onChanged: (_) => setState(() {}),
                onFilter: _openFilters,
              ),
              const SizedBox(height: 18),
              Text(
                'Popular',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.88),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...list.map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: GlassContainer(
                    radius: 18,
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      height: 120,
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              d.heroImageAsset,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  d.city,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  d.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.star, size: 16, color: Colors.amber.shade300),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${d.rating.toStringAsFixed(1)}  (${d.reviews})',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.serviceDestinationDetail,
                                arguments: {'serviceId': d.id},
                              );
                            },
                            icon: const Icon(Icons.chevron_right, color: Colors.white),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
