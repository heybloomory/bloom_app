import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/services/api_config.dart';
import '../models/photo_model.dart';
import 'local_photo_store.dart';
import 'photo_sync_service.dart';

/// Automatically syncs local Timeline photos when internet is available.
/// Triggers: app startup, every 60 seconds, when user opens Timeline.
/// Does not modify authentication or API services.
class AutoSyncService {
  AutoSyncService._();

  static Timer? _timer;
  static const _interval = Duration(seconds: 60);

  /// Start background auto-sync: run once now, then every 60 seconds.
  static void start() {
    runNow();
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) => runNow());
  }

  /// Stop the periodic timer (e.g. on app dispose if needed).
  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Run one sync pass: if online, sync all albums that have local_only or failed photos.
  static Future<void> runNow() async {
    try {
      await LocalPhotoStore.init();
    } catch (e, st) {
      // Local-first: skip sync pass if store cannot open.
      debugPrint('[AutoSync] LocalPhotoStore.init failed: $e\n$st');
      return;
    }
    final ok = await _isOnline();
    if (!ok) return;

    final albumIds = _albumsWithUnsyncedPhotos();
    if (albumIds.isEmpty) return;

    for (final albumId in albumIds) {
      try {
        await PhotoSyncService.syncAlbum(albumId);
      } catch (_) {
        // Ignore (e.g. not logged in, network error, album not found).
      }
    }
  }

  static Future<bool> _isOnline() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static List<String> _albumsWithUnsyncedPhotos() {
    try {
      final albums = LocalPhotoStore.listAlbums();
      final result = <String>[];
      for (final album in albums) {
        final photos = LocalPhotoStore.listPhotosInAlbum(album.id);
        final hasUnsynced = photos.any((p) =>
            p.syncStatus == PhotoSyncStatus.localOnly ||
            p.syncStatus == PhotoSyncStatus.failed);
        if (hasUnsynced) result.add(album.id);
      }
      return result;
    } catch (_) {
      return [];
    }
  }
}
