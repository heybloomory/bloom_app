import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';
import 'gift_data.dart';
import 'gift_models.dart';
import 'gift_image.dart';

enum _SortMode { newest, priceLow, priceHigh, ratingHigh, discount }

class GiftCategoryScreen extends StatefulWidget {
  final String category;
  final String title;

  const GiftCategoryScreen({
    super.key,
    required this.category,
    required this.title,
  });

  static GiftCategoryScreen fromRoute(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map ? args : const {};
    final category = (map['category'] ?? 'photo_frame_collages').toString();
    final title = (map['title'] ?? 'Photo Frame Collages').toString();
    return GiftCategoryScreen(category: category, title: title);
  }

  @override
  State<GiftCategoryScreen> createState() => _GiftCategoryScreenState();
}

class _GiftCategoryScreenState extends State<GiftCategoryScreen> {
  final _search = TextEditingController();

  _SortMode _sort = _SortMode.newest;
  int? _minPrice;
  int? _maxPrice;
  bool _onlyDiscounted = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<GiftProduct> _filtered() {
    final q = _search.text.trim().toLowerCase();
    final base = GiftData.byCategory(widget.category);

    var items = base.where((p) {
      if (_onlyDiscounted && p.discountedPrice == null) return false;
      if (_minPrice != null && p.effectivePrice < _minPrice!) return false;
      if (_maxPrice != null && p.effectivePrice > _maxPrice!) return false;
      if (q.isEmpty) return true;
      return p.title.toLowerCase().contains(q);
    }).toList();

    switch (_sort) {
      case _SortMode.newest:
        // Demo data doesn't have createdAt; inserting new items at index 0 in
        // GiftData.addProduct makes this behave like "Newest".
        break;
      case _SortMode.priceLow:
        items.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
        break;
      case _SortMode.priceHigh:
        items.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
        break;
      case _SortMode.ratingHigh:
        items.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case _SortMode.discount:
        items.sort((a, b) {
          final ad = (a.discountedPrice == null) ? 0 : (a.price - a.discountedPrice!);
          final bd = (b.discountedPrice == null) ? 0 : (b.price - b.discountedPrice!);
          return bd.compareTo(ad);
        });
        break;
    }
    return items;
  }

  void _openFilters() {
    // NOTE: The bottom sheet is its own route; calling setState from the parent
    // won't rebuild widgets inside the sheet.
    // Keep local draft state in a StatefulBuilder and only commit on Apply.
    final minCtrl = TextEditingController(text: _minPrice?.toString() ?? '');
    final maxCtrl = TextEditingController(text: _maxPrice?.toString() ?? '');
    var draftSort = _sort;
    var draftOnlyDiscounted = _onlyDiscounted;

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
                                    draftSort = _SortMode.newest;
                                    draftOnlyDiscounted = false;
                                    minCtrl.text = '';
                                    maxCtrl.text = '';
                                  });
                                },
                                child: const Text('Clear'),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon:
                                    const Icon(Icons.close, color: Colors.white70),
                              )
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text('Sort By',
                              style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _Chip(
                                label: 'Newest',
                                selected: draftSort == _SortMode.newest,
                                onTap: () => setSheetState(
                                    () => draftSort = _SortMode.newest),
                              ),
                              _Chip(
                                label: 'Price (Low)',
                                selected: draftSort == _SortMode.priceLow,
                                onTap: () => setSheetState(
                                    () => draftSort = _SortMode.priceLow),
                              ),
                              _Chip(
                                label: 'Price (High)',
                                selected: draftSort == _SortMode.priceHigh,
                                onTap: () => setSheetState(
                                    () => draftSort = _SortMode.priceHigh),
                              ),
                              _Chip(
                                label: 'Rating',
                                selected: draftSort == _SortMode.ratingHigh,
                                onTap: () => setSheetState(
                                    () => draftSort = _SortMode.ratingHigh),
                              ),
                              _Chip(
                                label: 'Discount',
                                selected: draftSort == _SortMode.discount,
                                onTap: () => setSheetState(
                                    () => draftSort = _SortMode.discount),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Text('Price Range',
                              style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _Field(
                                  controller: minCtrl,
                                  hint: 'Min',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _Field(
                                  controller: maxCtrl,
                                  hint: 'Max',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Checkbox(
                                value: draftOnlyDiscounted,
                                onChanged: (v) => setSheetState(
                                    () => draftOnlyDiscounted = v ?? false),
                                activeColor: Colors.white,
                                checkColor: Colors.black,
                              ),
                              const Text('Only discounted',
                                  style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _sort = draftSort;
                                  _onlyDiscounted = draftOnlyDiscounted;
                                  _minPrice = int.tryParse(minCtrl.text.trim());
                                  _maxPrice = int.tryParse(maxCtrl.text.trim());
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
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

  @override
  Widget build(BuildContext context) {
    final products = _filtered();

    return MainAppShell(
      currentRoute: AppRoutes.gifts,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              _TopBar(title: widget.title),
              const SizedBox(height: 12),
              _SearchBar(
                controller: _search,
                hint: 'Search gifts... ',
                onFilter: _openFilters,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Celebrate love, moments, and milestones\nwith premium ${widget.title}.'.replaceAll(
                      'Photo Frame Collages', 'photo frame collages'),
                  style: const TextStyle(color: Colors.white70, height: 1.35),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${widget.title} ✨',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  itemCount: products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.78,
                  ),
                  itemBuilder: (context, i) {
                    return _ProductCard(product: products[i]);
                  },
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'See all Signature Gifts  >',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onFilter;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.controller,
    required this.hint,
    required this.onFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.white54),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: onFilter,
            icon: const Icon(Icons.tune, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final GiftProduct product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.giftProduct,
          arguments: {'id': product.id},
        );
      },
      child: GlassContainer(
        radius: 18,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: GiftImage(
                path: product.primaryImage,
                height: 110,
                width: double.infinity,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              product.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            _PriceTag(price: product.price, discounted: product.discountedPrice),
            const SizedBox(height: 4),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  Icons.star,
                  size: 14,
                  color: i < product.rating.round() ? Colors.amber : Colors.white24,
                ),
              ),
            ),
            const Spacer(),
            const Center(
              child: GlassContainer(
                radius: 20,
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text('Create Gift', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  final int price;
  final int? discounted;
  const _PriceTag({required this.price, required this.discounted});

  @override
  Widget build(BuildContext context) {
    if (discounted == null || discounted! >= price) {
      return Text(
        'From \$$price',
        style: const TextStyle(color: Colors.white70),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '\$$price',
          style: const TextStyle(
            color: Colors.white54,
            decoration: TextDecoration.lineThrough,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'From \$$discounted',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? Colors.white24 : Colors.white10,
          border: Border.all(color: selected ? Colors.white54 : Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? Colors.white : Colors.white70),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _Field({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
