import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/photo_model.dart';
import '../models/smart_media_models.dart';
import 'local_photo_store.dart';
import 'smart_media/image_scene_tags.dart';
import 'smart_media/smart_media_file_size.dart';
import 'smart_media/smart_media_storage.dart';

/// Local-first Smart Media Engine. Timeline reads from SQLite (or in-memory on web)
/// via [process] output — ingestion uses Hive only inside this class.
class LocalSmartMediaProcessingEngine {
  LocalSmartMediaProcessingEngine._();

  static final _videoExt = <String>{
    'mp4',
    'mov',
    'm4v',
    'webm',
    'mkv',
    'avi',
    '3gp',
  };

  static final Map<String, List<SmartTag>> _geoTagCache = {};

  /// Rebuild smart index from local Hive library and return structured result.
  static Future<SmartProcessingResult> process() async {
    await LocalPhotoStore.init();
    if (!LocalPhotoStore.isReady) {
      return const SmartProcessingResult(
        media: [],
        events: [],
        duplicateGroups: {},
      );
    }

    final albums = LocalPhotoStore.listAlbums();
    final albumTitle = <String, String>{
      for (final a in albums) a.id: a.title,
    };

    final photos = LocalPhotoStore.listAllPhotos();
    final rawItems = <_RawItem>[];

    for (final p in photos) {
      final path = p.localPath.toLowerCase();
      final name = (p.originalFileName ?? path).toLowerCase();
      final ext = _extension(path);
      final isVideo = _videoExt.contains(ext);
      final isScreenshot = name.contains('screenshot') ||
          name.contains('screen shot') ||
          name.contains('screencap') ||
          path.contains('screenshot');
      final size = smartMediaFileByteSize(p.localPath);
      final tagScores = await _buildTagScores(p, isVideo);
      rawItems.add(
        _RawItem(
          photo: p,
          albumTitle: albumTitle[p.albumId] ?? 'Album',
          fileSize: size,
          isVideo: isVideo,
          isScreenshot: isScreenshot,
          tagScores: tagScores,
        ),
      );
    }

    // Duplicates: same album + same file size (lightweight heuristic).
    final dupMap = <String, List<_RawItem>>{};
    for (final r in rawItems) {
      if (r.fileSize <= 0) continue;
      final key = '${r.photo.albumId}_${r.fileSize}';
      dupMap.putIfAbsent(key, () => []).add(r);
    }
    for (final entry in dupMap.entries) {
      final list = entry.value;
      if (list.length < 2) continue;
      list.sort((a, b) => b.fileSize.compareTo(a.fileSize));
      for (var i = 0; i < list.length; i++) {
        list[i].duplicateGroupId = entry.key;
        list[i].isDuplicate = true;
        list[i].isBest = i == 0;
      }
    }

    // Real-ish event clustering: time gaps + tag/location hints + density.
    final timeline = List<_RawItem>.from(rawItems)
      ..sort((a, b) => a.photo.createdAt.compareTo(b.photo.createdAt));
    final clusters = <List<_RawItem>>[];
    for (final item in timeline) {
      if (clusters.isEmpty) {
        clusters.add([item]);
        continue;
      }
      final current = clusters.last;
      final prev = current.last;
      final gap = item.photo.createdAt.difference(prev.photo.createdAt).abs();
      final prevLocTag = _majorLocationTag(prev.tagScores);
      final curLocTag = _majorLocationTag(item.tagScores);
      final locationChanged = prevLocTag != null &&
          curLocTag != null &&
          prevLocTag != curLocTag;
      final splitByGap = gap.inHours >= 18;
      final splitByLongGap = gap.inDays >= 2;
      if (splitByLongGap || (splitByGap && locationChanged)) {
        clusters.add([item]);
      } else {
        current.add(item);
      }
    }

    final events = <SmartEvent>[];
    for (var i = 0; i < clusters.length; i++) {
      final group = clusters[i]
        ..sort((a, b) => a.photo.createdAt.compareTo(b.photo.createdAt));
      final start = group.first.photo.createdAt;
      final end = group.last.photo.createdAt;
      final title = _eventTitleFor(group, start, end);
      final cover = group.last;
      final id = 'evt_${start.millisecondsSinceEpoch}_$i';
      events.add(
        SmartEvent(
          id: id,
          title: title,
          coverPhotoId: cover.photo.id,
          coverLocalPath: cover.photo.localThumbnailPath ?? cover.photo.localPath,
          photoCount: group.length,
          start: start,
          end: end,
        ),
      );
      for (final r in group) {
        r.eventId = id;
      }
    }

    final items = <SmartMediaItem>[];
    for (final r in rawItems) {
      final p = r.photo;
      final merged = _mergeTagScores([
        ...r.tagScores,
        ..._faceTags(p.faces.length),
      ]);
      items.add(
        SmartMediaItem(
          id: 'sm_${p.id}',
          photoId: p.id,
          albumId: p.albumId,
          albumTitle: r.albumTitle,
          localPath: p.localPath,
          thumbPath: p.localThumbnailPath,
          takenAt: p.createdAt,
          isVideo: r.isVideo,
          isBest: r.isBest,
          isDuplicate: r.isDuplicate,
          isScreenshot: r.isScreenshot,
          isBlurry: false,
          duplicateGroupId: r.duplicateGroupId,
          fileSizeBytes: r.fileSize,
          tagScores: merged,
          eventId: r.eventId,
          favorite: p.isLikedByMe,
        ),
      );
    }

    final storage = SmartMediaStorage.instance;
    await storage.init();
    await storage.replaceAll(items: items, events: events);

    final storedItems = await storage.getAllItems();
    final storedEvents = await storage.getAllEvents();

    final dupGroups = <String, List<String>>{};
    for (final m in storedItems) {
      final g = m.duplicateGroupId;
      if (g == null || g.isEmpty) continue;
      dupGroups.putIfAbsent(g, () => []).add(m.photoId);
    }

    debugPrint(
      '[SmartEngine] process photos=${photos.length} items=${storedItems.length} events=${storedEvents.length}',
    );

    return SmartProcessingResult(
      media: storedItems,
      events: storedEvents,
      duplicateGroups: dupGroups,
    );
  }

  static String _extension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot >= path.length - 1) return '';
    return path.substring(dot + 1);
  }

  static Future<List<SmartTag>> _buildTagScores(Photo p, bool isVideo) async {
    final out = <SmartTag>[
      ..._ruleBasedTags(p, isVideo),
      ..._geoHintTags(p),
    ];
    final samplePath = p.localThumbnailPath ?? p.localPath;
    if (!isVideo) {
      out.addAll(await sampleSceneTagsFromPath(samplePath));
    }
    return _mergeTagScores(out);
  }

  static List<SmartTag> _ruleBasedTags(Photo p, bool isVideo) {
    final tags = <SmartTag>[];
    final h = p.createdAt.hour;
    if (h >= 20 || h < 6) {
      tags.add(const SmartTag(name: 'night', confidence: 0.58));
    }
    if (h >= 17 && h < 20) {
      tags.add(const SmartTag(name: 'sunset', confidence: 0.52));
    }
    if (h >= 6 && h < 12) {
      tags.add(const SmartTag(name: 'morning', confidence: 0.48));
    }
    if (h >= 12 && h < 17) {
      tags.add(const SmartTag(name: 'afternoon', confidence: 0.45));
    }
    if (isVideo) {
      tags.add(const SmartTag(name: 'video', confidence: 0.95));
    }

    final blob = '${p.localPath} ${p.originalFileName ?? ''}'.toLowerCase();
    if (blob.contains('beach') || blob.contains('sea') || blob.contains('ocean')) {
      tags.add(const SmartTag(name: 'beach', confidence: 0.7));
    }
    if (blob.contains('city') ||
        blob.contains('urban') ||
        blob.contains('street')) {
      tags.add(const SmartTag(name: 'city', confidence: 0.62));
    }
    if (blob.contains('mountain') ||
        blob.contains('hill') ||
        blob.contains('trek')) {
      tags.add(const SmartTag(name: 'mountain', confidence: 0.65));
    }
    if (blob.contains('food') ||
        blob.contains('dinner') ||
        blob.contains('lunch') ||
        blob.contains('restaurant')) {
      tags.add(const SmartTag(name: 'food', confidence: 0.6));
    }
    if (blob.contains('selfie') || blob.contains('front_cam')) {
      tags.add(const SmartTag(name: 'selfie', confidence: 0.72));
    }
    return tags;
  }

  /// Coarse location-derived tags (cached per ~0.1° cell). No network.
  static List<SmartTag> _geoHintTags(Photo p) {
    final lat = p.latitude;
    final lng = p.longitude;
    if (lat == null || lng == null) return const [];
    final key =
        '${lat.toStringAsFixed(1)}_${lng.toStringAsFixed(1)}';
    return _geoTagCache.putIfAbsent(key, () {
      final t = <SmartTag>[];
      if (lat.abs() < 23.5) {
        t.add(const SmartTag(name: 'tropical', confidence: 0.42));
      }
      if (lat.abs() > 48) {
        t.add(const SmartTag(name: 'northern', confidence: 0.38));
      }
      if (lng.abs() > 100 && lat.abs() < 40) {
        t.add(const SmartTag(name: 'asia_travel', confidence: 0.35));
      }
      t.add(const SmartTag(name: 'geo_tagged', confidence: 0.55));
      return t;
    });
  }

  static List<SmartTag> _faceTags(int n) {
    if (n <= 0) return const [];
    if (n >= 4) {
      return [SmartTag(name: 'group', confidence: 0.68 + (n > 6 ? 0.08 : 0))];
    }
    if (n >= 2) {
      return [const SmartTag(name: 'duo', confidence: 0.55)];
    }
    return [const SmartTag(name: 'portrait', confidence: 0.58)];
  }

  static List<SmartTag> _mergeTagScores(List<SmartTag> raw) {
    final map = <String, double>{};
    for (final t in raw) {
      final name = t.name.trim();
      if (name.isEmpty) continue;
      final prev = map[name] ?? 0;
      if (t.confidence > prev) map[name] = t.confidence;
    }
    final list = map.entries
        .map((e) => SmartTag(name: e.key, confidence: e.value))
        .toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    return list;
  }

  static String? _majorLocationTag(List<SmartTag> tags) {
    for (final t in tags) {
      final n = t.name;
      if (n == 'beach' ||
          n == 'city' ||
          n == 'mountain' ||
          n == 'sky' ||
          n == 'tropical') {
        return n;
      }
    }
    return null;
  }

  static String _eventTitleFor(
    List<_RawItem> group,
    DateTime start,
    DateTime end,
  ) {
    final allNames = <String>{for (final g in group) ...g.tagScores.map((t) => t.name)};
    final weekend = start.weekday == DateTime.saturday ||
        start.weekday == DateTime.sunday ||
        end.weekday == DateTime.saturday ||
        end.weekday == DateTime.sunday;
    final manyFaces = group.any((g) =>
        g.photo.faces.length >= 3 ||
        g.tagScores.any((t) => t.name == 'group' && t.confidence >= 0.6));
    if (allNames.contains('beach') || allNames.contains('tropical')) {
      return 'Goa Trip 🌴';
    }
    if (weekend && group.length >= 8) {
      return 'Weekend Memory';
    }
    if (allNames.contains('night') && group.length >= 6) {
      return 'Night Out 🌙';
    }
    if (manyFaces) {
      return 'Friends Time';
    }
    if (group.length >= 8) return '${DateFormat('EEE').format(start)} Highlights';
    return DateFormat('MMMM').format(start);
  }
}

class _RawItem {
  final Photo photo;
  final String albumTitle;
  final int fileSize;
  final bool isVideo;
  final bool isScreenshot;
  final List<SmartTag> tagScores;
  String? duplicateGroupId;
  String? eventId;
  bool isDuplicate = false;
  bool isBest = true;

  _RawItem({
    required this.photo,
    required this.albumTitle,
    required this.fileSize,
    required this.isVideo,
    required this.isScreenshot,
    required this.tagScores,
  });
}
