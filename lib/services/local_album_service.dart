import 'package:flutter/foundation.dart';

import '../models/album_model.dart';
import '../models/photo_model.dart';
import '../models/timeline_album_summary.dart';
import 'local_photo_store.dart';

class LocalAlbumService {
  LocalAlbumService._();

  static List<TimelineAlbumSummary> listRootAlbumSummaries() {
    return _listAlbumSummaries(LocalPhotoStore.listRootAlbums());
  }

  static List<TimelineAlbumSummary> listChildAlbumSummaries(String parentAlbumId) {
    return _listAlbumSummaries(LocalPhotoStore.listChildAlbums(parentAlbumId));
  }

  static TimelineAlbum? getAlbum(String albumId) {
    if (!LocalPhotoStore.isReady) {
      debugPrint('[LocalAlbumService] getAlbum: store not ready');
      return null;
    }
    return LocalPhotoStore.getAlbum(albumId);
  }

  static List<TimelineAlbumSummary> listAlbumSummaries() {
    return _listAlbumSummaries(LocalPhotoStore.listAlbums());
  }

  static List<TimelineAlbumSummary> _listAlbumSummaries(List<TimelineAlbum> albums) {
    if (!LocalPhotoStore.isReady) {
      debugPrint('[LocalAlbumService] listAlbumSummaries: store not ready');
      return <TimelineAlbumSummary>[];
    }
    try {
      for (final album in albums) {
        LocalPhotoStore.ensureAlbumCover(album.id);
      }
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
    } catch (e, st) {
      debugPrint('[LocalAlbumService] listAlbumSummaries error: $e\n$st');
      return <TimelineAlbumSummary>[];
    }
  }

  static TimelineAlbum createAlbum(String title, {String? parentAlbumId}) {
    if (!LocalPhotoStore.isReady) {
      throw StateError(
        'Local library is not ready yet. Restart the app or try again in a moment.',
      );
    }
    return LocalPhotoStore.addAlbum(title, parentAlbumId: parentAlbumId);
  }

  static TimelineSearchResults search({
    String query = '',
    TimelineSearchScope scope = TimelineSearchScope.all,
    TimelineSyncFilter syncFilter = TimelineSyncFilter.all,
    TimelineLevelFilter levelFilter = TimelineLevelFilter.all,
    String? personClusterId,
  }) {
    if (!LocalPhotoStore.isReady) {
      return const TimelineSearchResults(
        albumResults: <TimelineAlbumSummary>[],
        photoResults: <TimelinePhotoSearchResult>[],
      );
    }

    final normalizedQuery = query.trim().toLowerCase();
    final albumSummaries = listAlbumSummaries();

    bool albumMatchesLevel(TimelineAlbumSummary summary) {
      switch (levelFilter) {
        case TimelineLevelFilter.all:
          return true;
        case TimelineLevelFilter.root:
          return summary.album.level == 1;
        case TimelineLevelFilter.subAlbum:
          return summary.album.level >= 2;
      }
    }

    bool photoMatchesSync(Photo photo) {
      switch (syncFilter) {
        case TimelineSyncFilter.all:
          return true;
        case TimelineSyncFilter.localOnly:
          return photo.syncStatus == PhotoSyncStatus.localOnly;
        case TimelineSyncFilter.synced:
          return photo.syncStatus == PhotoSyncStatus.synced;
        case TimelineSyncFilter.pending:
          return photo.syncStatus == PhotoSyncStatus.uploading;
        case TimelineSyncFilter.failed:
          return photo.syncStatus == PhotoSyncStatus.failed;
      }
    }

    bool albumMatchesQuery(TimelineAlbumSummary summary) {
      if (normalizedQuery.isEmpty) return true;
      return summary.album.title.toLowerCase().contains(normalizedQuery);
    }

    bool photoMatchesQuery(Photo photo) {
      if (normalizedQuery.isEmpty) return true;
      final name = (photo.originalFileName ?? '').toLowerCase();
      final path = photo.localPath.toLowerCase();
      return name.contains(normalizedQuery) || path.contains(normalizedQuery);
    }

    bool photoMatchesPerson(Photo photo) {
      final clusterId = (personClusterId ?? '').trim();
      if (clusterId.isEmpty) return true;
      return photo.faces.any((face) => face.clusterId == clusterId);
    }

    final albumResults = albumSummaries
        .where(albumMatchesLevel)
        .where((summary) {
          final scopeAllowsAlbum = scope == TimelineSearchScope.all ||
              scope == TimelineSearchScope.albums;
          if (!scopeAllowsAlbum) return false;
          final queryMatch = albumMatchesQuery(summary);
          if (queryMatch) return true;
          if (normalizedQuery.isEmpty) return true;
          return summary.photos.any(
            (photo) => photoMatchesQuery(photo) && photoMatchesPerson(photo),
          );
        })
        .toList();

    final photoResults = <TimelinePhotoSearchResult>[];
    final scopeAllowsPhotos =
        scope == TimelineSearchScope.all || scope == TimelineSearchScope.images;

    if (scopeAllowsPhotos) {
      for (final summary in albumSummaries.where(albumMatchesLevel)) {
        for (final photo in summary.photos) {
          if (!photoMatchesSync(photo)) continue;
          if (!photoMatchesQuery(photo)) continue;
          if (!photoMatchesPerson(photo)) continue;
          photoResults.add(
            TimelinePhotoSearchResult(
              albumSummary: summary,
              photo: photo,
            ),
          );
        }
      }
    }

    photoResults.sort(
      (a, b) => b.photo.createdAt.compareTo(a.photo.createdAt),
    );

    return TimelineSearchResults(
      albumResults: albumResults,
      photoResults: photoResults,
    );
  }
}

enum TimelineSearchScope {
  all,
  albums,
  images,
}

enum TimelineSyncFilter {
  all,
  localOnly,
  synced,
  pending,
  failed,
}

enum TimelineLevelFilter {
  all,
  root,
  subAlbum,
}

class TimelinePhotoSearchResult {
  final TimelineAlbumSummary albumSummary;
  final Photo photo;

  const TimelinePhotoSearchResult({
    required this.albumSummary,
    required this.photo,
  });
}

class TimelineSearchResults {
  final List<TimelineAlbumSummary> albumResults;
  final List<TimelinePhotoSearchResult> photoResults;

  const TimelineSearchResults({
    required this.albumResults,
    required this.photoResults,
  });
}
