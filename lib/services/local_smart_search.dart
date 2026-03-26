import '../models/smart_media_models.dart';

/// Local-only smart search with query parsing and weighted ranking.
class LocalSmartSearch {
  LocalSmartSearch._();

  static const _wTag = 3.2;
  static const _wEventTitle = 2.1;
  static const _wDateYear = 1.4;
  static const _wDateMonth = 0.9;
  static const _wAlbumPath = 0.55;

  static SmartSearchResult search({
    required String query,
    required List<SmartMediaItem> items,
    required List<SmartEvent> events,
  }) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return SmartSearchResult(events: events, photos: items);
    }

    final tokens = q
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
    final yearMatch = RegExp(r'(20\d{2})').firstMatch(q)?.group(1);
    final monthHints = <String, int>{
      'jan': 1,
      'january': 1,
      'feb': 2,
      'february': 2,
      'mar': 3,
      'march': 3,
      'apr': 4,
      'april': 4,
      'may': 5,
      'jun': 6,
      'june': 6,
      'jul': 7,
      'july': 7,
      'aug': 8,
      'august': 8,
      'sep': 9,
      'sept': 9,
      'september': 9,
      'oct': 10,
      'october': 10,
      'nov': 11,
      'november': 11,
      'dec': 12,
      'december': 12,
    };
    int? monthFilter;
    monthHints.forEach((key, m) {
      if (q.contains(key)) monthFilter = m;
    });

    // Event-title keywords: drop bare years and month names.
    final eventKeywords = tokens.where((t) {
      if (t.length < 3) return false;
      if (RegExp(r'^20\d{2}$').hasMatch(t)) return false;
      if (monthHints.containsKey(t)) return false;
      return true;
    }).toList();

    double scoreEvent(SmartEvent e) {
      var s = 0.0;
      final title = e.title.toLowerCase();
      if (title.contains(q)) s += _wEventTitle * 1.2;
      for (final kw in eventKeywords) {
        if (title.contains(kw)) s += _wEventTitle;
      }
      if (yearMatch != null && e.start.year.toString() == yearMatch) {
        s += _wDateYear;
      }
      if (monthFilter != null &&
          e.start.month == monthFilter &&
          (yearMatch == null || e.start.year.toString() == yearMatch)) {
        s += _wDateMonth;
      }
      return s;
    }

    double scoreItem(SmartMediaItem m) {
      var s = 0.0;
      for (final kw in tokens) {
        for (final t in m.tagScores) {
          final name = t.name.toLowerCase();
          if (name.contains(kw) || kw.contains(name)) {
            s += _wTag * t.confidence;
          }
        }
      }
      for (final kw in tokens) {
        if (m.albumTitle.toLowerCase().contains(kw)) {
          s += _wAlbumPath * 0.9;
        }
        if (m.localPath.toLowerCase().contains(kw)) {
          s += _wAlbumPath * 0.5;
        }
      }
      if (yearMatch != null && m.takenAt.year.toString() == yearMatch) {
        s += _wDateYear;
      }
      if (monthFilter != null && m.takenAt.month == monthFilter) {
        if (yearMatch == null || m.takenAt.year.toString() == yearMatch) {
          s += _wDateMonth;
        }
      }
      for (final e in events) {
        if (e.id != m.eventId) continue;
        final es = scoreEvent(e);
        if (es > 0) s += es * 0.85;
      }
      return s;
    }

    final hitEvents = events.where((e) => scoreEvent(e) > 0.5).toList()
      ..sort((a, b) => scoreEvent(b).compareTo(scoreEvent(a)));

    final ranked = <SmartSearchPhotoHit>[];
    for (final m in items) {
      final sc = scoreItem(m);
      if (sc > 0.25) ranked.add(SmartSearchPhotoHit(item: m, score: sc));
    }
    ranked.sort((a, b) => b.score.compareTo(a.score));

    final hitPhotos = ranked.map((h) => h.item).toList(growable: false);

    return SmartSearchResult(
      events: hitEvents,
      photos: hitPhotos,
      rankedPhotos: ranked,
    );
  }
}
