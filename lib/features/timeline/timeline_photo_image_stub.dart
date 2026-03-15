import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Stub (web): web_ path → Image.memory(bytes); no File on web.
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
      errorBuilder: (_, __, ___) => _placeholder(fit),
    );
  }
  final effectiveUrl = thumbUrl ?? url;
  if (effectiveUrl != null && effectiveUrl.isNotEmpty) {
    return Image.network(
      effectiveUrl,
      fit: fit,
      errorBuilder: (_, __, ___) => _placeholder(fit),
    );
  }
  return _placeholder(fit);
}

Widget _placeholder(BoxFit fit) {
  return Container(
    color: Colors.white.withValues(alpha: 0.10),
    child: const Center(
      child: Icon(Icons.photo, color: Colors.white54, size: 40),
    ),
  );
}
