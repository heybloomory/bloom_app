import '../core/services/album_api_service.dart';
import '../core/services/media_api_service.dart';
import '../core/utils/image_compress.dart';
import '../models/album_model.dart';
import '../models/photo_model.dart';
import 'file_reader.dart';
import 'local_photo_store.dart';

/// Core upload + album creation (shared by [PhotoSyncService] and [SyncQueueService]).
class PhotoSyncCore {
  PhotoSyncCore._();

  static Future<TimelineAlbum> ensureBackendAlbum(TimelineAlbum album) async {
    var current = album;
    final existingBackendId = current.backendAlbumId ?? '';
    if (existingBackendId.isNotEmpty) {
      return current;
    }

    String? backendParentId;
    final parentAlbumId = current.parentAlbumId ?? '';
    if (parentAlbumId.isNotEmpty) {
      final parent = LocalPhotoStore.getAlbum(parentAlbumId);
      if (parent == null) {
        throw Exception('Parent album not found for ${current.title}');
      }
      final syncedParent = await ensureBackendAlbum(parent);
      backendParentId = syncedParent.backendAlbumId;
      if (backendParentId == null || backendParentId.isEmpty) {
        throw Exception('Parent album failed to sync for ${current.title}');
      }
    }

    final created = await AlbumApiService.createAlbum(
      title: current.title,
      parentId: backendParentId,
    );
    final id = (created['id'] ?? created['_id'])?.toString();
    if (id == null || id.isEmpty) {
      throw Exception('Backend did not return album id');
    }

    current = current.copyWith(backendAlbumId: id);
    LocalPhotoStore.updateAlbum(current);
    return current;
  }

  static Future<void> syncSinglePhoto({
    required Photo photo,
    required String backendAlbumId,
  }) async {
    await LocalPhotoStore.init();
    LocalPhotoStore.updatePhoto(
      photo.copyWith(
        syncStatus: PhotoSyncStatus.uploading,
        errorMessage: null,
      ),
    );
    final fresh = LocalPhotoStore.getPhoto(photo.id) ?? photo;

    final bytes = await readFileBytes(fresh.localPath);
    if (bytes == null || bytes.isEmpty) {
      LocalPhotoStore.updatePhoto(
        fresh.copyWith(
          syncStatus: PhotoSyncStatus.failed,
          errorMessage:
              'Could not read file (e.g. unsupported on web or file missing)',
        ),
      );
      return;
    }

    final sourceFileName = _preferredFileName(fresh);
    if (sourceFileName.isEmpty) {
      LocalPhotoStore.updatePhoto(
        fresh.copyWith(
          syncStatus: PhotoSyncStatus.failed,
          errorMessage: 'Invalid file path',
        ),
      );
      return;
    }

    final uploadBytes = _isImagePath(sourceFileName)
        ? await ImageCompress.compressForUpload(bytes,
            quality: 75, maxWidth: 1920)
        : bytes;
    final uploadFileName = _isImagePath(sourceFileName)
        ? ImageCompress.toJpegName(sourceFileName)
        : sourceFileName;

    try {
      final media = await MediaApiService.uploadToAlbum(
        albumId: backendAlbumId,
        bytes: uploadBytes,
        fileName: uploadFileName,
        originalFileName: fresh.originalFileName ?? sourceFileName,
      );
      final serverUrl =
          (media['url'] ?? media['cdnUrl'] ?? media['fileUrl'])?.toString();
      final thumbUrl =
          (media['thumbUrl'] ?? media['thumbnailUrl'] ?? media['thumb_url'])
              ?.toString();

      LocalPhotoStore.updatePhoto(
        fresh.copyWith(
          serverUrl: serverUrl,
          thumbUrl: thumbUrl,
          syncStatus: PhotoSyncStatus.synced,
          errorMessage: null,
        ),
      );
    } catch (e) {
      LocalPhotoStore.updatePhoto(
        fresh.copyWith(
          syncStatus: PhotoSyncStatus.failed,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  static String _basename(String path) {
    final p = path.replaceAll(r'\', '/');
    final i = p.lastIndexOf('/');
    return i < 0 ? p : p.substring(i + 1);
  }

  static String _preferredFileName(Photo photo) {
    final original = (photo.originalFileName ?? '').trim();
    if (original.isNotEmpty) return original;
    return _basename(photo.localPath);
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
