import '../models/album_model.dart';
import '../models/timeline_album_summary.dart';
import 'local_photo_store.dart';

class LocalAlbumService {
  LocalAlbumService._();

  static List<TimelineAlbumSummary> listAlbumSummaries() {
    final albums = LocalPhotoStore.listAlbums();
    return albums
        .map(
          (album) => TimelineAlbumSummary(
            album: album,
            photos: LocalPhotoStore.listPhotosInAlbum(album.id),
          ),
        )
        .toList()
      ..sort((a, b) {
        final aTime = a.latestPhotoAt ?? a.album.updatedAt;
        final bTime = b.latestPhotoAt ?? b.album.updatedAt;
        return bTime.compareTo(aTime);
      });
  }

  static TimelineAlbum createAlbum(String title) {
    return LocalPhotoStore.addAlbum(title);
  }
}
