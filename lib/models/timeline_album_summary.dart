import 'album_model.dart';
import 'photo_model.dart';

class TimelineAlbumSummary {
  final TimelineAlbum album;
  final List<Photo> photos;

  const TimelineAlbumSummary({
    required this.album,
    required this.photos,
  });

  int get photoCount => photos.length;

  int get syncedCount => photos
      .where((photo) => photo.syncStatus == PhotoSyncStatus.synced)
      .length;

  int get failedCount => photos
      .where((photo) => photo.syncStatus == PhotoSyncStatus.failed)
      .length;

  int get pendingCount => photos
      .where((photo) =>
          photo.syncStatus == PhotoSyncStatus.localOnly ||
          photo.syncStatus == PhotoSyncStatus.uploading)
      .length;

  Photo? get coverPhoto => photos.isNotEmpty ? photos.first : null;

  DateTime? get latestPhotoAt =>
      photos.isNotEmpty ? photos.first.createdAt : album.updatedAt;

  DateTime? get earliestPhotoAt =>
      photos.isNotEmpty ? photos.last.createdAt : album.createdAt;
}
