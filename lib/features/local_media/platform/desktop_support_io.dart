
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class DesktopFileItem {
  final String path;
  final DateTime modified;
  DesktopFileItem({required this.path, required this.modified});
}

bool get isDesktopPlatform => Platform.isMacOS || Platform.isWindows || Platform.isLinux;
String get pathSeparator => Platform.pathSeparator;

Future<String?> pickDirectoryPath() => FilePicker.platform.getDirectoryPath(dialogTitle: 'Select folder');

Future<List<DesktopFileItem>> listImageFilesInDir(String dirPath) async {
  final dir = Directory(dirPath);
  if (!await dir.exists()) return [];
  final exts = {'.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp', '.heic'};
  final files = <DesktopFileItem>[];

  for (final entity in dir.listSync(followLinks: false)) {
    if (entity is File) {
      final lower = entity.path.toLowerCase();
      final dot = lower.lastIndexOf('.');
      if (dot != -1) {
        final ext = lower.substring(dot);
        if (exts.contains(ext)) {
          final stat = await entity.stat();
          files.add(DesktopFileItem(path: entity.path, modified: stat.modified));
        }
      }
    }
  }

  files.sort((a, b) => b.modified.compareTo(a.modified));
  return files;
}

Widget buildFileImageWidget(String path) => Image.file(File(path), fit: BoxFit.cover);

bool fileExists(String path) => File(path).existsSync();

String basename(String path) => path.split(Platform.pathSeparator).last;
