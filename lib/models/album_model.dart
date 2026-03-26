/// Local-first album for the Timeline.
/// Stored in Hive. [backendAlbumId] is set after first successful sync to the API.
import 'dart:typed_data';

const Object _timelineAlbumUnset = Object();

class TimelineAlbum {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? backendAlbumId;
  final String? parentAlbumId;
  final int level;
  /// True after user ran optional "Sync to Cloud" for this album tree.
  final bool isSynced;
  final String? coverPhotoId;
  final Uint8List? coverBytes;
  final String? coverPath;

  const TimelineAlbum({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.backendAlbumId,
    this.parentAlbumId,
    this.level = 1,
    this.isSynced = false,
    this.coverPhotoId,
    this.coverBytes,
    this.coverPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'backendAlbumId': backendAlbumId,
      'parentAlbumId': parentAlbumId,
      'level': level,
      'isSynced': isSynced,
      'coverPhotoId': coverPhotoId,
      'coverBytes': coverBytes,
      'coverPath': coverPath,
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
      parentAlbumId: map['parentAlbumId']?.toString(),
      level: (map['level'] as num?)?.toInt() ?? 1,
      isSynced: map['isSynced'] == true,
      coverPhotoId: map['coverPhotoId']?.toString(),
      coverBytes: map['coverBytes'] is Uint8List
          ? map['coverBytes'] as Uint8List
          : (map['coverBytes'] is List
              ? Uint8List.fromList((map['coverBytes'] as List).cast<int>())
              : null),
      coverPath: map['coverPath']?.toString(),
    );
  }

  TimelineAlbum copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? backendAlbumId = _timelineAlbumUnset,
    Object? parentAlbumId = _timelineAlbumUnset,
    int? level,
    bool? isSynced,
    Object? coverPhotoId = _timelineAlbumUnset,
    Object? coverBytes = _timelineAlbumUnset,
    Object? coverPath = _timelineAlbumUnset,
  }) {
    return TimelineAlbum(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      backendAlbumId: identical(backendAlbumId, _timelineAlbumUnset)
          ? this.backendAlbumId
          : backendAlbumId as String?,
      parentAlbumId: identical(parentAlbumId, _timelineAlbumUnset)
          ? this.parentAlbumId
          : parentAlbumId as String?,
      level: level ?? this.level,
      isSynced: isSynced ?? this.isSynced,
      coverPhotoId: identical(coverPhotoId, _timelineAlbumUnset)
          ? this.coverPhotoId
          : coverPhotoId as String?,
      coverBytes: identical(coverBytes, _timelineAlbumUnset)
          ? this.coverBytes
          : coverBytes as Uint8List?,
      coverPath: identical(coverPath, _timelineAlbumUnset)
          ? this.coverPath
          : coverPath as String?,
    );
  }
}
