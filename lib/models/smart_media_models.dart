import 'dart:convert';

/// Local AI-style tag with confidence (0–1).
class SmartTag {
  final String name;
  final double confidence;

  const SmartTag({
    required this.name,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {'name': name, 'c': confidence};

  static SmartTag? tryParse(dynamic e) {
    if (e is String) {
      return SmartTag(name: e, confidence: 0.55);
    }
    if (e is Map) {
      final name = (e['name'] ?? e['tag'] ?? '').toString();
      if (name.isEmpty) return null;
      final c = (e['c'] ?? e['confidence'] as num?)?.toDouble() ?? 0.6;
      return SmartTag(name: name, confidence: c.clamp(0.0, 1.0));
    }
    return null;
  }
}

/// Single media row in the Smart Media Engine (SQLite or in-memory on web).
class SmartMediaItem {
  final String id;
  final String photoId;
  final String albumId;
  final String albumTitle;
  final String localPath;
  final String? thumbPath;
  final DateTime takenAt;
  final bool isVideo;
  final bool isBest;
  final bool isDuplicate;
  final bool isScreenshot;
  final bool isBlurry;
  final String? duplicateGroupId;
  final int fileSizeBytes;
  final List<SmartTag> tagScores;
  final String? eventId;
  final bool favorite;

  const SmartMediaItem({
    required this.id,
    required this.photoId,
    required this.albumId,
    required this.albumTitle,
    required this.localPath,
    this.thumbPath,
    required this.takenAt,
    this.isVideo = false,
    this.isBest = true,
    this.isDuplicate = false,
    this.isScreenshot = false,
    this.isBlurry = false,
    this.duplicateGroupId,
    this.fileSizeBytes = 0,
    this.tagScores = const [],
    this.eventId,
    this.favorite = false,
  });

  List<String> get tagNames =>
      tagScores.map((t) => t.name).toList(growable: false);

  String get tagsJson =>
      jsonEncode(tagScores.map((t) => t.toJson()).toList(growable: false));
}

/// Smart event cluster (replaces Today/Yesterday-only grouping).
class SmartEvent {
  final String id;
  final String title;
  final String? coverPhotoId;
  final String? coverLocalPath;
  final int photoCount;
  final DateTime start;
  final DateTime end;

  const SmartEvent({
    required this.id,
    required this.title,
    this.coverPhotoId,
    this.coverLocalPath,
    required this.photoCount,
    required this.start,
    required this.end,
  });
}

/// Result of [LocalSmartMediaProcessingEngine.process].
class SmartProcessingResult {
  final List<SmartMediaItem> media;
  final List<SmartEvent> events;
  final Map<String, List<String>> duplicateGroups;

  const SmartProcessingResult({
    required this.media,
    required this.events,
    required this.duplicateGroups,
  });
}

/// Ranked local search result row.
class SmartSearchPhotoHit {
  final SmartMediaItem item;
  final double score;

  const SmartSearchPhotoHit({
    required this.item,
    required this.score,
  });
}

/// Local smart search hits (no network).
class SmartSearchResult {
  final List<SmartEvent> events;
  final List<SmartMediaItem> photos;
  final List<SmartSearchPhotoHit> rankedPhotos;

  const SmartSearchResult({
    required this.events,
    required this.photos,
    this.rankedPhotos = const [],
  });
}
