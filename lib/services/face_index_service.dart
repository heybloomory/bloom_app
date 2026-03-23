import '../models/photo_model.dart';
import 'face_detection_service.dart';
import 'local_photo_store.dart';

class FaceIndexService {
  FaceIndexService._();

  static const int _matchThreshold = 10;

  static Future<FaceIndexSummary> refreshFaceIndex() async {
    await LocalPhotoStore.init();

    final photos = <Photo>[];
    for (final album in LocalPhotoStore.listAlbums()) {
      photos.addAll(LocalPhotoStore.listPhotosInAlbum(album.id));
    }

    final savedGroups = LocalPhotoStore.getFacePersonGroups();
    final photoMap = <String, List<PhotoFace>>{};
    final unmatched = <_DetectedFace>[];
    var processedPhotos = 0;
    var totalFaces = 0;

    for (final photo in photos) {
      final detectedFaces = await FaceDetectionService.detectFacesForPath(photo.localPath);
      processedPhotos += 1;
      totalFaces += detectedFaces.length;

      for (final face in detectedFaces) {
        final personId = _bestMatchingPersonId(
          hash: face.hash,
          groups: savedGroups,
        );
        if (personId == null) {
          unmatched.add(_DetectedFace(photo: photo, face: face));
          continue;
        }

        savedGroups.putIfAbsent(personId, () => <String>{}).add(face.hash);
        final list = photoMap.putIfAbsent(photo.id, () => <PhotoFace>[]);
        list.add(face.copyWith(clusterId: personId));
      }
    }

    final autoClusters = <_FaceCluster>[];
    for (final entry in unmatched) {
      final matched = autoClusters.cast<_FaceCluster?>().firstWhere(
            (cluster) =>
                _hammingDistance(cluster!.representativeHash, entry.face.hash) <=
                _matchThreshold,
            orElse: () => null,
          );
      if (matched == null) {
        autoClusters.add(
          _FaceCluster(
            representativeHash: entry.face.hash,
            items: <_DetectedFace>[entry],
          ),
        );
      } else {
        matched.items.add(entry);
      }
    }

    for (final cluster in autoClusters) {
      final personId = _bestMatchingPersonId(
            hash: cluster.representativeHash,
            groups: savedGroups,
          ) ??
          LocalPhotoStore.allocateFacePersonId();
      final hashes = savedGroups.putIfAbsent(personId, () => <String>{});
      for (final item in cluster.items) {
        hashes.add(item.face.hash);
        final list = photoMap.putIfAbsent(item.photo.id, () => <PhotoFace>[]);
        list.add(item.face.copyWith(clusterId: personId));
      }
    }

    LocalPhotoStore.saveFacePersonGroups(savedGroups);

    for (final photo in photos) {
      final nextFaces = photoMap[photo.id] ?? const <PhotoFace>[];
      LocalPhotoStore.updatePhoto(photo.copyWith(faces: nextFaces));
    }

    return FaceIndexSummary(
      processedPhotos: processedPhotos,
      totalFaces: totalFaces,
      totalPeople: savedGroups.length,
    );
  }

  static List<FacePersonGroup> listPeopleGroups() {
    if (!LocalPhotoStore.isReady) return const <FacePersonGroup>[];

    final names = LocalPhotoStore.getFacePersonNames();
    final groups = <String, FacePersonGroupBuilder>{};
    for (final album in LocalPhotoStore.listAlbums()) {
      final photos = LocalPhotoStore.listPhotosInAlbum(album.id);
      for (final photo in photos) {
        for (final face in photo.faces) {
          final clusterId = face.clusterId.trim();
          if (clusterId.isEmpty) continue;
          final builder = groups.putIfAbsent(
            clusterId,
            () => FacePersonGroupBuilder(
              clusterId: clusterId,
              displayName: names[clusterId],
            ),
          );
          builder.add(album.id, photo, face);
        }
      }
    }

    final results = groups.values.map((e) => e.build()).toList();
    results.sort((a, b) => b.photoCount.compareTo(a.photoCount));
    return results;
  }

  static List<Photo> photosForPerson(String clusterId) {
    if (!LocalPhotoStore.isReady) return const <Photo>[];
    final photos = <Photo>[];
    for (final album in LocalPhotoStore.listAlbums()) {
      for (final photo in LocalPhotoStore.listPhotosInAlbum(album.id)) {
        if (photo.faces.any((face) => face.clusterId == clusterId)) {
          photos.add(photo);
        }
      }
    }
    photos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return photos;
  }

  static Future<void> mergePeopleGroups({
    required String keepClusterId,
    required String mergeClusterId,
  }) async {
    final keepId = keepClusterId.trim();
    final mergeId = mergeClusterId.trim();
    if (keepId.isEmpty || mergeId.isEmpty || keepId == mergeId) return;

    await LocalPhotoStore.init();

    final groups = LocalPhotoStore.getFacePersonGroups();
    final keepHashes = groups.putIfAbsent(keepId, () => <String>{});
    keepHashes.addAll(groups.remove(mergeId) ?? const <String>{});
    LocalPhotoStore.saveFacePersonGroups(groups);
    final names = LocalPhotoStore.getFacePersonNames();
    final keepName = names[keepId];
    final mergeName = names.remove(mergeId);
    if ((keepName == null || keepName.trim().isEmpty) &&
        mergeName != null &&
        mergeName.trim().isNotEmpty) {
      names[keepId] = mergeName;
    }
    LocalPhotoStore.saveFacePersonNames(names);

    for (final album in LocalPhotoStore.listAlbums()) {
      for (final photo in LocalPhotoStore.listPhotosInAlbum(album.id)) {
        var changed = false;
        final nextFaces = photo.faces.map((face) {
          if (face.clusterId != mergeId) return face;
          changed = true;
          return face.copyWith(clusterId: keepId);
        }).toList();
        if (changed) {
          LocalPhotoStore.updatePhoto(photo.copyWith(faces: nextFaces));
        }
      }
    }
  }

  static List<FaceSplitCandidate> listSplitCandidates(String clusterId) {
    if (!LocalPhotoStore.isReady) return const <FaceSplitCandidate>[];

    final groups = <String, FaceSplitCandidateBuilder>{};
    for (final album in LocalPhotoStore.listAlbums()) {
      for (final photo in LocalPhotoStore.listPhotosInAlbum(album.id)) {
        for (final face in photo.faces) {
          if (face.clusterId != clusterId) continue;
          final builder = groups.putIfAbsent(
            face.hash,
            () => FaceSplitCandidateBuilder(faceHash: face.hash),
          );
          builder.add(face);
        }
      }
    }

    final results = groups.values.map((entry) => entry.build()).toList();
    results.sort((a, b) => b.imageCount.compareTo(a.imageCount));
    return results;
  }

  static Future<String?> separatePersonGroup({
    required String clusterId,
    required String faceHash,
  }) async {
    final currentClusterId = clusterId.trim();
    final targetHash = faceHash.trim();
    if (currentClusterId.isEmpty || targetHash.isEmpty) return null;

    await LocalPhotoStore.init();

    final groups = LocalPhotoStore.getFacePersonGroups();
    final hashes = groups[currentClusterId];
    if (hashes == null || hashes.length <= 1 || !hashes.contains(targetHash)) {
      return null;
    }

    hashes.remove(targetHash);
    final newClusterId = LocalPhotoStore.allocateFacePersonId();
    groups[currentClusterId] = hashes;
    groups[newClusterId] = <String>{targetHash};
    LocalPhotoStore.saveFacePersonGroups(groups);

    for (final album in LocalPhotoStore.listAlbums()) {
      for (final photo in LocalPhotoStore.listPhotosInAlbum(album.id)) {
        var changed = false;
        final nextFaces = photo.faces.map((face) {
          if (face.clusterId == currentClusterId && face.hash == targetHash) {
            changed = true;
            return face.copyWith(clusterId: newClusterId);
          }
          return face;
        }).toList();
        if (changed) {
          LocalPhotoStore.updatePhoto(photo.copyWith(faces: nextFaces));
        }
      }
    }

    return newClusterId;
  }

  static String displayNameForCluster(String clusterId) {
    final id = clusterId.trim();
    if (id.isEmpty) return 'Unknown';
    final names = LocalPhotoStore.getFacePersonNames();
    final custom = names[id]?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    return id.replaceFirst('person_', 'Person ');
  }

  static Future<void> renamePersonGroup({
    required String clusterId,
    required String name,
  }) async {
    final id = clusterId.trim();
    if (id.isEmpty) return;
    await LocalPhotoStore.init();
    final names = LocalPhotoStore.getFacePersonNames();
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      names.remove(id);
    } else {
      names[id] = trimmed;
    }
    LocalPhotoStore.saveFacePersonNames(names);
  }

  static String? _bestMatchingPersonId({
    required String hash,
    required Map<String, Set<String>> groups,
  }) {
    String? bestPersonId;
    var bestDistance = 1 << 30;

    groups.forEach((personId, memberHashes) {
      for (final memberHash in memberHashes) {
        final distance = _hammingDistance(memberHash, hash);
        if (distance <= _matchThreshold && distance < bestDistance) {
          bestDistance = distance;
          bestPersonId = personId;
        }
      }
    });

    return bestPersonId;
  }

  static int _hammingDistance(String a, String b) {
    final limit = a.length < b.length ? a.length : b.length;
    var distance = (a.length - b.length).abs();
    for (var i = 0; i < limit; i++) {
      if (a[i] != b[i]) distance += 1;
    }
    return distance;
  }
}

class FaceIndexSummary {
  final int processedPhotos;
  final int totalFaces;
  final int totalPeople;

  const FaceIndexSummary({
    required this.processedPhotos,
    required this.totalFaces,
    required this.totalPeople,
  });
}

class FacePersonGroup {
  final String clusterId;
  final String displayName;
  final int photoCount;
  final String sampleAlbumId;
  final Photo samplePhoto;
  final PhotoFace? sampleFace;

  const FacePersonGroup({
    required this.clusterId,
    required this.displayName,
    required this.photoCount,
    required this.sampleAlbumId,
    required this.samplePhoto,
    required this.sampleFace,
  });
}

class FaceSplitCandidate {
  final String faceHash;
  final String thumbnailPath;
  final int imageCount;

  const FaceSplitCandidate({
    required this.faceHash,
    required this.thumbnailPath,
    required this.imageCount,
  });
}

class FacePersonGroupBuilder {
  final String clusterId;
  String? displayName;
  final Map<String, Photo> _photos = {};
  String? _sampleAlbumId;
  Photo? _samplePhoto;
  PhotoFace? _sampleFace;

  FacePersonGroupBuilder({
    required this.clusterId,
    this.displayName,
  });

  void add(String albumId, Photo photo, PhotoFace face) {
    _photos[photo.id] = photo;
    _sampleAlbumId ??= albumId;
    _samplePhoto ??= photo;
    _sampleFace ??= face;
  }

  FacePersonGroup build() {
    return FacePersonGroup(
      clusterId: clusterId,
      displayName: displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : clusterId.replaceFirst('person_', 'Person '),
      photoCount: _photos.length,
      sampleAlbumId: _sampleAlbumId ?? '',
      samplePhoto: _samplePhoto ??
          Photo(
            id: '',
            albumId: '',
            localPath: '',
            createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          ),
      sampleFace: _sampleFace,
    );
  }
}

class FaceSplitCandidateBuilder {
  final String faceHash;
  final Set<String> _imageKeys = <String>{};
  String _thumbnailPath = '';

  FaceSplitCandidateBuilder({
    required this.faceHash,
  });

  void add(PhotoFace face) {
    _imageKeys.add('${face.thumbnailPath}|$faceHash');
    if (_thumbnailPath.isEmpty && face.thumbnailPath.trim().isNotEmpty) {
      _thumbnailPath = face.thumbnailPath;
    }
  }

  FaceSplitCandidate build() {
    return FaceSplitCandidate(
      faceHash: faceHash,
      thumbnailPath: _thumbnailPath,
      imageCount: _imageKeys.length,
    );
  }
}

class _DetectedFace {
  final Photo photo;
  final PhotoFace face;

  const _DetectedFace({
    required this.photo,
    required this.face,
  });
}

class _FaceCluster {
  final String representativeHash;
  final List<_DetectedFace> items;

  _FaceCluster({
    required this.representativeHash,
    required this.items,
  });
}
