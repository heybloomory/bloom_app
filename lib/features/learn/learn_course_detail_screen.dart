import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';
import 'learn_data.dart';
import 'learn_store.dart';
import 'add_learn_lesson_dialog.dart';

class LearnCourseDetailScreen extends StatelessWidget {
  final String courseId;

  const LearnCourseDetailScreen({super.key, required this.courseId});

  static LearnCourseDetailScreen fromRoute(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map ? args : const {};
    final courseId = (map['courseId'] ?? '').toString();
    return LearnCourseDetailScreen(courseId: courseId);
  }

  @override
  Widget build(BuildContext context) {
    final store = LearnStore.instance;
    final course = store.courseById(courseId) ?? LearnData.courses.first;
    final lessons = store.lessonsForCourse(course.id);

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
                      course.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () async {
                      final lesson = await AddLearnLessonDialog.open(context);
                      if (lesson == null) return;
                      LearnStore.instance.addLesson(course.id, lesson);
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
                  // Video preview / hero
                  GlassContainer(
                    radius: 22,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 190,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Center(
                            child: Icon(Icons.play_circle_fill, color: Colors.white54, size: 56),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          course.shortDescription,
                          style: const TextStyle(color: Colors.white70, height: 1.35),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _MetaPill(icon: Icons.star, text: course.rating.toStringAsFixed(1)),
                            const SizedBox(width: 10),
                            _MetaPill(icon: Icons.menu_book, text: '${course.lessons} lessons'),
                            const SizedBox(width: 10),
                            _MetaPill(icon: Icons.schedule, text: '${course.minutes} min'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: GlassContainer(
                                radius: 16,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                child: Row(
                                  children: [
                                    const Icon(Icons.currency_rupee, color: Colors.white70, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      course.price.toStringAsFixed(0),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Text('One time', style: TextStyle(color: Colors.white54)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Purchase flow coming soon')),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Buy Course'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Lessons',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),

                  ...lessons.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final lesson = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassContainer(
                        radius: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: InkWell(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.learnLessonPlayer,
                              arguments: {
                                'courseId': course.id,
                                'lessonId': lesson.id,
                                'lessonTitle': lesson.title,
                                'lessonIndex': idx,
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$idx',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lesson.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${lesson.minutes} min',
                                      style: const TextStyle(color: Colors.white54),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.play_arrow, color: Colors.white70),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
