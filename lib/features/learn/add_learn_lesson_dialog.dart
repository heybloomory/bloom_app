import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import 'learn_models.dart';

class AddLearnLessonDialog extends StatefulWidget {
  const AddLearnLessonDialog({super.key});

  static Future<LearnLesson?> open(BuildContext context) {
    return showDialog<LearnLesson>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const AddLearnLessonDialog(),
    );
  }

  @override
  State<AddLearnLessonDialog> createState() => _AddLearnLessonDialogState();
}

class _AddLearnLessonDialogState extends State<AddLearnLessonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _minutes = TextEditingController(text: '8');

  @override
  void dispose() {
    _title.dispose();
    _minutes.dispose();
    super.dispose();
  }

  String _safeId(String t) {
    final s = t.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return s.isEmpty ? 'lesson' : 'lesson_$s';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: GlassContainer(
        radius: 24,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Lesson',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),

              _label('Lesson title'),
              TextFormField(
                controller: _title,
                style: const TextStyle(color: Colors.white),
                decoration: _dec('e.g., Lighting for indoors'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),

              _label('Minutes'),
              TextFormField(
                controller: _minutes,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: _dec('8'),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  return (n == null || n <= 0) ? 'Enter minutes' : null;
                },
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _btn('Cancel', () => Navigator.pop(context), false),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _btn('Add', () {
                      if (!_formKey.currentState!.validate()) return;
                      final title = _title.text.trim();
                      final minutes = int.parse(_minutes.text.trim());
                      final lesson = LearnLesson(id: _safeId(title), title: title, minutes: minutes);
                      Navigator.pop(context, lesson);
                    }, true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );

  Widget _btn(String text, VoidCallback onTap, bool primary) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        radius: 14,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: primary ? Colors.white : Colors.white70,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
