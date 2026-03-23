import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/album_model.dart';
import '../models/photo_model.dart';

/// Local-first storage for Timeline albums and photos using Hive.
/// Call [init] once before using (e.g. from main.dart).
class LocalPhotoStore {
  LocalPhotoStore._();

  static const _albumsBoxName = 'timeline_albums';
  static const _photosBoxName = 'timeline_photos';
  static const _faceMetaBoxName = 'timeline_face_meta';
  static const _faceGroupsKey = 'person_groups';
  static const _faceNamesKey = 'person_names';
  static const _nextFacePersonIdKey = 'next_person_id';

  static Box<dynamic>? _albumsBox;
  static Box<dynamic>? _photosBox;
  static Box<dynamic>? _faceMetaBox;

  static bool _initialized = false;
  static bool _hiveFlutterInited = false;

  /// True when boxes are open and safe to read/write.
  static bool get isReady =>
      _initialized &&
      _albumsBox != null &&
      _photosBox != null &&
      _faceMetaBox != null;

  /// Initialize Hive and open boxes. Safe to call multiple times; subsequent calls no-op.
  /// On corrupt / locked boxes, deletes on-disk boxes once and retries (common crash fix).
  static Future<void> init() async {
    if (_initialized) return;

    Object? lastError;
    StackTrace? lastStack;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        if (!_hiveFlutterInited) {
          await Hive.initFlutter();
          _hiveFlutterInited = true;
        }
        _albumsBox = await Hive.openBox<dynamic>(_albumsBoxName);
        _photosBox = await Hive.openBox<dynamic>(_photosBoxName);
        _faceMetaBox = await Hive.openBox<dynamic>(_faceMetaBoxName);
        _initialized = true;
        debugPrint('[LocalPhotoStore] init OK (attempt ${attempt + 1})');
        return;
      } catch (e, st) {
        lastError = e;
        lastStack = st;
        debugPrint(
          '[LocalPhotoStore] init attempt ${attempt + 1} failed: $e\n$st',
        );
        _albumsBox = null;
        _photosBox = null;
        _faceMetaBox = null;
        _initialized = false;
        try {
          await Hive.deleteBoxFromDisk(_albumsBoxName);
        } catch (_) {}
        try {
          await Hive.deleteBoxFromDisk(_photosBoxName);
        } catch (_) {}
        try {
          await Hive.deleteBoxFromDisk(_faceMetaBoxName);
        } catch (_) {}
      }
    }
    Error.throwWithStackTrace(
      lastError ?? StateError('LocalPhotoStore.init failed'),
      lastStack ?? StackTrace.empty,
    );
  }

  static void _ensureInitialized() {
    if (!_initialized ||
        _albumsBox == null ||
        _photosBox == null ||
        _faceMetaBox == null) {
      throw StateError(
        'LocalPhotoStore not initialized. Call LocalPhotoStore.init() first.',
      );
    }
  }

  static String _generateId({String prefix = ''}) {
    final r = Random();
    return '$prefix${DateTime.now().millisecondsSinceEpoch}_${r.nextInt(999999)}';
  }

  static String _normalizePath(String path) {
    var normalized = path.trim();
    if (normalized.startsWith('file://')) {
      normalized = normalized.substring(7);
    }
    return normalized;
  }

  // --- Albums ---

  /// All local albums, newest first.
  static List<TimelineAlbum> listAlbums() {
    _ensureInitialized();
    final box = _albumsBox!;
    final list = <TimelineAlbum>[];
    for (final key in box.keys) {
      final v = box.get(key);
      if (v is Map) {
        try {
          list.add(TimelineAlbum.fromMap(v));
        } catch (e, st) {
          debugPrint('[LocalPhotoStore] skip corrupt album $key: $e\n$st');
        }
      }
    }
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  static List<TimelineAlbum> listRootAlbums() {
    return listAlbums()
        .where((album) => (album.parentAlbumId ?? '').isEmpty)
        .toList();
  }

  static List<TimelineAlbum> listChildAlbums(String parentAlbumId) {
    final list = listAlbums()
        .where((album) => album.parentAlbumId == parentAlbumId)
        .toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  /// Create a new local album. Returns the created album.
  static TimelineAlbum addAlbum(
    String title, {
    String? parentAlbumId,
  }) {
    _ensureInitialized();
    final parent = parentAlbumId == null || parentAlbumId.trim().isEmpty
        ? null
        : getAlbum(parentAlbumId);
    final level = parent == null ? 1 : parent.level + 1;
    if (level > 2) {
      throw StateError('Only 2 album levels are supported.');
    }
    final id = _generateId(prefix: 'album_');
    final album = TimelineAlbum(
      id: id,
      title: title.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      parentAlbumId: parent?.id,
      level: level,
    );
    _albumsBox!.put(album.id, album.toMap());
    if (parent != null) {
      touchAlbum(parent.id);
    }
    return album;
  }

  /// Get a single album by id, or null if not found.
  static TimelineAlbum? getAlbum(String id) {
    _ensureInitialized();
    final v = _albumsBox!.get(id);
    if (v is Map) {
      try {
        return TimelineAlbum.fromMap(v);
      } catch (e, st) {
        debugPrint('[LocalPhotoStore] getAlbum corrupt $id: $e\n$st');
        return null;
      }
    }
    return null;
  }

  /// Update album (e.g. set backendAlbumId after first sync). Replaces by id.
  static void updateAlbum(TimelineAlbum album) {
    _ensureInitialized();
    _albumsBox!.put(album.id, album.toMap());
  }

  static void touchAlbum(String albumId, {DateTime? at}) {
    final album = getAlbum(albumId);
    if (album == null) return;
    updateAlbum(
      album.copyWith(updatedAt: at ?? DateTime.now()),
    );
  }

  /// Delete an album and all its photos.
  static void deleteAlbum(String albumId) {
    _ensureInitialized();
    final children = listChildAlbums(albumId);
    for (final child in children) {
      deleteAlbum(child.id);
    }
    _albumsBox!.delete(albumId);
    final box = _photosBox!;
    final toRemove = <String>[];
    for (final key in box.keys) {
      final v = box.get(key);
      if (v is Map) {
        final albumIdVal = (v['albumId'] ?? '').toString();
        if (albumIdVal == albumId) toRemove.add(key.toString());
      }
    }
    for (final k in toRemove) {
      box.delete(k);
    }
  }

  // --- Photos ---

  /// All photos in an album, newest first.
  static List<Photo> listPhotosInAlbum(String albumId) {
    _ensureInitialized();
    final box = _photosBox!;
    final list = <Photo>[];
    for (final key in box.keys) {
      final v = box.get(key);
      if (v is Map) {
        try {
          final photo = Photo.fromMap(v);
          if (photo.albumId == albumId) list.add(photo);
        } catch (e, st) {
          debugPrint('[LocalPhotoStore] skip corrupt photo $key: $e\n$st');
        }
      }
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Add a photo to an album. Status is [PhotoSyncStatus.localOnly].
  static Photo addPhoto({
    required String albumId,
    required String localPath,
    String? originalFileName,
    String? sourceId,
    String? localThumbnailPath,
    DateTime? createdAt,
  }) {
    _ensureInitialized();
    final existing = findPhotoInAlbum(
      albumId: albumId,
      localPath: localPath,
      sourceId: sourceId,
    );
    if (existing != null) {
      return existing;
    }

    final id = _generateId(prefix: 'photo_');
    final effectiveCreatedAt = createdAt ?? DateTime.now();
    final photo = Photo(
      id: id,
      albumId: albumId,
      localPath: _normalizePath(localPath),
      originalFileName: originalFileName?.trim().isEmpty ?? true
          ? null
          : originalFileName?.trim(),
      sourceId: sourceId,
      localThumbnailPath: localThumbnailPath,
      syncStatus: PhotoSyncStatus.localOnly,
      createdAt: effectiveCreatedAt,
    );
    _photosBox!.put(photo.id, photo.toMap());
    touchAlbum(albumId, at: effectiveCreatedAt);
    return photo;
  }

  /// Get a single photo by id, or null if not found.
  static Photo? getPhoto(String id) {
    _ensureInitialized();
    final v = _photosBox!.get(id);
    if (v is Map) {
      try {
        return Photo.fromMap(v);
      } catch (e, st) {
        debugPrint('[LocalPhotoStore] getPhoto corrupt $id: $e\n$st');
        return null;
      }
    }
    return null;
  }

  /// Update a photo (e.g. after sync: serverUrl, thumbUrl, syncStatus).
  static void updatePhoto(Photo photo) {
    _ensureInitialized();
    _photosBox!.put(photo.id, photo.toMap());
    touchAlbum(photo.albumId);
  }

  /// Delete a photo.
  static void deletePhoto(String photoId) {
    _ensureInitialized();
    final photo = getPhoto(photoId);
    _photosBox!.delete(photoId);
    if (photo != null) {
      touchAlbum(photo.albumId);
    }
  }

  static Photo? findPhotoInAlbum({
    required String albumId,
    String? localPath,
    String? sourceId,
  }) {
    _ensureInitialized();
    final normalizedLocalPath =
        localPath == null ? null : _normalizePath(localPath);
    for (final photo in listPhotosInAlbum(albumId)) {
      if (sourceId != null &&
          sourceId.isNotEmpty &&
          photo.sourceId != null &&
          photo.sourceId == sourceId) {
        return photo;
      }

      if (normalizedLocalPath != null &&
          normalizedLocalPath.isNotEmpty &&
          _normalizePath(photo.localPath) == normalizedLocalPath) {
        return photo;
      }
    }
    return null;
  }

  // --- Face metadata ---

  static Map<String, Set<String>> getFacePersonGroups() {
    _ensureInitialized();
    final raw = _faceMetaBox!.get(_faceGroupsKey);
    if (raw is! Map) return <String, Set<String>>{};

    final result = <String, Set<String>>{};
    raw.forEach((key, value) {
      final personId = key.toString().trim();
      if (personId.isEmpty) return;
      final hashes = <String>{};
      if (value is List) {
        for (final entry in value) {
          final hash = entry.toString().trim();
          if (hash.isNotEmpty) hashes.add(hash);
        }
      }
      if (hashes.isNotEmpty) {
        result[personId] = hashes;
      }
    });
    return result;
  }

  static void saveFacePersonGroups(Map<String, Set<String>> groups) {
    _ensureInitialized();
    final normalized = <String, List<String>>{};
    groups.forEach((personId, hashes) {
      final key = personId.trim();
      if (key.isEmpty) return;
      final values = hashes.map((hash) => hash.trim()).where((hash) => hash.isNotEmpty).toSet().toList()
        ..sort();
      if (values.isNotEmpty) {
        normalized[key] = values;
      }
    });
    _faceMetaBox!.put(_faceGroupsKey, normalized);
  }

  static String allocateFacePersonId() {
    _ensureInitialized();
    final current = (_faceMetaBox!.get(_nextFacePersonIdKey) as num?)?.toInt() ?? 1;
    _faceMetaBox!.put(_nextFacePersonIdKey, current + 1);
    return 'person_$current';
  }

  static Map<String, String> getFacePersonNames() {
    _ensureInitialized();
    final raw = _faceMetaBox!.get(_faceNamesKey);
    if (raw is! Map) return <String, String>{};

    final result = <String, String>{};
    raw.forEach((key, value) {
      final personId = key.toString().trim();
      final name = value.toString().trim();
      if (personId.isNotEmpty && name.isNotEmpty) {
        result[personId] = name;
      }
    });
    return result;
  }

  static void saveFacePersonNames(Map<String, String> names) {
    _ensureInitialized();
    final normalized = <String, String>{};
    names.forEach((personId, name) {
      final key = personId.trim();
      final value = name.trim();
      if (key.isNotEmpty && value.isNotEmpty) {
        normalized[key] = value;
      }
    });
    _faceMetaBox!.put(_faceNamesKey, normalized);
  }
}
