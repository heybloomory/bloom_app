import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/photo_model.dart';

class ImportProcessingOptions {
  final bool removeDuplicates;
  final bool bestOnly;
  final bool detectScreenshots;
  final bool autoGroup;
  final bool autoTag;

  const ImportProcessingOptions({
    required this.removeDuplicates,
    required this.bestOnly,
    required this.detectScreenshots,
    required this.autoGroup,
    required this.autoTag,
  });
}

class ImportProcessedResult {
  final List<Photo> photos;
  final Map<String, List<Photo>> groups;
  final Map<String, List<String>> tagsByPhotoId;

  const ImportProcessedResult({
    required this.photos,
    required this.groups,
    required this.tagsByPhotoId,
  });
}

class ImportProcessingService {
  ImportProcessingService._();

  static Future<ImportProcessedResult> processPhotos(
    List<Photo> input, {
    required ImportProcessingOptions options,
    int batchSize = 50,
  }) async {
    final original = List<Photo>.from(input);
    var working = List<Photo>.from(input);

    if (options.detectScreenshots) {
      working = working.where((p) => !_looksLikeScreenshot(p)).toList();
    }

    if (options.removeDuplicates) {
      final seen = <String>{};
      final out = <Photo>[];
      for (var i = 0; i < working.length; i++) {
        final p = working[i];
        final key = _dedupeKey(p);
        if (seen.add(key)) out.add(p);
        if (i % batchSize == 0) {
          await Future<void>.delayed(Duration.zero);
        }
      }
      working = out;
    }

    if (options.bestOnly) {
      final byDay = <String, List<Photo>>{};
      for (final p in working) {
        byDay.putIfAbsent(_dayKey(p.createdAt), () => []).add(p);
      }
      final out = <Photo>[];
      for (final entry in byDay.entries) {
        final best = _pickBest(entry.value);
        out.add(best);
      }
      out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      working = out;
      await Future<void>.delayed(Duration.zero);
    }

    final groups = options.autoGroup ? _groupByDayClusters(working) : <String, List<Photo>>{};
    final tags = options.autoTag ? await _autoTags(working, batchSize: batchSize) : <String, List<String>>{};

    debugPrint(
      '[ImportProcessing] before=${original.length} after=${working.length} groups=${groups.length} tags=${tags.length}',
    );

    return ImportProcessedResult(
      photos: working,
      groups: groups,
      tagsByPhotoId: tags,
    );
  }

  static bool _looksLikeScreenshot(Photo p) {
    final name = (p.originalFileName ?? '').toLowerCase();
    final path = p.localPath.toLowerCase();
    return name.contains('screenshot') ||
        path.contains('screenshot') ||
        name.startsWith('screen') ||
        path.contains('/screenshots') ||
        path.contains('\\screenshots');
  }

  static String _dedupeKey(Photo p) {
    final source = (p.sourceId ?? '').trim();
    if (source.isNotEmpty) return 'src:$source';
    final path = p.localPath.trim();
    if (path.isNotEmpty) return 'path:${path.toLowerCase()}';
    final name = (p.originalFileName ?? '').trim();
    if (name.isNotEmpty) return 'name:${name.toLowerCase()}';
    final bytes = p.bytes;
    if (bytes != null && bytes.isNotEmpty) {
      return 'bytes:${bytes.length}:${_cheapBytesSig(bytes)}';
    }
    return 'id:${p.id}';
  }

  static int _cheapBytesSig(Uint8List bytes) {
    var a = 0;
    var b = 0;
    for (var i = 0; i < bytes.length; i += (bytes.length ~/ 16).clamp(1, bytes.length)) {
      a = (a + bytes[i]) & 0xFFFFFFFF;
      b = (b ^ (bytes[i] << (i % 8))) & 0xFFFFFFFF;
    }
    return a ^ b;
  }

  static String _dayKey(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static Photo _pickBest(List<Photo> group) {
    if (group.isEmpty) {
      throw StateError('Cannot pick best from empty group');
    }
    group.sort((a, b) {
      final aHasBytes = (a.bytes?.isNotEmpty ?? false) ? 1 : 0;
      final bHasBytes = (b.bytes?.isNotEmpty ?? false) ? 1 : 0;
      if (aHasBytes != bHasBytes) return bHasBytes.compareTo(aHasBytes);
      final aName = (a.originalFileName ?? '').length;
      final bName = (b.originalFileName ?? '').length;
      if (aName != bName) return bName.compareTo(aName);
      return b.createdAt.compareTo(a.createdAt);
    });
    return group.first;
  }

  static Map<String, List<Photo>> _groupByDayClusters(List<Photo> photos) {
    final sorted = List<Photo>.from(photos)..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final groups = <String, List<Photo>>{};
    if (sorted.isEmpty) return groups;

    List<Photo> current = [sorted.first];
    var clusterStart = sorted.first.createdAt;
    for (var i = 1; i < sorted.length; i++) {
      final p = sorted[i];
      final delta = p.createdAt.difference(current.last.createdAt);
      final sameDay = p.createdAt.year == clusterStart.year &&
          p.createdAt.month == clusterStart.month &&
          p.createdAt.day == clusterStart.day;
      final split = !sameDay || delta.inHours >= 6;
      if (split) {
        final key = _clusterKey(current.first.createdAt);
        groups[key] = List<Photo>.from(current);
        current = [p];
        clusterStart = p.createdAt;
      } else {
        current.add(p);
      }
    }
    final key = _clusterKey(current.first.createdAt);
    groups[key] = List<Photo>.from(current);
    return groups;
  }

  static String _clusterKey(DateTime dt) {
    final label = '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
    return '$label • ${dt.hour.toString().padLeft(2, '0')}:00';
  }

  static Future<Map<String, List<String>>> _autoTags(
    List<Photo> photos, {
    required int batchSize,
  }) async {
    final out = <String, List<String>>{};
    for (var i = 0; i < photos.length; i++) {
      final p = photos[i];
      final tags = <String>[];

      final name = (p.originalFileName ?? '').toLowerCase();
      if (name.contains('selfie')) tags.add('selfie');
      if (_looksLikeScreenshot(p)) tags.add('screenshot');

      final hour = p.createdAt.hour;
      if (hour >= 19 || hour <= 5) tags.add('night');
      if (hour >= 6 && hour <= 10) tags.add('morning');

      if (tags.isNotEmpty) out[p.id] = tags;

      if (i % batchSize == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }
    return out;
  }
}

