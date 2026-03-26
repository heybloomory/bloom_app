import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/smart_media_models.dart';

/// SQLite-backed smart media cache (mobile / desktop).
class SmartMediaStorage {
  SmartMediaStorage._();
  static final SmartMediaStorage instance = SmartMediaStorage._();

  Database? _db;

  Future<void> init() async {
    if (_db != null) return;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'bloomory_smart_media.db');
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE smart_media (
  id TEXT PRIMARY KEY,
  photo_id TEXT NOT NULL,
  album_id TEXT NOT NULL,
  album_title TEXT NOT NULL,
  local_path TEXT NOT NULL,
  thumb_path TEXT,
  taken_at INTEGER NOT NULL,
  is_video INTEGER NOT NULL,
  is_best INTEGER NOT NULL,
  is_duplicate INTEGER NOT NULL,
  is_screenshot INTEGER NOT NULL,
  is_blurry INTEGER NOT NULL,
  duplicate_group_id TEXT,
  file_size INTEGER NOT NULL,
  tags TEXT NOT NULL,
  event_id TEXT,
  favorite INTEGER NOT NULL
)
''');
        await db.execute('''
CREATE TABLE smart_events (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  cover_photo_id TEXT,
  cover_local_path TEXT,
  photo_count INTEGER NOT NULL,
  start_ms INTEGER NOT NULL,
  end_ms INTEGER NOT NULL
)
''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // v2: tags column now stores JSON array of {name, c} (strings still supported).
        if (oldVersion < 2) {
          // Schema unchanged; parser accepts legacy string arrays.
        }
      },
    );
    debugPrint('[SmartMediaStorage] SQLite open OK: $path');
  }

  Future<void> clear() async {
    final db = _db;
    if (db == null) return;
    await db.delete('smart_media');
    await db.delete('smart_events');
  }

  Future<void> replaceAll({
    required List<SmartMediaItem> items,
    required List<SmartEvent> events,
  }) async {
    await init();
    final db = _db!;
    final batch = db.batch();
    batch.delete('smart_media');
    batch.delete('smart_events');
    for (final m in items) {
      batch.insert('smart_media', {
        'id': m.id,
        'photo_id': m.photoId,
        'album_id': m.albumId,
        'album_title': m.albumTitle,
        'local_path': m.localPath,
        'thumb_path': m.thumbPath,
        'taken_at': m.takenAt.millisecondsSinceEpoch,
        'is_video': m.isVideo ? 1 : 0,
        'is_best': m.isBest ? 1 : 0,
        'is_duplicate': m.isDuplicate ? 1 : 0,
        'is_screenshot': m.isScreenshot ? 1 : 0,
        'is_blurry': m.isBlurry ? 1 : 0,
        'duplicate_group_id': m.duplicateGroupId,
        'file_size': m.fileSizeBytes,
        'tags': m.tagsJson,
        'event_id': m.eventId,
        'favorite': m.favorite ? 1 : 0,
      });
    }
    for (final e in events) {
      batch.insert('smart_events', {
        'id': e.id,
        'title': e.title,
        'cover_photo_id': e.coverPhotoId,
        'cover_local_path': e.coverLocalPath,
        'photo_count': e.photoCount,
        'start_ms': e.start.millisecondsSinceEpoch,
        'end_ms': e.end.millisecondsSinceEpoch,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<SmartMediaItem>> getAllItems() async {
    await init();
    final rows = await _db!.query('smart_media', orderBy: 'taken_at DESC');
    return rows.map(_rowToItem).toList();
  }

  Future<List<SmartEvent>> getAllEvents() async {
    await init();
    final rows = await _db!.query('smart_events', orderBy: 'start_ms DESC');
    return rows.map(_rowToEvent).toList();
  }

  static SmartMediaItem _rowToItem(Map<String, Object?> r) {
    var tagScores = <SmartTag>[];
    try {
      final raw = r['tags'] as String? ?? '[]';
      final decoded = (jsonDecode(raw) as List?) ?? [];
      for (final e in decoded) {
        final t = SmartTag.tryParse(e);
        if (t != null) tagScores.add(t);
      }
    } catch (_) {}

    return SmartMediaItem(
      id: (r['id'] ?? '').toString(),
      photoId: (r['photo_id'] ?? '').toString(),
      albumId: (r['album_id'] ?? '').toString(),
      albumTitle: (r['album_title'] ?? '').toString(),
      localPath: (r['local_path'] ?? '').toString(),
      thumbPath: r['thumb_path']?.toString(),
      takenAt: DateTime.fromMillisecondsSinceEpoch(
        (r['taken_at'] as int?) ?? 0,
      ),
      isVideo: (r['is_video'] as int? ?? 0) == 1,
      isBest: (r['is_best'] as int? ?? 1) == 1,
      isDuplicate: (r['is_duplicate'] as int? ?? 0) == 1,
      isScreenshot: (r['is_screenshot'] as int? ?? 0) == 1,
      isBlurry: (r['is_blurry'] as int? ?? 0) == 1,
      duplicateGroupId: r['duplicate_group_id']?.toString(),
      fileSizeBytes: (r['file_size'] as int?) ?? 0,
      tagScores: tagScores,
      eventId: r['event_id']?.toString(),
      favorite: (r['favorite'] as int? ?? 0) == 1,
    );
  }

  static SmartEvent _rowToEvent(Map<String, Object?> r) {
    return SmartEvent(
      id: (r['id'] ?? '').toString(),
      title: (r['title'] ?? '').toString(),
      coverPhotoId: r['cover_photo_id']?.toString(),
      coverLocalPath: r['cover_local_path']?.toString(),
      photoCount: (r['photo_count'] as int?) ?? 0,
      start: DateTime.fromMillisecondsSinceEpoch((r['start_ms'] as int?) ?? 0),
      end: DateTime.fromMillisecondsSinceEpoch((r['end_ms'] as int?) ?? 0),
    );
  }
}
