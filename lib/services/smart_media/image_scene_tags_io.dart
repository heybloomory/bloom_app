import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../models/smart_media_models.dart';

/// Lightweight pixel heuristics on a downscaled decode (local files only).
Future<List<SmartTag>> sampleSceneTagsFromPath(String? path) async {
  if (path == null || path.isEmpty) return const [];
  try {
    final file = File(path);
    if (!await file.exists()) return const [];
    final bytes = await file.readAsBytes();
    if (bytes.length < 24) return const [];
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return const [];
    final w = decoded.width;
    final h = decoded.height;
    if (w < 2 || h < 2) return const [];
    final small = img.copyResize(
      decoded,
      width: w > h ? 48 : null,
      height: h >= w ? 48 : null,
      interpolation: img.Interpolation.average,
    );
    var lumSum = 0.0;
    var n = 0;
    var blueLean = 0;
    final sw = small.width;
    final sh = small.height;
    for (var y = 0; y < sh; y += 2) {
      for (var x = 0; x < sw; x += 2) {
        final px = small.getPixel(x, y);
        final r = px.r.toInt();
        final g = px.g.toInt();
        final b = px.b.toInt();
        final lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
        lumSum += lum;
        n++;
        if (b > r + 18 && b > g + 12) blueLean++;
      }
    }
    if (n == 0) return const [];
    final avgLum = lumSum / n;
    final blueRatio = blueLean / n;
    final out = <SmartTag>[];
    if (avgLum < 0.22) {
      out.add(const SmartTag(name: 'night', confidence: 0.72));
    } else if (avgLum > 0.78) {
      out.add(const SmartTag(name: 'bright', confidence: 0.55));
    }
    if (blueRatio > 0.28) {
      out.add(const SmartTag(name: 'sky', confidence: 0.62));
      out.add(const SmartTag(name: 'beach', confidence: 0.48));
    }
    return out;
  } catch (e, st) {
    debugPrint('[image_scene_tags_io] $e $st');
    return const [];
  }
}
