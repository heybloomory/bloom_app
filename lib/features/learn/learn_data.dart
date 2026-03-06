import 'learn_models.dart';

/// Demo data to make the Learn module fully clickable.
/// Replace this later with Firestore/API.
class LearnData {
  static const categories = <String>[
    'All',
    'Parents',
    'Kids',
    'Couples',
    'Travel',
    'Photography',
    'Wellness',
  ];

  static const courses = <LearnCourse>[
    LearnCourse(
      id: 'c1',
      title: 'Capture Better Family Moments',
      category: 'Parents',
      level: 'Beginner',
      rating: 4.8,
      lessons: 12,
      minutes: 95,
      price: 199,
      shortDescription:
          'Simple tips to shoot, organize, and preserve memories that matter.',
    ),
    LearnCourse(
      id: 'c2',
      title: 'Phone Photography Basics',
      category: 'Photography',
      level: 'Beginner',
      rating: 4.6,
      lessons: 10,
      minutes: 80,
      price: 149,
      shortDescription:
          'Lighting, composition, and quick edits to make photos look premium.',
    ),
    LearnCourse(
      id: 'c3',
      title: 'Travel Storytelling',
      category: 'Travel',
      level: 'Intermediate',
      rating: 4.7,
      lessons: 14,
      minutes: 120,
      price: 249,
      shortDescription:
          'Turn trips into cinematic stories with shot lists and simple editing.',
    ),
    LearnCourse(
      id: 'c4',
      title: 'Kids Growth Album',
      category: 'Kids',
      level: 'Beginner',
      rating: 4.5,
      lessons: 8,
      minutes: 60,
      price: 99,
      shortDescription:
          'Create month-by-month albums and keep your gallery clean and organized.',
    ),
  ];

  static const lessonsByCourse = <String, List<LearnLesson>>{
    'c1': [
      LearnLesson(id: 'l1', title: 'Welcome & Setup', minutes: 5),
      LearnLesson(id: 'l2', title: 'Lighting for Indoors', minutes: 9),
      LearnLesson(id: 'l3', title: 'Candid Moments', minutes: 8),
      LearnLesson(id: 'l4', title: 'Organize Albums Fast', minutes: 10),
      LearnLesson(id: 'l5', title: 'Sharing with Family', minutes: 7),
    ],
    'c2': [
      LearnLesson(id: 'l1', title: 'Composition Rules', minutes: 9),
      LearnLesson(id: 'l2', title: 'Portrait Mode Tips', minutes: 8),
      LearnLesson(id: 'l3', title: 'Quick Editing', minutes: 12),
      LearnLesson(id: 'l4', title: 'Export & Backup', minutes: 7),
    ],
    'c3': [
      LearnLesson(id: 'l1', title: 'Build a Shot List', minutes: 10),
      LearnLesson(id: 'l2', title: 'B-Roll Essentials', minutes: 12),
      LearnLesson(id: 'l3', title: 'Simple Cuts', minutes: 15),
      LearnLesson(id: 'l4', title: 'Add Music', minutes: 8),
      LearnLesson(id: 'l5', title: 'Share your Film', minutes: 6),
    ],
    'c4': [
      LearnLesson(id: 'l1', title: 'Monthly Capture Checklist', minutes: 6),
      LearnLesson(id: 'l2', title: 'Album Templates', minutes: 11),
      LearnLesson(id: 'l3', title: 'Printing & Gifts', minutes: 9),
    ],
  };
}
