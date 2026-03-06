class LearnCourse {
  final String id;
  final String title;
  final String category;
  final String level;
  final double rating;
  final int lessons;
  final int minutes;
  final double price;
  final String shortDescription;

  const LearnCourse({
    required this.id,
    required this.title,
    required this.category,
    required this.level,
    required this.rating,
    required this.lessons,
    required this.minutes,
    required this.price,
    required this.shortDescription,
  });
}

class LearnLesson {
  final String id;
  final String title;
  final int minutes;

  const LearnLesson({
    required this.id,
    required this.title,
    required this.minutes,
  });
}
