import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../core/utils/image_compress.dart';
import 'album_picked_media.dart';
import 'local_photo_store.dart';
import 'local_album_media_import_service_stub.dart';

class LocalAlbumMediaImportService {
  LocalAlbumMediaImportService._();

  static Future<AlbumImportResult> importPickedMedia({
    required String albumId,
    required List<AlbumPickedMedia> items,
  }) async {
    final root = await _albumRootDir(albumId);
    var addedCount = 0;
    var duplicateCount = 0;

    for (final item in items) {
      final originalPath = (item.originalPath ?? '').trim();
      final existing = LocalPhotoStore.findPhotoInAlbum(
        albumId: albumId,
        sourceId: item.sourceId,
        localPath: originalPath.isEmpty ? null : originalPath,
      );
      if (existing != null) {
        duplicateCount += 1;
        continue;
      }

      final fileName =
          _safeFileName(item.name.isNotEmpty ? item.name : 'photo.jpg');
      final uniqueBase =
          '${DateTime.now().microsecondsSinceEpoch}_${addedCount + duplicateCount}';
      final ext = _extension(fileName);
      final mediaPath = '${root.path}/$uniqueBase$ext';
      final thumbPath = '${root.path}/${uniqueBase}_thumb.jpg';

      await File(mediaPath).writeAsBytes(item.bytes, flush: true);

      String? savedThumbPath;
      final thumbBytes = await ImageCompress.thumbnailJpeg(
        item.bytes,
        quality: 72,
        width: 480,
        height: 480,
      );
      if (thumbBytes.isNotEmpty) {
        await File(thumbPath).writeAsBytes(thumbBytes, flush: true);
        savedThumbPath = thumbPath;
      }

      DateTime? createdAt;
      if (originalPath.isNotEmpty) {
        try {
          createdAt = await File(originalPath).lastModified();
        } catch (_) {
          createdAt = null;
        }
      }

      LocalPhotoStore.addPhoto(
        albumId: albumId,
        localPath: mediaPath,
        originalFileName: item.name,
        sourceId: item.sourceId,
        localThumbnailPath: savedThumbPath,
        createdAt: createdAt ?? item.selectedAt,
      );
      addedCount += 1;
    }

    return AlbumImportResult(
      addedCount: addedCount,
      duplicateCount: duplicateCount,
    );
  }

  static Future<Directory> _albumRootDir(String albumId) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${baseDir.path}/bloomory/albums/$albumId');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _safeFileName(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  static String _extension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0) {
      return '.jpg';
    }
    return fileName.substring(dot);
  }
}
