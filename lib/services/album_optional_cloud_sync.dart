import '../models/photo_model.dart';
import 'local_photo_store.dart';
import 'photo_sync_service.dart';
import 'sync/sync_queue_service.dart';

/// Optional per-album cloud sync. Does not auto-run. Uses [SyncQueueService] + existing APIs.
class AlbumOptionalCloudSync {
  AlbumOptionalCloudSync._();

  /// Enqueues this album tree, drains the queue, then updates [TimelineAlbum.isSynced]
  /// when no failures / pending uploads remain in that tree.
  static Future<void> syncAlbumToCloud(String localAlbumId) async {
    await SyncQueueService.instance.init();
    await PhotoSyncService.syncAlbum(localAlbumId);
    final album = LocalPhotoStore.getAlbum(localAlbumId);
    if (album == null) return;

    var failed = false;
    var pending = false;

    void walk(String albumId) {
      for (final p in LocalPhotoStore.listPhotosInAlbum(albumId)) {
        if (p.syncStatus == PhotoSyncStatus.failed) failed = true;
        if (p.syncStatus == PhotoSyncStatus.localOnly ||
            p.syncStatus == PhotoSyncStatus.uploading) {
          pending = true;
        }
      }
      for (final c in LocalPhotoStore.listChildAlbums(albumId)) {
        walk(c.id);
      }
    }

    walk(localAlbumId);
    final qPending =
        SyncQueueService.instance.pendingCountForAlbumTree(localAlbumId);
    pending = pending || qPending > 0;

    LocalPhotoStore.updateAlbum(
      album.copyWith(isSynced: !failed && !pending),
    );
  }
}
