import 'dart:io';
import 'dart:typed_data';

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
  if (localPath.startsWith('web_') &&
      memoryBytes != null &&
      memoryBytes.isNotEmpty) {
    return Image.memory(
      memoryBytes,
      fit: fit,
      errorBuilder: (_, __, ___) => _fromPath(localPath, fit),
    );
  }
  final effectiveUrl = thumbUrl ?? url;
  if (effectiveUrl != null && effectiveUrl.isNotEmpty) {
    return Image.network(
      effectiveUrl,
      fit: fit,
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
  if (path.isEmpty) return _placeholder(fit);
  String p = path.trim();
  if (p.startsWith('file://')) p = p.substring(7);
  final file = File(p);
  if (!file.existsSync()) return _placeholder(fit);
  return Image.file(
    file,
    fit: fit,
    errorBuilder: (_, __, ___) => _placeholder(fit),
  );
}

Widget _placeholder(BoxFit fit) {
  return Container(
    color: Colors.white.withValues(alpha: 0.10),
    child: const Center(
      child: Icon(Icons.photo, color: Colors.white54, size: 40),
    ),
  );
}
