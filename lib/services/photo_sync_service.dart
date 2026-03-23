import 'package:flutter/foundation.dart';

import '../core/services/album_api_service.dart';
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
    await LocalPhotoStore.init();
    final album = LocalPhotoStore.getAlbum(localAlbumId);
    if (album == null) {
      throw Exception('Album not found: $localAlbumId');
    }

    await _syncAlbumTree(album);
  }

  static Future<void> _syncAlbumTree(TimelineAlbum album) async {
    final syncedAlbum = await _ensureBackendAlbum(album);
    final backendAlbumId = syncedAlbum.backendAlbumId ?? '';

    if (backendAlbumId.isEmpty) {
      throw Exception('Backend album id missing after sync preparation.');
    }

    final photos = LocalPhotoStore.listPhotosInAlbum(album.id);
    final toSyncList = photos
        .where((p) =>
            p.syncStatus == PhotoSyncStatus.localOnly ||
            p.syncStatus == PhotoSyncStatus.failed)
        .toList();
    debugPrint('[PhotoSync] sync queue size for ${album.title}: ${toSyncList.length}');

    for (final photo in toSyncList) {
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

      final sourceFileName = _preferredFileName(photo);
      if (sourceFileName.isEmpty) {
        LocalPhotoStore.updatePhoto(
          photo.copyWith(
            syncStatus: PhotoSyncStatus.failed,
            errorMessage: 'Invalid file path',
          ),
        );
        continue;
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
          originalFileName: photo.originalFileName ?? sourceFileName,
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
      } catch (e) {
        LocalPhotoStore.updatePhoto(
          photo.copyWith(
            syncStatus: PhotoSyncStatus.failed,
            errorMessage: e.toString(),
          ),
        );
      }
    }

    final children = LocalPhotoStore.listChildAlbums(album.id);
    for (final child in children) {
      await _syncAlbumTree(child);
    }
  }

  static Future<TimelineAlbum> _ensureBackendAlbum(TimelineAlbum album) async {
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
      final syncedParent = await _ensureBackendAlbum(parent);
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
