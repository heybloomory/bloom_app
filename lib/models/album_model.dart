/// Local-first album for the Timeline.
/// Stored in Hive. [backendAlbumId] is set after first successful sync to the API.
const Object _timelineAlbumUnset = Object();

class TimelineAlbum {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? backendAlbumId;

  const TimelineAlbum({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.backendAlbumId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'backendAlbumId': backendAlbumId,
    };
  }

  static TimelineAlbum fromMap(Map<dynamic, dynamic> map) {
    final createdAtRaw = map['createdAt'];
    DateTime createdAt = DateTime.now();
    if (createdAtRaw != null) {
      if (createdAtRaw is DateTime) {
        createdAt = createdAtRaw;
      } else {
        createdAt = DateTime.tryParse(createdAtRaw.toString()) ?? createdAt;
      }
    }

    final updatedAtRaw = map['updatedAt'];
    DateTime updatedAt = createdAt;
    if (updatedAtRaw != null) {
      if (updatedAtRaw is DateTime) {
        updatedAt = updatedAtRaw;
      } else {
        updatedAt = DateTime.tryParse(updatedAtRaw.toString()) ?? createdAt;
      }
    }

    return TimelineAlbum(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      backendAlbumId: map['backendAlbumId']?.toString(),
    );
  }

  TimelineAlbum copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? backendAlbumId = _timelineAlbumUnset,
  }) {
    return TimelineAlbum(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      backendAlbumId: identical(backendAlbumId, _timelineAlbumUnset)
          ? this.backendAlbumId
          : backendAlbumId as String?,
    );
  }
}
