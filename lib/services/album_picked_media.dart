import 'dart:typed_data';

class AlbumPickedMedia {
  final String name;
  final String sourceId;
  final String? originalPath;
  final Uint8List bytes;
  final DateTime selectedAt;

  const AlbumPickedMedia({
    required this.name,
    required this.sourceId,
    required this.bytes,
    required this.selectedAt,
    this.originalPath,
  });
}

class AlbumMediaPickResult {
  final List<AlbumPickedMedia> items;
  final bool usedDocumentFallback;
  final bool noGalleryMediaLikely;

  const AlbumMediaPickResult({
    required this.items,
    this.usedDocumentFallback = false,
    this.noGalleryMediaLikely = false,
  });

  bool get isEmpty => items.isEmpty;
}
