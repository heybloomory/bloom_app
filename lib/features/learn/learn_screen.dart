import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';
import 'add_learn_course_dialog.dart';
import 'learn_models.dart';
import 'learn_store.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final LearnStore _store = LearnStore.instance;

  String _selectedCategory = 'All';
  String _selectedLevel = 'All';
  String _selectedPrice = 'All';

  List<LearnCourse> get _filteredCourses {
    return _store.courses.where((c) {
      final catOk = _selectedCategory == 'All' || c.category == _selectedCategory;
      final levelOk = _selectedLevel == 'All' || c.level == _selectedLevel;

      final priceOk = _selectedPrice == 'All'
          ? true
          : _selectedPrice == 'Under ₹150'
              ? c.price < 150
              : _selectedPrice == '₹150 - ₹200'
                  ? (c.price >= 150 && c.price <= 200)
                  : c.price > 200;

      return catOk && levelOk && priceOk;
    }).toList();
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _FilterSheet(
          categories: _store.categories,
          category: _selectedCategory,
          level: _selectedLevel,
          price: _selectedPrice,
        );
      },
    );

    if (result == null) return;
    setState(() {
      _selectedCategory = result['category'] ?? _selectedCategory;
      _selectedLevel = result['level'] ?? _selectedLevel;
      _selectedPrice = result['price'] ?? _selectedPrice;
    });
  }

  Future<void> _openAddCourse() async {
    final course = await AddLearnCourseDialog.open(
      context,
      existingCategories: _store.categories,
    );
    if (course == null) return;
    _store.addCourse(course);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        final categories = _store.categories;

        return MainAppShell(
          currentRoute: AppRoutes.learn,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Learn',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _TopIconButton(
                        icon: Icons.search,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Search coming soon')),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      _TopIconButton(
                        icon: Icons.notifications_none,
                        hasDot: true,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.settingsNotifications,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, i) {
                      final c = categories[i];
                      final active = c == _selectedCategory;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = c),
                        child: GlassContainer(
                          radius: 999,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Text(
                            c,
                            style: TextStyle(
                              color: active ? Colors.white : Colors.white70,
                              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemCount: categories.length,
                  ),
                ),

                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_filteredCourses.length} courses',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _openAddCourse,
                        icon: const Icon(Icons.add, color: Colors.white70, size: 18),
                        label: const Text('Add', style: TextStyle(color: Colors.white70)),
                      ),
                      const SizedBox(width: 6),
                      TextButton.icon(
                        onPressed: _openFilters,
                        icon: const Icon(Icons.tune, color: Colors.white70, size: 18),
                        label: const Text('Filter', style: TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
                    itemBuilder: (context, i) {
                      final course = _filteredCourses[i];
                      return _CourseCard(
                        course: course,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.learnCourseDetail,
                            arguments: {'courseId': course.id},
                          );
                        },
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: _filteredCourses.length,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool hasDot;

  const _TopIconButton({
    required this.icon,
    required this.onTap,
    this.hasDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        radius: 14,
        padding: const EdgeInsets.all(10),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: Colors.white70),
            if (hasDot)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final LearnCourse course;
  final VoidCallback onTap;

  const _CourseCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        radius: 22,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // thumbnail placeholder
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withOpacity(0.08),
              ),
              child: const Icon(Icons.play_circle_outline, color: Colors.white70),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 6),
                      Text(
                        course.rating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${course.lessons} lessons • ${course.minutes} min',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Pill(text: course.category),
                      _Pill(text: course.level),
                      _Pill(text: '₹${course.price.toStringAsFixed(0)}'),
                    ],
                  ),
                  if (course.shortDescription.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      course.shortDescription,
                      style: const TextStyle(color: Colors.white70),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final List<String> categories;
  final String category;
  final String level;
  final String price;

  const _FilterSheet({
    required this.categories,
    required this.category,
    required this.level,
    required this.price,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String category;
  late String level;
  late String price;

  @override
  void initState() {
    super.initState();
    category = widget.category;
    level = widget.level;
    price = widget.price;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 14,
          right: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 14,
        ),
        child: GlassContainer(
          radius: 24,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filters',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _LabeledChips(
                label: 'Category',
                values: widget.categories,
                value: category,
                onChanged: (v) => setState(() => category = v),
              ),
              const SizedBox(height: 14),

              _LabeledChips(
                label: 'Level',
                values: const ['All', 'Beginner', 'Intermediate', 'Advanced'],
                value: level,
                onChanged: (v) => setState(() => level = v),
              ),
              const SizedBox(height: 14),

              _LabeledChips(
                label: 'Price',
                values: const ['All', 'Under ₹150', '₹150 - ₹200', 'Above ₹200'],
                value: price,
                onChanged: (v) => setState(() => price = v),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          category = 'All';
                          level = 'All';
                          price = 'All';
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withOpacity(0.25)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          'category': category,
                          'level': level,
                          'price': price,
                        });
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
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledChips extends StatelessWidget {
  final String label;
  final List<String> values;
  final String value;
  final ValueChanged<String> onChanged;

  const _LabeledChips({
    required this.label,
    required this.values,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((v) {
            final active = v == value;
            return GestureDetector(
              onTap: () => onChanged(v),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? Colors.white.withOpacity(0.18) : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(active ? 0.22 : 0.12)),
                ),
                child: Text(
                  v,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.white70,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
