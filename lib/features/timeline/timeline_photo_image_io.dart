import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// IO: web_ path → Image.memory(bytes); else localPath → Image.file(File(localPath)).
Widget buildTimelinePhotoImage({
  required String? url,
  required String? thumbUrl,
  required String localPath,
  String? localThumbnailPath,
  BoxFit fit = BoxFit.cover,
  Uint8List? memoryBytes,
}) {
  try {
    return _buildTimelinePhotoImageBody(
      url: url,
      thumbUrl: thumbUrl,
      localPath: localPath,
      localThumbnailPath: localThumbnailPath,
      fit: fit,
      memoryBytes: memoryBytes,
    );
  } catch (e, st) {
    debugPrint('[CRASH] timeline thumbnail (io build)');
    debugPrint('  └─ $e');
    debugPrintStack(label: '[CRASH] timeline thumbnail stack', stackTrace: st);
    return _placeholder(fit);
  }
}

Widget _buildTimelinePhotoImageBody({
  required String? url,
  required String? thumbUrl,
  required String localPath,
  String? localThumbnailPath,
  BoxFit fit = BoxFit.cover,
  Uint8List? memoryBytes,
}) {
  if (memoryBytes != null && memoryBytes.isNotEmpty) {
    return Image.memory(
      memoryBytes,
      fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          child: child,
        );
      },
      errorBuilder: (_, __, ___) => _placeholder(fit),
    );
  }
  final effectiveUrl = thumbUrl ?? url;
  if (effectiveUrl != null && effectiveUrl.isNotEmpty) {
    return Image.network(
      effectiveUrl,
      fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          child: child,
        );
      },
      errorBuilder: (_, __, ___) => _fromPath(localPath, fit),
    );
  }
  final effectiveLocalPath =
      (localThumbnailPath != null && localThumbnailPath.isNotEmpty)
          ? localThumbnailPath
          : localPath;
  return _fromPath(effectiveLocalPath, fit);
}

Widget _fromPath(String path, BoxFit fit) {
  try {
    if (path.isEmpty) return _placeholder(fit);
    String p = path.trim();
    if (p.startsWith('asset:') ||
        p.startsWith('http://') ||
        p.startsWith('https://') ||
        p.startsWith('data:')) {
      return _placeholder(fit);
    }
    if (p.startsWith('file://')) p = p.substring(7);
    final file = File(p);
    if (!file.existsSync()) return _placeholder(fit);
    return Image.file(
      file,
      fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          child: child,
        );
      },
      errorBuilder: (_, __, ___) => _placeholder(fit),
    );
  } catch (e, st) {
    debugPrint('[CRASH] timeline thumbnail _fromPath');
    debugPrint('  └─ $e');
    debugPrintStack(label: '[CRASH] _fromPath stack', stackTrace: st);
    return _placeholder(fit);
  }
}

Widget _placeholder(BoxFit fit) {
  return Container(
    color: Colors.white.withValues(alpha: 0.10),
    child: const Center(
      child: Icon(Icons.photo, color: Colors.white54, size: 40),
    ),
  );
}
