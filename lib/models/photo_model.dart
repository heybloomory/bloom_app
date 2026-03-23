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
class PhotoComment {
  final String authorName;
  final String text;
  final DateTime createdAt;

  const PhotoComment({
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'authorName': authorName,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static PhotoComment fromMap(Map<dynamic, dynamic> map) {
    final createdAtRaw = map['createdAt'];
    DateTime createdAt = DateTime.now();
    if (createdAtRaw != null) {
      if (createdAtRaw is DateTime) {
        createdAt = createdAtRaw;
      } else {
        createdAt = DateTime.tryParse(createdAtRaw.toString()) ?? createdAt;
      }
    }

    return PhotoComment(
      authorName: (map['authorName'] ?? 'You').toString(),
      text: (map['text'] ?? '').toString(),
      createdAt: createdAt,
    );
  }
}

class PhotoFace {
  final double left;
  final double top;
  final double width;
  final double height;
  final String hash;
  final String clusterId;
  final String thumbnailPath;

  const PhotoFace({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.hash,
    required this.clusterId,
    required this.thumbnailPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'left': left,
      'top': top,
      'width': width,
      'height': height,
      'hash': hash,
      'clusterId': clusterId,
      'thumbnailPath': thumbnailPath,
    };
  }

  static PhotoFace fromMap(Map<dynamic, dynamic> map) {
    return PhotoFace(
      left: (map['left'] as num?)?.toDouble() ?? 0,
      top: (map['top'] as num?)?.toDouble() ?? 0,
      width: (map['width'] as num?)?.toDouble() ?? 0,
      height: (map['height'] as num?)?.toDouble() ?? 0,
      hash: (map['hash'] ?? '').toString(),
      clusterId: (map['clusterId'] ?? '').toString(),
      thumbnailPath: (map['thumbnailPath'] ?? '').toString(),
    );
  }

  PhotoFace copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
    String? hash,
    String? clusterId,
    String? thumbnailPath,
  }) {
    return PhotoFace(
      left: left ?? this.left,
      top: top ?? this.top,
      width: width ?? this.width,
      height: height ?? this.height,
      hash: hash ?? this.hash,
      clusterId: clusterId ?? this.clusterId,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
}

class Photo {
  final String id;
  final String albumId;
  final String localPath;
  final String? originalFileName;
  final String? sourceId;
  final String? localThumbnailPath;
  final String? serverUrl;
  final String? thumbUrl;
  final PhotoSyncStatus syncStatus;
  final DateTime createdAt;
  final int likeCount;
  final bool isLikedByMe;
  final List<PhotoComment> comments;
  final List<PhotoFace> faces;
  final String? errorMessage;

  const Photo({
    required this.id,
    required this.albumId,
    required this.localPath,
    this.originalFileName,
    this.sourceId,
    this.localThumbnailPath,
    this.serverUrl,
    this.thumbUrl,
    this.syncStatus = PhotoSyncStatus.localOnly,
    required this.createdAt,
    this.likeCount = 0,
    this.isLikedByMe = false,
    this.comments = const <PhotoComment>[],
    this.faces = const <PhotoFace>[],
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'albumId': albumId,
      'localPath': localPath,
      'originalFileName': originalFileName,
      'sourceId': sourceId,
      'localThumbnailPath': localThumbnailPath,
      'serverUrl': serverUrl,
      'thumbUrl': thumbUrl,
      'syncStatus': syncStatus.value,
      'createdAt': createdAt.toIso8601String(),
      'likeCount': likeCount,
      'isLikedByMe': isLikedByMe,
      'comments': comments.map((comment) => comment.toMap()).toList(),
      'faces': faces.map((face) => face.toMap()).toList(),
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
      originalFileName: map['originalFileName']?.toString(),
      sourceId: map['sourceId']?.toString(),
      localThumbnailPath: map['localThumbnailPath']?.toString(),
      serverUrl: map['serverUrl']?.toString(),
      thumbUrl: map['thumbUrl']?.toString(),
      syncStatus: PhotoSyncStatusExt.fromString(
        (map['syncStatus'] ?? 'local_only').toString(),
      ),
      createdAt: createdAt,
      likeCount: (map['likeCount'] as num?)?.toInt() ?? 0,
      isLikedByMe: map['isLikedByMe'] == true,
      comments: ((map['comments'] as List?) ?? const [])
          .whereType<Map>()
          .map(PhotoComment.fromMap)
          .toList(),
      faces: ((map['faces'] as List?) ?? const [])
          .whereType<Map>()
          .map(PhotoFace.fromMap)
          .toList(),
      errorMessage: map['errorMessage']?.toString(),
    );
  }

  Photo copyWith({
    String? id,
    String? albumId,
    String? localPath,
    Object? originalFileName = _photoUnset,
    Object? sourceId = _photoUnset,
    Object? localThumbnailPath = _photoUnset,
    Object? serverUrl = _photoUnset,
    Object? thumbUrl = _photoUnset,
    PhotoSyncStatus? syncStatus,
    DateTime? createdAt,
    int? likeCount,
    bool? isLikedByMe,
    List<PhotoComment>? comments,
    List<PhotoFace>? faces,
    Object? errorMessage = _photoUnset,
  }) {
    return Photo(
      id: id ?? this.id,
      albumId: albumId ?? this.albumId,
      localPath: localPath ?? this.localPath,
      originalFileName: identical(originalFileName, _photoUnset)
          ? this.originalFileName
          : originalFileName as String?,
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
      likeCount: likeCount ?? this.likeCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      comments: comments ?? this.comments,
      faces: faces ?? this.faces,
      errorMessage: identical(errorMessage, _photoUnset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
