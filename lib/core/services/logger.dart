import 'package:flutter/foundation.dart';

/// Lightweight app logging (sync, chat, media).
class AppLogger {
  AppLogger._();

  static void info(String tag, String message) {
    debugPrint('[INFO][$tag] $message');
  }

  static void warning(String tag, String message) {
    debugPrint('[WARN][$tag] $message');
  }

  static void error(String tag, String message, [Object? e, StackTrace? st]) {
    debugPrint('[ERROR][$tag] $message ${e ?? ''}');
    if (st != null) {
      debugPrintStack(label: tag, stackTrace: st);
    }
  }
}
