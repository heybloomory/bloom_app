import 'dart:io';
import 'dart:math';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../models/photo_model.dart';
import 'file_reader.dart';

class FaceDetectionService {
  FaceDetectionService._();

  static final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableContours: false,
      enableLandmarks: false,
      enableClassification: false,
      minFaceSize: 0.08,
    ),
  );

  static Future<List<PhotoFace>> detectFacesForPath(String path) async {
    final normalizedPath =
        path.startsWith('file://') ? path.substring(7) : path;
    final bytes = await readFileBytes(normalizedPath);
    if (bytes == null || bytes.isEmpty) return const <PhotoFace>[];

    final decoded = img.decodeImage(bytes);
    if (decoded == null) return const <PhotoFace>[];

    final input = InputImage.fromFilePath(normalizedPath);
    final faces = await _detector.processImage(input);
    if (faces.isEmpty) return const <PhotoFace>[];

    final results = <PhotoFace>[];
    for (final face in faces) {
      final rect = face.boundingBox;
      final left = max(0, rect.left.floor());
      final top = max(0, rect.top.floor());
      final width = min(decoded.width - left, rect.width.ceil());
      final height = min(decoded.height - top, rect.height.ceil());
      if (width <= 0 || height <= 0) continue;

      final cropped = img.copyCrop(
        decoded,
        x: left,
        y: top,
        width: width,
        height: height,
      );
      final expandedCrop = _expandedSquareCrop(
        decoded: decoded,
        left: left,
        top: top,
        width: width,
        height: height,
      );
      final hash = _averageHash(cropped);
      final thumbnailPath = await _writeFaceThumbnail(
        sourcePath: normalizedPath,
        index: results.length,
        faceCrop: expandedCrop,
      );
      results.add(
        PhotoFace(
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
          hash: hash,
          clusterId: '',
          thumbnailPath: thumbnailPath,
        ),
      );
    }

    return results;
  }

  static String _averageHash(img.Image image) {
    final resized = img.copyResize(image, width: 8, height: 8);
    final luminance = <int>[];
    var total = 0;
    for (var y = 0; y < resized.height; y++) {
      for (var x = 0; x < resized.width; x++) {
        final pixel = resized.getPixel(x, y);
        final l = (((pixel.r.toInt()) * 299) +
                    ((pixel.g.toInt()) * 587) +
                    ((pixel.b.toInt()) * 114)) ~/
                1000;
        luminance.add(l);
        total += l;
      }
    }
    final avg = total / luminance.length;
    final buffer = StringBuffer();
    for (final value in luminance) {
      buffer.write(value >= avg ? '1' : '0');
    }
    return buffer.toString();
  }

  static img.Image _expandedSquareCrop({
    required img.Image decoded,
    required int left,
    required int top,
    required int width,
    required int height,
  }) {
    final centerX = left + (width / 2);
    final centerY = top + (height * 0.42);
    final side = max(width, height) * 1.08;
    var cropLeft = (centerX - (side / 2)).floor();
    var cropTop = (centerY - (side / 2)).floor();
    var cropSize = side.ceil();

    if (cropLeft < 0) {
      cropSize += cropLeft;
      cropLeft = 0;
    }
    if (cropTop < 0) {
      cropSize += cropTop;
      cropTop = 0;
    }
    if (cropLeft + cropSize > decoded.width) {
      cropSize = decoded.width - cropLeft;
    }
    if (cropTop + cropSize > decoded.height) {
      cropSize = min(cropSize, decoded.height - cropTop);
    }
    cropSize = max(1, cropSize);

    return img.copyCrop(
      decoded,
      x: cropLeft,
      y: cropTop,
      width: cropSize,
      height: cropSize,
    );
  }

  static Future<String> _writeFaceThumbnail({
    required String sourcePath,
    required int index,
    required img.Image faceCrop,
  }) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${baseDir.path}/bloomory/faces');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final safeSource = sourcePath
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')
        .replaceAll('__', '_');
    final resized = img.copyResizeCropSquare(faceCrop, size: 64);
    final bytes = img.encodeJpg(resized, quality: 82);
    final file = File(
      '${dir.path}/${safeSource}_${index + 1}_face.jpg',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
