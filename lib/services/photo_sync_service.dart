import '../core/services/album_api_service.dart';
import '../core/services/firestore_sync_service.dart';
import '../core/services/media_api_service.dart';
import '../core/utils/image_compress.dart';
import '../models/album_model.dart';
import '../models/photo_model.dart';
import 'file_reader.dart';
import 'local_photo_store.dart';

/// Syncs local Timeline albums/photos to the backend using existing API services.
/// Does not modify authentication, API services, or backend routes.
class PhotoSyncService {
  PhotoSyncService._();

  /// Sync one local album to the backend.
  /// 1. If album has no [TimelineAlbum.backendAlbumId], creates backend album via [AlbumApiService.createAlbum].
  /// 2. For each photo with status [PhotoSyncStatus.localOnly] or [PhotoSyncStatus.failed]:
  ///    - Sets status to [PhotoSyncStatus.uploading]
  ///    - Reads file from [Photo.localPath]
  ///    - Uploads via [MediaApiService.uploadToAlbum]
  /// 3. On success: saves [Photo.serverUrl] (and [Photo.thumbUrl] if present), sets status to [PhotoSyncStatus.synced].
  /// 4. On error: sets status to [PhotoSyncStatus.failed] and saves error message.
  ///
  /// Throws if album is not found, or if creating the backend album fails.
  /// Individual photo failures are recorded on the photo (status failed + errorMessage); they do not throw.
  static Future<void> syncAlbum(String localAlbumId) async {
    final album = LocalPhotoStore.getAlbum(localAlbumId);
    if (album == null) {
      throw Exception('Album not found: $localAlbumId');
    }

    String backendAlbumId = album.backendAlbumId ?? '';

    if (backendAlbumId.isEmpty) {
      final created = await AlbumApiService.createAlbum(
        title: album.title,
      );
      final id = (created['id'] ?? created['_id'])?.toString();
      if (id == null || id.isEmpty) {
        throw Exception('Backend did not return album id');
      }
      backendAlbumId = id;
      LocalPhotoStore.updateAlbum(
        album.copyWith(backendAlbumId: backendAlbumId),
      );
    }

    final photos = LocalPhotoStore.listPhotosInAlbum(localAlbumId);
    final toSync = photos.where((p) =>
        p.syncStatus == PhotoSyncStatus.localOnly ||
        p.syncStatus == PhotoSyncStatus.failed);

    for (final photo in toSync) {
      LocalPhotoStore.updatePhoto(
        photo.copyWith(
          syncStatus: PhotoSyncStatus.uploading,
          errorMessage: null,
        ),
      );

      final bytes = await readFileBytes(photo.localPath);
      if (bytes == null || bytes.isEmpty) {
        LocalPhotoStore.updatePhoto(
          photo.copyWith(
            syncStatus: PhotoSyncStatus.failed,
            errorMessage:
                'Could not read file (e.g. unsupported on web or file missing)',
          ),
        );
        continue;
      }

      final fileName = _basename(photo.localPath);
      if (fileName.isEmpty) {
        LocalPhotoStore.updatePhoto(
          photo.copyWith(
            syncStatus: PhotoSyncStatus.failed,
            errorMessage: 'Invalid file path',
          ),
        );
        continue;
      }

      final uploadBytes = _isImagePath(photo.localPath)
          ? await ImageCompress.compressForUpload(bytes,
              quality: 75, maxWidth: 1920)
          : bytes;
      final uploadFileName = _isImagePath(photo.localPath)
          ? ImageCompress.toJpegName(fileName)
          : fileName;

      try {
        final media = await MediaApiService.uploadToAlbum(
          albumId: backendAlbumId,
          bytes: uploadBytes,
          fileName: uploadFileName,
        );
        final serverUrl =
            (media['url'] ?? media['cdnUrl'] ?? media['fileUrl'])?.toString();
        final thumbUrl =
            (media['thumbUrl'] ?? media['thumbnailUrl'] ?? media['thumb_url'])
                ?.toString();

        LocalPhotoStore.updatePhoto(
          photo.copyWith(
            serverUrl: serverUrl,
            thumbUrl: thumbUrl,
            syncStatus: PhotoSyncStatus.synced,
            errorMessage: null,
          ),
        );
        try {
          await FirestoreSyncService.upsertMediaFromApi(
            albumId: backendAlbumId,
            media: media,
          );
        } catch (_) {
          // Timeline is local-first; Firestore mirror is best effort only.
        }
      } catch (e) {
        LocalPhotoStore.updatePhoto(
          photo.copyWith(
            syncStatus: PhotoSyncStatus.failed,
            errorMessage: e.toString(),
          ),
        );
      }
    }
  }

  static String _basename(String path) {
    final p = path.replaceAll(r'\', '/');
    final i = p.lastIndexOf('/');
    return i < 0 ? p : p.substring(i + 1);
  }

  static bool _isImagePath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.heic') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.bmp');
  }
}
