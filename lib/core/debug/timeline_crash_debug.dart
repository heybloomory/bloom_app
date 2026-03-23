import 'package:flutter/foundation.dart';

/// Greppable one-line markers for crash attribution (logcat / Xcode / `flutter run`).
/// Use these so logs clearly show whether failure was during scan, DB, or UI.
void logScanStart([String? context]) {
  debugPrint('SCAN START');
  if (context != null) debugPrint('  └─ $context');
}

void logScanEnd([String? context]) {
  debugPrint('SCAN END');
  if (context != null) debugPrint('  └─ $context');
}

void logDbRead(String phase) {
  debugPrint('DB READ');
  debugPrint('  └─ $phase');
}

void logUiBuild(String screen) {
  debugPrint('UI BUILD');
  debugPrint('  └─ $screen');
}

void logThumbnailCrash(Object error, StackTrace stack) {
  debugPrint('[CRASH] thumbnail load');
  debugPrint('  └─ $error');
  debugPrintStack(label: '[CRASH] thumbnail stack', stackTrace: stack);
}

void logTimelineLoadCrash(String where, Object error, StackTrace stack) {
  debugPrint('[CRASH] timeline load | $where');
  debugPrint('  └─ $error');
  debugPrintStack(label: '[CRASH] timeline stack', stackTrace: stack);
}
