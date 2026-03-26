import 'dart:io';

int smartMediaFileByteSize(String path) {
  try {
    final f = File(path);
    if (f.existsSync()) return f.lengthSync();
  } catch (_) {}
  return 0;
}
