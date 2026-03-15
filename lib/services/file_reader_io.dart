import 'dart:io';
import 'dart:typed_data';

/// Reads file at [path] into bytes. Strips [file://] prefix if present.
/// Returns null if file does not exist or cannot be read.
Future<Uint8List?> readFileBytes(String path) async {
  String p = path.trim();
  if (p.startsWith('file://')) {
    p = p.substring(7);
  }
  final file = File(p);
  if (!await file.exists()) return null;
  try {
    return await file.readAsBytes();
  } catch (_) {
    return null;
  }
}
