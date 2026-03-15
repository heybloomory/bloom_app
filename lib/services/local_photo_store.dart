import 'dart:math';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/album_model.dart';
import '../models/photo_model.dart';

/// Local-first storage for Timeline albums and photos using Hive.
/// Call [init] once before using (e.g. from main.dart).
class LocalPhotoStore {
  LocalPhotoStore._();

  static const _albumsBoxName = 'timeline_albums';
  static const _photosBoxName = 'timeline_photos';

  static Box<dynamic>? _albumsBox;
  static Box<dynamic>? _photosBox;

  static bool _initialized = false;

  /// Initialize Hive and open boxes. Safe to call multiple times; subsequent calls no-op.
  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _albumsBox = await Hive.openBox(_albumsBoxName);
    _photosBox = await Hive.openBox(_photosBoxName);
    _initialized = true;
  }

  static void _ensureInitialized() {
    if (!_initialized || _albumsBox == null || _photosBox == null) {
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
        list.add(TimelineAlbum.fromMap(v));
      }
    }
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  /// Create a new local album. Returns the created album.
  static TimelineAlbum addAlbum(String title) {
    _ensureInitialized();
    final id = _generateId(prefix: 'album_');
    final album = TimelineAlbum(
      id: id,
      title: title.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _albumsBox!.put(album.id, album.toMap());
    return album;
  }

  /// Get a single album by id, or null if not found.
  static TimelineAlbum? getAlbum(String id) {
    _ensureInitialized();
    final v = _albumsBox!.get(id);
    if (v is Map) {
      return TimelineAlbum.fromMap(v);
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
        final photo = Photo.fromMap(v);
        if (photo.albumId == albumId) list.add(photo);
      }
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Add a photo to an album. Status is [PhotoSyncStatus.localOnly].
  static Photo addPhoto({
    required String albumId,
    required String localPath,
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
      return Photo.fromMap(v);
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
}
