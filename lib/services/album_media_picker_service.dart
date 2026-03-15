import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:image_picker/image_picker.dart';

import 'album_picked_media.dart';

class AlbumMediaPickerService {
  AlbumMediaPickerService._();

  static final ImagePicker _imagePicker = ImagePicker();

  static Future<AlbumMediaPickResult> pickImages() async {
    if (kIsWeb) {
      return _pickWithFilePicker();
    }

    if (_isAndroidOrIos) {
      final photoResult = await _pickWithNativePhotoPicker();
      if (photoResult.items.isNotEmpty) {
        return photoResult;
      }

      final fileFallback = await _pickWithFilePicker();
      if (fileFallback.items.isNotEmpty) {
        return AlbumMediaPickResult(
          items: fileFallback.items,
          usedDocumentFallback: true,
          noGalleryMediaLikely: true,
        );
      }

      return const AlbumMediaPickResult(
        items: <AlbumPickedMedia>[],
        noGalleryMediaLikely: true,
      );
    }

    return _pickWithFilePicker();
  }

  static bool get _isAndroidOrIos =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  static Future<AlbumMediaPickResult> _pickWithNativePhotoPicker() async {
    try {
      final files = await _imagePicker.pickMultiImage(
        imageQuality: 100,
        requestFullMetadata: false,
      );

      if (files.isEmpty) {
        return const AlbumMediaPickResult(items: <AlbumPickedMedia>[]);
      }

      final items = <AlbumPickedMedia>[];
      for (final file in files) {
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) continue;
        items.add(
          AlbumPickedMedia(
            name: file.name,
            sourceId: _sourceIdFromXFile(file, bytes),
            originalPath: file.path.isEmpty ? null : file.path,
            bytes: bytes,
            selectedAt: DateTime.now(),
          ),
        );
      }

      return AlbumMediaPickResult(items: items);
    } catch (_) {
      return const AlbumMediaPickResult(items: <AlbumPickedMedia>[]);
    }
  }

  static Future<AlbumMediaPickResult> _pickWithFilePicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return const AlbumMediaPickResult(items: <AlbumPickedMedia>[]);
    }

    final items = <AlbumPickedMedia>[];
    for (final file in result.files) {
      final bytes = await _readPlatformFileBytes(file);
      if (bytes == null || bytes.isEmpty) continue;
      items.add(
        AlbumPickedMedia(
          name: file.name,
          sourceId: _sourceIdFromPlatformFile(file, bytes),
          originalPath: (file.path ?? '').isEmpty ? null : file.path,
          bytes: bytes,
          selectedAt: DateTime.now(),
        ),
      );
    }

    return AlbumMediaPickResult(items: items);
  }

  static Future<Uint8List?> _readPlatformFileBytes(PlatformFile file) async {
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      return file.bytes!;
    }

    final stream = file.readStream;
    if (stream == null) {
      return null;
    }

    final chunks = <int>[];
    await for (final chunk in stream) {
      chunks.addAll(chunk);
    }
    return Uint8List.fromList(chunks);
  }

  static String _sourceIdFromXFile(XFile file, Uint8List bytes) {
    final path = file.path;
    if (path.isNotEmpty) {
      return 'mobile:${path.toLowerCase()}';
    }
    return 'mobile:${file.name}:${bytes.lengthInBytes}';
  }

  static String _sourceIdFromPlatformFile(PlatformFile file, Uint8List bytes) {
    final path = file.path;
    if (path != null && path.isNotEmpty) {
      return 'picker:${path.toLowerCase()}';
    }
    return 'picker:${file.name}:${bytes.lengthInBytes}:${file.size}';
  }
}
