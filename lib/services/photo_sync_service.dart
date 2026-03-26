import '../models/album_model.dart';
import '../models/photo_model.dart';
import 'local_photo_store.dart';
import 'photo_sync_core.dart';
import 'sync/sync_queue_service.dart';

/// Syncs local Timeline albums/photos to the backend using existing API services.
///
/// [syncAlbum] enqueues work into [SyncQueueService] and drains it (sequential uploads, retries).
class PhotoSyncService {
  PhotoSyncService._();

  /// Sync one local album tree to the backend via the offline-first queue.
  static Future<void> syncAlbum(String localAlbumId) async {
    await LocalPhotoStore.init();
    final album = LocalPhotoStore.getAlbum(localAlbumId);
    if (album == null) {
      throw Exception('Album not found: $localAlbumId');
    }
    await SyncQueueService.instance.init();
    await SyncQueueService.instance.enqueueAlbumSyncTree(localAlbumId);
    await SyncQueueService.instance.drain();
  }

  /// Ensure [album] and ancestors exist on the server; returns album with [backendAlbumId].
  static Future<TimelineAlbum> ensureBackendAlbum(TimelineAlbum album) =>
      PhotoSyncCore.ensureBackendAlbum(album);

  /// Upload a single photo (used by [SyncQueueService]).
  static Future<void> syncSinglePhoto({
    required Photo photo,
    required String backendAlbumId,
  }) =>
      PhotoSyncCore.syncSinglePhoto(
        photo: photo,
        backendAlbumId: backendAlbumId,
      );
}
