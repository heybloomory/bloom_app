/// Sync status for a locally stored photo.
const Object _photoUnset = Object();

enum PhotoSyncStatus {
  localOnly,
  uploading,
  synced,
  failed,
}

extension PhotoSyncStatusExt on PhotoSyncStatus {
  static PhotoSyncStatus fromString(String value) {
    switch (value) {
      case 'local_only':
        return PhotoSyncStatus.localOnly;
      case 'uploading':
        return PhotoSyncStatus.uploading;
      case 'synced':
        return PhotoSyncStatus.synced;
      case 'failed':
        return PhotoSyncStatus.failed;
      default:
        return PhotoSyncStatus.localOnly;
    }
  }

  String get value {
    switch (this) {
      case PhotoSyncStatus.localOnly:
        return 'local_only';
      case PhotoSyncStatus.uploading:
        return 'uploading';
      case PhotoSyncStatus.synced:
        return 'synced';
      case PhotoSyncStatus.failed:
        return 'failed';
    }
  }
}

/// Local-first photo record for the Timeline.
/// Stored in Hive; may have only [localPath] or, after sync, [serverUrl]/[thumbUrl].
class Photo {
  final String id;
  final String albumId;
  final String localPath;
  final String? sourceId;
  final String? localThumbnailPath;
  final String? serverUrl;
  final String? thumbUrl;
  final PhotoSyncStatus syncStatus;
  final DateTime createdAt;
  final String? errorMessage;

  const Photo({
    required this.id,
    required this.albumId,
    required this.localPath,
    this.sourceId,
    this.localThumbnailPath,
    this.serverUrl,
    this.thumbUrl,
    this.syncStatus = PhotoSyncStatus.localOnly,
    required this.createdAt,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'albumId': albumId,
      'localPath': localPath,
      'sourceId': sourceId,
      'localThumbnailPath': localThumbnailPath,
      'serverUrl': serverUrl,
      'thumbUrl': thumbUrl,
      'syncStatus': syncStatus.value,
      'createdAt': createdAt.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  static Photo fromMap(Map<dynamic, dynamic> map) {
    final createdAtRaw = map['createdAt'];
    DateTime createdAt = DateTime.now();
    if (createdAtRaw != null) {
      if (createdAtRaw is DateTime) {
        createdAt = createdAtRaw;
      } else {
        createdAt = DateTime.tryParse(createdAtRaw.toString()) ?? createdAt;
      }
    }
    return Photo(
      id: (map['id'] ?? '').toString(),
      albumId: (map['albumId'] ?? '').toString(),
      localPath: (map['localPath'] ?? '').toString(),
      sourceId: map['sourceId']?.toString(),
      localThumbnailPath: map['localThumbnailPath']?.toString(),
      serverUrl: map['serverUrl']?.toString(),
      thumbUrl: map['thumbUrl']?.toString(),
      syncStatus: PhotoSyncStatusExt.fromString(
        (map['syncStatus'] ?? 'local_only').toString(),
      ),
      createdAt: createdAt,
      errorMessage: map['errorMessage']?.toString(),
    );
  }

  Photo copyWith({
    String? id,
    String? albumId,
    String? localPath,
    Object? sourceId = _photoUnset,
    Object? localThumbnailPath = _photoUnset,
    Object? serverUrl = _photoUnset,
    Object? thumbUrl = _photoUnset,
    PhotoSyncStatus? syncStatus,
    DateTime? createdAt,
    Object? errorMessage = _photoUnset,
  }) {
    return Photo(
      id: id ?? this.id,
      albumId: albumId ?? this.albumId,
      localPath: localPath ?? this.localPath,
      sourceId: identical(sourceId, _photoUnset)
          ? this.sourceId
          : sourceId as String?,
      localThumbnailPath: identical(localThumbnailPath, _photoUnset)
          ? this.localThumbnailPath
          : localThumbnailPath as String?,
      serverUrl: identical(serverUrl, _photoUnset)
          ? this.serverUrl
          : serverUrl as String?,
      thumbUrl: identical(thumbUrl, _photoUnset)
          ? this.thumbUrl
          : thumbUrl as String?,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      errorMessage: identical(errorMessage, _photoUnset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
