import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import 'learn_models.dart';

class AddLearnCourseDialog extends StatefulWidget {
  const AddLearnCourseDialog({
    super.key,
    required this.existingCategories,
  });

  final List<String> existingCategories;

  @override
  State<AddLearnCourseDialog> createState() => _AddLearnCourseDialogState();

  static Future<LearnCourse?> open(
    BuildContext context, {
    required List<String> existingCategories,
  }) {
    return showDialog<LearnCourse>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AddLearnCourseDialog(existingCategories: existingCategories),
    );
  }
}

class _AddLearnCourseDialogState extends State<AddLearnCourseDialog> {
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _customCategory = TextEditingController();
  final _minutes = TextEditingController(text: '60');
  final _price = TextEditingController(text: '199');
  final _desc = TextEditingController();

  String _category = 'Parents';
  String _level = 'Beginner';
  double _rating = 4.5;

  @override
  void initState() {
    super.initState();
    final cats = widget.existingCategories.where((c) => c != 'All').toList();
    _category = cats.isNotEmpty ? cats.first : 'Parents';
  }

  @override
  void dispose() {
    _title.dispose();
    _customCategory.dispose();
    _minutes.dispose();
    _price.dispose();
    _desc.dispose();
    super.dispose();
  }

  String _safeIdFromTitle(String t) {
    final s = t.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return s.isEmpty ? 'course' : 'course_$s';
  }

  @override
  Widget build(BuildContext context) {
    final cats = widget.existingCategories.where((c) => c != 'All').toList();
    final categoryItems = <String>[
      ...cats,
      if (!cats.contains('Other')) 'Other',
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: GlassContainer(
        radius: 24,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add Course',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),

                _fieldLabel('Title'),
                TextFormField(
                  controller: _title,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('e.g., Wedding Photo Storytelling'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Category'),
                          DropdownButtonFormField<String>(
                            value: _category,
                            dropdownColor: const Color(0xFF1E1E1E),
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Category'),
                            items: categoryItems
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) => setState(() => _category = v ?? _category),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Level'),
                          DropdownButtonFormField<String>(
                            value: _level,
                            dropdownColor: const Color(0xFF1E1E1E),
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Level'),
                            items: const ['Beginner', 'Intermediate', 'Advanced']
                                .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                                .toList(),
                            onChanged: (v) => setState(() => _level = v ?? _level),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (_category == 'Other') ...[
                  const SizedBox(height: 12),
                  _fieldLabel('Custom Category'),
                  TextFormField(
                    controller: _customCategory,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('e.g., Events'),
                    validator: (v) {
                      if (_category != 'Other') return null;
                      return (v == null || v.trim().isEmpty) ? 'Enter a category' : null;
                    },
                  ),
                ],

                const SizedBox(height: 12),
                _fieldLabel('Rating (${_rating.toStringAsFixed(1)})'),
                Slider(
                  value: _rating,
                  min: 1.0,
                  max: 5.0,
                  divisions: 40,
                  label: _rating.toStringAsFixed(1),
                  onChanged: (v) => setState(() => _rating = v.toDouble()),
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Minutes'),
                          TextFormField(
                            controller: _minutes,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('60'),
                            validator: (v) {
                              final n = int.tryParse((v ?? '').trim());
                              return (n == null || n <= 0) ? 'Enter minutes' : null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Price (₹)'),
                          TextFormField(
                            controller: _price,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('199'),
                            validator: (v) {
                              final n = double.tryParse((v ?? '').trim());
                              return (n == null || n < 0) ? 'Enter price' : null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                _fieldLabel('Short description'),
                TextFormField(
                  controller: _desc,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: _inputDecoration('1–2 lines about what the course teaches'),
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        text: 'Cancel',
                        onTap: () => Navigator.pop(context),
                        isPrimary: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionButton(
                        text: 'Add',
                        onTap: () {
                          if (!_formKey.currentState!.validate()) return;

                          final title = _title.text.trim();
                          final id = _safeIdFromTitle(title);

                          final category = _category == 'Other'
                              ? _customCategory.text.trim()
                              : _category;

                          final minutes = int.parse(_minutes.text.trim());
                          final price = double.parse(_price.text.trim());

                          final course = LearnCourse(
                            id: id,
                            title: title,
                            category: category.isEmpty ? 'General' : category,
                            level: _level,
                            rating: _rating.toDouble(),
                            lessons: 0,
                            minutes: minutes,
                            price: price,
                            shortDescription: _desc.text.trim().isEmpty
                                ? 'New course'
                                : _desc.text.trim(),
                          );

                          Navigator.pop(context, course);
                        },
                        isPrimary: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );

  Widget _actionButton({
    required String text,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        radius: 14,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isPrimary ? Colors.white : Colors.white70,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
