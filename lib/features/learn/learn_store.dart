import 'package:flutter/foundation.dart';

import 'learn_data.dart';
import 'learn_models.dart';

/// In-memory store so the Learn module supports "Add Course" / "Add Lesson"
/// without needing Firestore yet.
///
/// Later you can replace this with a Firestore-backed repository and keep the UI the same.
class LearnStore extends ChangeNotifier {
  LearnStore._() {
    _courses = List<LearnCourse>.from(LearnData.courses);
    _lessonsByCourse = <String, List<LearnLesson>>{};
    LearnData.lessonsByCourse.forEach((courseId, lessons) {
      _lessonsByCourse[courseId] = List<LearnLesson>.from(lessons);
    });
  }

  static final LearnStore instance = LearnStore._();

  late List<LearnCourse> _courses;
  late Map<String, List<LearnLesson>> _lessonsByCourse;

  List<LearnCourse> get courses => List.unmodifiable(_courses);

  Map<String, List<LearnLesson>> get lessonsByCourse {
    final out = <String, List<LearnLesson>>{};
    _lessonsByCourse.forEach((k, v) => out[k] = List.unmodifiable(v));
    return out;
  }

  /// Categories shown in filter sheet. Always includes "All".
  List<String> get categories {
    final set = <String>{'All'};
    for (final c in _courses) {
      set.add(c.category);
    }
    return set.toList();
  }

  LearnCourse? courseById(String id) {
    try {
      return _courses.firstWhere((c) => c.id == id);
    } catch (_) {
      return _courses.isNotEmpty ? _courses.first : null;
    }
  }

  List<LearnLesson> lessonsForCourse(String courseId) {
    return List.unmodifiable(_lessonsByCourse[courseId] ?? const <LearnLesson>[]);
  }

  void addCourse(LearnCourse course, {List<LearnLesson>? lessons}) {
    // Prevent duplicate IDs: if collision, suffix with timestamp.
    final exists = _courses.any((c) => c.id == course.id);
    final finalCourse = exists
        ? LearnCourse(
            id: '${course.id}_${DateTime.now().millisecondsSinceEpoch}',
            title: course.title,
            category: course.category,
            level: course.level,
            rating: course.rating,
            lessons: course.lessons,
            minutes: course.minutes,
            price: course.price,
            shortDescription: course.shortDescription,
          )
        : course;

    _courses = [finalCourse, ..._courses];
    _lessonsByCourse[finalCourse.id] = List<LearnLesson>.from(lessons ?? const <LearnLesson>[]);
    _syncLessonCount(finalCourse.id);
    notifyListeners();
  }

  void addLesson(String courseId, LearnLesson lesson) {
    final list = _lessonsByCourse.putIfAbsent(courseId, () => <LearnLesson>[]);
    list.add(lesson);
    _syncLessonCount(courseId);
    notifyListeners();
  }

  void _syncLessonCount(String courseId) {
    final idx = _courses.indexWhere((c) => c.id == courseId);
    if (idx < 0) return;

    final c = _courses[idx];
    final lessonCount = (_lessonsByCourse[courseId]?.length ?? 0);
    final updated = LearnCourse(
      id: c.id,
      title: c.title,
      category: c.category,
      level: c.level,
      rating: c.rating,
      lessons: lessonCount == 0 ? c.lessons : lessonCount,
      minutes: c.minutes,
      price: c.price,
      shortDescription: c.shortDescription,
    );
    _courses[idx] = updated;
  }
}
