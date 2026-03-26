import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/services/logger.dart';
import '../../models/photo_model.dart';
import '../local_photo_store.dart';
import '../photo_sync_core.dart';

/// Offline-first upload/delete queue with retries, backoff, and connectivity pause.
///
/// UI and features should enqueue work here; [PhotoSyncService.syncAlbum] drains this queue.
class SyncQueueService {
  SyncQueueService._();

  static final SyncQueueService instance = SyncQueueService._();

  static const _boxName = 'bloom_sync_queue_v2';
  static const _kJobs = 'jobs';

  static const maxRetries = 3;

  Box<dynamic>? _box;
  bool _opened = false;
  bool _pausedOffline = false;
  Future<void> _drainChain = Future.value();
  StreamSubscription<List<ConnectivityResult>>? _netSub;

  /// 0.0 – 1.0 for the current drain pass.
  final ValueNotifier<double> progress = ValueNotifier<double>(0);

  final ValueNotifier<bool> isDraining = ValueNotifier<bool>(false);

  Future<void> init() async {
    if (_opened) return;
    await LocalPhotoStore.init();
    _box = await Hive.openBox<dynamic>(_boxName);
    _opened = true;
    _pausedOffline = await _checkOffline();
    _netSub ??= Connectivity().onConnectivityChanged.listen(_onConnectivity);
    AppLogger.info('SyncQueue', 'opened box=$_boxName offline=$_pausedOffline');
  }

  Future<bool> _checkOffline() async {
    try {
      final r = await Connectivity().checkConnectivity();
      return r.contains(ConnectivityResult.none) || r.isEmpty;
    } catch (_) {
      return false;
    }
  }

  void _onConnectivity(List<ConnectivityResult> results) {
    final offline =
        results.contains(ConnectivityResult.none) || results.isEmpty;
    if (offline == _pausedOffline) return;
    _pausedOffline = offline;
    AppLogger.info('SyncQueue', 'connectivity offline=$offline');
    if (!offline) {
      unawaited(drain());
    }
  }

  List<Map<String, dynamic>> _readJobs() {
    final raw = _box?.get(_kJobs);
    if (raw is! List) return [];
    final out = <Map<String, dynamic>>[];
    for (final e in raw) {
      if (e is Map) {
        out.add(Map<String, dynamic>.from(
          e.map((k, v) => MapEntry(k.toString(), v)),
        ));
      }
    }
    return out;
  }

  Future<void> _writeJobs(List<Map<String, dynamic>> jobs) async {
    await _box?.put(_kJobs, jobs);
  }

  /// Enqueue all unsynced photos in this album and descendants (upload jobs).
  Future<int> enqueueAlbumSyncTree(String rootAlbumId) async {
    await init();
    final jobs = _readJobs();
    final existingKeys = <String, bool>{
      for (final j in jobs)
        if (j['mediaId'] != null)
          '${j['type']}_${j['mediaId']}': true,
    };
    var added = 0;

    void visitAlbum(String albumId) {
      final photos = LocalPhotoStore.listPhotosInAlbum(albumId);
      for (final p in photos) {
        if (p.syncStatus != PhotoSyncStatus.localOnly &&
            p.syncStatus != PhotoSyncStatus.failed) {
          continue;
        }
        final key = 'upload_${p.id}';
        if (existingKeys.containsKey(key)) continue;
        existingKeys[key] = true;
        jobs.add({
          'id': 'jq_${DateTime.now().microsecondsSinceEpoch}_$added',
          'albumId': albumId,
          'mediaId': p.id,
          'type': 'upload',
          'status': 'pending',
          'retryCount': 0,
          'createdAtMs': DateTime.now().millisecondsSinceEpoch,
          'nextAttemptAtMs': 0,
        });
        added++;
      }
      for (final child in LocalPhotoStore.listChildAlbums(albumId)) {
        visitAlbum(child.id);
      }
    }

    visitAlbum(rootAlbumId);
    await _writeJobs(jobs);
    AppLogger.info('SyncQueue', 'enqueue album=$rootAlbumId added=$added total=${jobs.length}');
    return added;
  }

  /// Enqueue a single media upload if needed.
  Future<void> enqueueUpload({
    required String albumId,
    required String mediaId,
  }) async {
    await init();
    final p = LocalPhotoStore.getPhoto(mediaId);
    if (p == null) return;
    if (p.syncStatus != PhotoSyncStatus.localOnly &&
        p.syncStatus != PhotoSyncStatus.failed) {
      return;
    }
    final jobs = _readJobs();
    if (jobs.any((j) =>
        j['mediaId'] == mediaId &&
        j['type'] == 'upload' &&
        (j['status'] == 'pending' || j['status'] == 'retry'))) {
      return;
    }
    jobs.add({
      'id': 'jq_${DateTime.now().microsecondsSinceEpoch}',
      'albumId': albumId,
      'mediaId': mediaId,
      'type': 'upload',
      'status': 'pending',
      'retryCount': 0,
      'createdAtMs': DateTime.now().millisecondsSinceEpoch,
      'nextAttemptAtMs': 0,
    });
    await _writeJobs(jobs);
  }

  /// Process queued jobs sequentially until empty or offline.
  Future<void> drain() async {
    await init();
    _drainChain = _drainChain.then((_) => _drainImpl());
    return _drainChain;
  }

  Future<void> _drainImpl() async {
    if (_pausedOffline) {
      AppLogger.warning('SyncQueue', 'drain skipped (offline)');
      return;
    }
    isDraining.value = true;
    try {
      var jobs = _readJobs();
      final initialPending = jobs
          .where((j) =>
              j['status'] == 'pending' || j['status'] == 'retry')
          .length;
      final denom = initialPending > 0 ? initialPending : 1;
      progress.value = 0;

      while (!_pausedOffline) {
        jobs = _readJobs();
        final now = DateTime.now().millisecondsSinceEpoch;
        final idx = jobs.indexWhere((j) {
          if (j['status'] != 'pending' && j['status'] != 'retry') {
            return false;
          }
          final next = (j['nextAttemptAtMs'] as num?)?.toInt() ?? 0;
          return now >= next;
        });
        if (idx < 0) break;

        final job = Map<String, dynamic>.from(jobs[idx]);
        final type = (job['type'] ?? 'upload').toString();
        try {
          if (type == 'upload') {
            await _runUpload(job);
          } else if (type == 'delete') {
            await _runDelete(job);
          }
          jobs.removeAt(idx);
          await _writeJobs(jobs);
        } catch (e, st) {
          AppLogger.error('SyncQueue', 'job failed', e, st);
          jobs = _readJobs();
          final curIdx = jobs.indexWhere((j) => j['id'] == job['id']);
          if (curIdx < 0) continue;
          final retries = (job['retryCount'] as num?)?.toInt() ?? 0;
          if (retries + 1 >= maxRetries) {
            job['status'] = 'failed';
            jobs[curIdx] = job;
          } else {
            job['retryCount'] = retries + 1;
            job['status'] = 'retry';
            final backoffMs = (1 << (retries + 1)) * 1000;
            job['nextAttemptAtMs'] = now + backoffMs;
            jobs[curIdx] = job;
          }
          await _writeJobs(jobs);
        }

        jobs = _readJobs();
        final left = jobs
            .where((j) =>
                j['status'] == 'pending' || j['status'] == 'retry')
            .length;
        progress.value = (1.0 - (left / denom)).clamp(0.0, 1.0);
      }
      if (!_pausedOffline) {
        progress.value = 1.0;
      }
    } finally {
      isDraining.value = false;
    }
  }

  Future<void> _runUpload(Map<String, dynamic> job) async {
    await LocalPhotoStore.init();
    final albumId = job['albumId']?.toString() ?? '';
    final mediaId = job['mediaId']?.toString() ?? '';
    final album = LocalPhotoStore.getAlbum(albumId);
    if (album == null) {
      throw StateError('Album missing $albumId');
    }
    final syncedAlbum = await PhotoSyncCore.ensureBackendAlbum(album);
    final backendId = syncedAlbum.backendAlbumId ?? '';
    if (backendId.isEmpty) throw StateError('No backend album id');
    final photo = LocalPhotoStore.getPhoto(mediaId);
    if (photo == null) throw StateError('Photo missing $mediaId');
    if (photo.syncStatus == PhotoSyncStatus.synced) {
      return;
    }
    await PhotoSyncCore.syncSinglePhoto(
      photo: photo,
      backendAlbumId: backendId,
    );
    final after = LocalPhotoStore.getPhoto(mediaId);
    if (after?.syncStatus == PhotoSyncStatus.failed) {
      throw StateError(after?.errorMessage ?? 'upload failed');
    }
  }

  Future<void> _runDelete(Map<String, dynamic> job) async {
    final mediaId = job['mediaId']?.toString() ?? '';
    AppLogger.info('SyncQueue', 'delete job (local) media=$mediaId');
    LocalPhotoStore.deletePhoto(mediaId);
  }

  /// Pending / retry jobs targeting [albumId] or its descendants.
  int pendingCountForAlbumTree(String rootAlbumId) {
    if (!_opened) return 0;
    final ids = <String>{};
    void visit(String id) {
      ids.add(id);
      for (final c in LocalPhotoStore.listChildAlbums(id)) {
        visit(c.id);
      }
    }

    visit(rootAlbumId);
    return _readJobs().where((j) {
      if (j['status'] != 'pending' && j['status'] != 'retry') return false;
      return ids.contains(j['albumId']?.toString());
    }).length;
  }

  bool hasFailedJobs() {
    if (!_opened) return false;
    return _readJobs().any((j) => j['status'] == 'failed');
  }

  Future<void> clearFailed() async {
    await init();
    final jobs = _readJobs().where((j) => j['status'] != 'failed').toList();
    await _writeJobs(jobs);
  }

  int pendingUploads() {
    if (!_opened) return 0;
    return _readJobs()
        .where((j) =>
            j['type'] == 'upload' &&
            (j['status'] == 'pending' || j['status'] == 'retry'))
        .length;
  }

  int failedUploads() {
    if (!_opened) return 0;
    return _readJobs()
        .where((j) => j['type'] == 'upload' && j['status'] == 'failed')
        .length;
  }

  int totalSynced() {
    try {
      final all = LocalPhotoStore.listAllPhotos();
      return all.where((p) => p.syncStatus == PhotoSyncStatus.synced).length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> retryFailedUploads() async {
    await init();
    final jobs = _readJobs();
    final now = DateTime.now().millisecondsSinceEpoch;
    var changed = false;
    for (final j in jobs) {
      if (j['type'] == 'upload' && j['status'] == 'failed') {
        j['status'] = 'retry';
        j['nextAttemptAtMs'] = now;
        j['retryCount'] = 0;
        changed = true;
      }
    }
    if (changed) {
      await _writeJobs(jobs);
    }
  }
}
