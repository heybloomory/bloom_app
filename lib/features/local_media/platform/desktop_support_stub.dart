
import 'package:flutter/material.dart';

class DesktopFileItem {
  final String path;
  final DateTime modified;
  DesktopFileItem({required this.path, required this.modified});
}

bool get isDesktopPlatform => false;
String get pathSeparator => '/';

Future<String?> pickDirectoryPath() async => null;

Future<List<DesktopFileItem>> listImageFilesInDir(String dirPath) async => [];

Widget buildFileImageWidget(String path) => const SizedBox.shrink();

bool fileExists(String path) => false;

String basename(String path) => path;
