import 'package:flutter/foundation.dart';

import '../../models/smart_media_models.dart';

/// Web / unsupported: in-memory mirror of smart media tables (repopulated each [process]).
class SmartMediaStorage {
  SmartMediaStorage._();
  static final SmartMediaStorage instance = SmartMediaStorage._();

  final List<SmartMediaItem> _items = [];
  final List<SmartEvent> _events = [];

  Future<void> init() async {}

  Future<void> clear() async {
    _items.clear();
    _events.clear();
  }

  Future<void> replaceAll({
    required List<SmartMediaItem> items,
    required List<SmartEvent> events,
  }) async {
    _items
      ..clear()
      ..addAll(items);
    _events
      ..clear()
      ..addAll(events);
    debugPrint('[SmartMediaStorage] stub replaceAll items=${_items.length} events=${_events.length}');
  }

  Future<List<SmartMediaItem>> getAllItems() async => List.unmodifiable(_items);

  Future<List<SmartEvent>> getAllEvents() async => List.unmodifiable(_events);
}
