import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import 'service_data.dart';

/// Demo-only dialog to add a new Service into the in-memory [ServiceCatalog].
///
/// Later you can replace this with a Firestore/API create flow.
class AddServiceDialog extends StatefulWidget {
  final VoidCallback onAdded;

  const AddServiceDialog({super.key, required this.onAdded});

  @override
  State<AddServiceDialog> createState() => _AddServiceDialogState();
}

class _AddServiceDialogState extends State<AddServiceDialog> {
  final _cityCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _ratingCtrl = TextEditingController(text: '4.8');
  final _reviewsCtrl = TextEditingController(text: '100');
  final _spotsCtrl = TextEditingController(text: 'Iconic Spot 1, Iconic Spot 2');
  final _photographerCtrl = TextEditingController(text: 'Photographer Name');

  String _categoryId = ServiceCatalog.categories.first.id;
  final String _heroAsset = ServiceCatalog.sampleImage;

  @override
  void dispose() {
    _cityCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _ratingCtrl.dispose();
    _reviewsCtrl.dispose();
    _spotsCtrl.dispose();
    _photographerCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final city = _cityCtrl.text.trim();
    final title = _titleCtrl.text.trim();
    if (city.isEmpty || title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('City and Title are required.')),
      );
      return;
    }

    final id = '${_categoryId}_${DateTime.now().millisecondsSinceEpoch}';
    final rating = (double.tryParse(_ratingCtrl.text.trim()) ?? 4.8).clamp(0, 5);
    final reviews = int.tryParse(_reviewsCtrl.text.trim()) ?? 100;
    final starting = double.tryParse(_priceCtrl.text.trim()) ?? 150;
    final desc = _descCtrl.text.trim().isEmpty
        ? 'Book a premium experience in $city with BloomoryAI.'
        : _descCtrl.text.trim();

    final spotTitles = _spotsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final spots = <ServiceSpot>[];
    for (var i = 0; i < spotTitles.length; i++) {
      spots.add(
        ServiceSpot(
          id: 'spot_${id}_$i',
          title: spotTitles[i],
          imageAsset: ServiceCatalog.sampleImage,
        ),
      );
    }
    if (spots.isEmpty) {
      spots.add(
        ServiceSpot(
          id: 'spot_${id}_0',
          title: 'Popular Spot',
          imageAsset: ServiceCatalog.sampleImage,
        ),
      );
    }

    final photographerName = _photographerCtrl.text.trim().isEmpty
        ? 'Bloomory Pro'
        : _photographerCtrl.text.trim();

    final photographers = <ServicePhotographer>[
      ServicePhotographer(
        id: 'ph_${id}_0',
        name: photographerName,
        rating: (rating - 0.1).clamp(0, 5),
        reviews: (reviews / 2).round(),
        avatarAsset: ServiceCatalog.profileImage,
      ),
    ];

    ServiceCatalog.addDestination(
      DestinationService(
        id: id,
        city: city,
        title: title,
        description: desc,
        rating: rating.toDouble(),
        reviews: reviews,
        heroImageAsset: _heroAsset,
        spots: spots,
        photographers: photographers,
        startingPrice: starting,
      ),
    );

    widget.onAdded();
    Navigator.pop(context);
  }

  InputDecoration _dec(String hint) {
    return InputDecoration(
      hintText: hint,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: GlassContainer(
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
                        'Add Service',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Category', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  dropdownColor: const Color(0xFF1A1A1A),
                  decoration: _dec('Select category'),
                  items: ServiceCatalog.categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.title, style: const TextStyle(color: Colors.white)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _categoryId = v ?? _categoryId),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cityCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: _dec('City (e.g. Paris)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: _dec('Starting Price'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('Service title (e.g. Paris Photo Tour)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('Description'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ratingCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: _dec('Rating (0-5)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _reviewsCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: _dec('Reviews'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _spotsCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('Photo spots (comma separated)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _photographerCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('Photographer name'),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
