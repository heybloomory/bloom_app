import 'package:flutter/foundation.dart' show kIsWeb;

import 'album_picked_media.dart';
import 'local_photo_store.dart';

class AlbumImportResult {
  final int addedCount;
  final int duplicateCount;

  const AlbumImportResult({
    required this.addedCount,
    required this.duplicateCount,
  });
}

class LocalAlbumMediaImportService {
  LocalAlbumMediaImportService._();

  static Future<AlbumImportResult> importPickedMedia({
    required String albumId,
    required List<AlbumPickedMedia> items,
  }) async {
    if (!kIsWeb) {
      return const AlbumImportResult(addedCount: 0, duplicateCount: 0);
    }

    var addedCount = 0;
    var duplicateCount = 0;

    for (final item in items) {
      final existing = LocalPhotoStore.findPhotoInAlbum(
        albumId: albumId,
        sourceId: item.sourceId,
      );
      if (existing != null) {
        duplicateCount += 1;
        continue;
      }

      LocalPhotoStore.addPhoto(
        albumId: albumId,
        localPath: 'web_${DateTime.now().millisecondsSinceEpoch}_${item.name}',
        sourceId: item.sourceId,
        createdAt: item.selectedAt,
      );
      addedCount += 1;
    }

    return AlbumImportResult(
      addedCount: addedCount,
      duplicateCount: duplicateCount,
    );
  }
}
