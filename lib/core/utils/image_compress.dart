import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Client-side image compression before upload.
///
/// Goal: reduce size aggressively (quality ~60) so a 10–15MB photo becomes much smaller
/// before being sent to the backend/CDN.
class ImageCompress {
  /// Compress bytes to JPEG at [quality] (0-100).
  ///
  /// If compression fails, returns the original bytes.
  static Future<Uint8List> compressToJpeg(
    Uint8List input, {
    int quality = 60,
    int? minWidth,
    int? minHeight,
  }) async {
    try {
      // flutter_image_compress doesn't run on web; just upload original bytes.
      if (kIsWeb) return input;

      // For tiny images, skip to avoid quality loss.
      if (input.lengthInBytes < 200 * 1024) return input;

      final out = await FlutterImageCompress.compressWithList(
        input,
        quality: quality.clamp(0, 100),
        format: CompressFormat.jpeg,
        keepExif: true,
        // flutter_image_compress expects non-null ints.
        minWidth: minWidth ?? 0,
        minHeight: minHeight ?? 0,
      );

      // If output is somehow larger, keep original.
      if (out.length >= input.length) return input;
      return Uint8List.fromList(out);
    } catch (_) {
      return input;
    }
  }

  /// Generate a small thumbnail JPEG.
  ///
  /// Default aims for something like ~300x200 while preserving aspect ratio.
  static Future<Uint8List> thumbnailJpeg(
    Uint8List input, {
    int quality = 70,
    int width = 300,
    int height = 200,
  }) async {
    return compressToJpeg(
      input,
      quality: quality,
      minWidth: width,
      minHeight: height,
    );
  }

  /// Ensure the filename matches JPEG output.
  static String toJpegName(String original) {
    final lower = original.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return original;
    final dot = original.lastIndexOf('.');
    if (dot <= 0) return '$original.jpg';
    return '${original.substring(0, dot)}.jpg';
  }
}
