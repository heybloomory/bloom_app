import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';
import 'learn_store.dart';
import 'add_learn_lesson_dialog.dart';

class LearnLessonPlayerScreen extends StatelessWidget {
  final String courseId;
  final String lessonId;
  final String lessonTitle;
  final int lessonIndex;

  const LearnLessonPlayerScreen({
    super.key,
    required this.courseId,
    required this.lessonId,
    required this.lessonTitle,
    required this.lessonIndex,
  });

  static LearnLessonPlayerScreen fromRoute(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map ? args : const {};
    return LearnLessonPlayerScreen(
      courseId: (map['courseId'] ?? '').toString(),
      lessonId: (map['lessonId'] ?? '').toString(),
      lessonTitle: (map['lessonTitle'] ?? 'Lesson').toString(),
      lessonIndex: (map['lessonIndex'] ?? 1) is int
          ? (map['lessonIndex'] as int)
          : int.tryParse((map['lessonIndex'] ?? '1').toString()) ?? 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainAppShell(
      currentRoute: AppRoutes.learn,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const GlassContainer(
                      radius: 14,
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.arrow_back, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Lesson $lessonIndex: $lessonTitle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () async {
                      final lesson = await AddLearnLessonDialog.open(context);
                      if (lesson == null) return;
                      LearnStore.instance.addLesson(courseId, lesson);
                    },
                    child: const GlassContainer(
                      radius: 14,
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.add, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
                children: [
                  GlassContainer(
                    radius: 22,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 220,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Center(
                            child: Icon(Icons.play_circle_fill, color: Colors.white54, size: 62),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'This is a placeholder player UI. Hook your real video/lesson content here.',
                          style: TextStyle(color: Colors.white70, height: 1.35),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.list, size: 18),
                                label: const Text('All Lessons'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                  side: BorderSide(color: Colors.white.withOpacity(0.25)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Marked as completed (demo)')),
                                  );
                                },
                                icon: const Icon(Icons.check_circle, size: 18),
                                label: const Text('Complete'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
