import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/services/offer_service.dart';
import '../../core/services/user_api_service.dart';
import '../../layout/main_app_shell.dart';
import '../../models/photo_model.dart';
import '../../models/smart_media_models.dart';
import '../../routes/app_routes.dart';
import '../../services/local_album_service.dart';
import '../../services/local_photo_store.dart';
import '../../services/local_smart_media_processing_engine.dart';
import '../../services/local_smart_search.dart';
import '../../services/sync/sync_queue_service.dart';
import '../../services/personalization_service.dart';
import '../../services/api_service.dart';
import '../import/import_studio_screen.dart';
import 'timeline_smart_viewer.dart';
import 'timeline_photo_image.dart';
import '../../services/analytics_service.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  SmartProcessingResult _result = const SmartProcessingResult(
    media: [],
    events: [],
    duplicateGroups: {},
  );
  bool _loading = false;
  bool _disposed = false;
  Set<String> _syncedAlbumIds = <String>{};
  Map<String, PhotoSyncStatus> _photoSync = {};
  Map<String, Uint8List> _photoBytes = {};
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _showIntro = false;
  bool _introPlayed = false;
  bool _offerShownThisSession = false;
  OfferMessage? _offer;
  PersonalizedBanner? _personalizedBanner;
  List<PersonalizedRecommendation> _recommendations =
      <PersonalizedRecommendation>[];
  DateTime? _importHeaderUntil;
  static const _lastImportPhotoIdsKey = 'last_import_photo_ids_v1';
  static const _lastImportAlbumIdsKey = 'last_import_album_ids_v1';
  static const _lastImportAtKey = 'last_import_at_v1';

  Future<void> _maybeShowFirstTimeHint() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    const key = 'timeline_hint_seen_v1';
    final seen = prefs.getBool(key) ?? false;
    if (seen) return;
    await prefs.setBool(key, true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✨ Your memories are organized automatically'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _searchCtrl.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (_disposed || !mounted) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      _safeSetState(() => _searchQuery = _searchCtrl.text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTimelineFlow());
  }

  Future<void> _startTimelineFlow() async {
    try {
      final completed = await UserApiService.isProfileCompleted();
      if (!mounted) return;
      if (!completed) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.profileCompletion,
          (_) => false,
        );
        return;
      }
    } catch (_) {
      // If check fails, allow timeline; profile screen can still be opened manually.
    }
    await _loadTimeline();
    await _loadOffer();
    await _loadPersonalizedContent();
    unawaited(_trackTimelineView());
  }

  Future<void> _loadOffer() async {
    if (_offerShownThisSession) return;
    final offer = await OfferService.getTimelineOffer();
    if (!mounted) return;
    setState(() {
      _offer = offer;
      _offerShownThisSession = offer != null;
    });
    if (offer != null) {
      await AnalyticsService.logEvent('banner_viewed', params: {
        'title': offer.title,
      });
    }
  }

  Future<void> _loadTimeline() async {
    if (_disposed) return;
    _safeSetState(() => _loading = true);
    try {
      await LocalPhotoStore.init();
      await SyncQueueService.instance.init();
      final r = await LocalSmartMediaProcessingEngine.process();
      PaintingBinding.instance.imageCache.maximumSize = 120;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 96 << 20;
      final synced = LocalPhotoStore
          .listAlbums()
          .where((a) => a.isSynced)
          .map((a) => a.id)
          .toSet();
      final syncMap = <String, PhotoSyncStatus>{};
      final byteMap = <String, Uint8List>{};
      for (final p in LocalPhotoStore.listAllPhotos()) {
        syncMap[p.id] = p.syncStatus;
        if (p.bytes != null && p.bytes!.isNotEmpty) {
          byteMap[p.id] = p.bytes!;
        }
      }
      if (_disposed) return;
      _safeSetState(() {
        _result = r;
        _syncedAlbumIds = synced;
        _photoSync = syncMap;
        _photoBytes = byteMap;
        if (!_introPlayed) {
          _showIntro = true;
          _introPlayed = true;
        }
      });
      unawaited(_maybeShowFirstTimeHint());
    } catch (e) {
      if (_disposed || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Timeline load failed: $e')),
      );
    } finally {
      if (!_disposed && mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadPersonalizedContent() async {
    final content = await PersonalizationService.fetchPersonalizedContent();
    if (!mounted) return;
    _safeSetState(() {
      _personalizedBanner =
          content.banners.isNotEmpty ? content.banners.first : null;
      _recommendations = content.recommendations;
    });
    if (_personalizedBanner != null) {
      await AnalyticsService.logEvent('banner_viewed', params: {
        'title': _personalizedBanner!.title,
        'source': 'personalized',
      });
    }
  }

  Future<void> _trackTimelineView() async {
    try {
      await ApiService.post('/api/users/track-engagement', {
        'action': 'timeline_view',
      });
    } catch (_) {}
  }

  ({List<SmartEvent> events, List<SmartMediaItem> items}) _visibleData() {
    var items = List<SmartMediaItem>.from(_result.media);
    var events = List<SmartEvent>.from(_result.events);

    final searched = LocalSmartSearch.search(
      query: _searchQuery,
      items: items,
      events: events,
    );
    items = searched.photos;
    events = searched.events;

    final eventIds = items.map((m) => m.eventId).whereType<String>().toSet();
    events = events.where((e) => eventIds.contains(e.id)).toList()
      ..sort((a, b) => b.start.compareTo(a.start));

    return (events: events, items: items);
  }

  Future<void> _toggleFavorite(SmartMediaItem m) async {
    await LocalPhotoStore.init();
    final p = LocalPhotoStore.getPhoto(m.photoId);
    if (p == null) return;
    LocalPhotoStore.updatePhoto(p.copyWith(isLikedByMe: !p.isLikedByMe));
    await _loadTimeline();
  }

  void _openItem(SmartMediaItem m, List<SmartMediaItem> contextItems) {
    final photos = <Photo>[];
    for (final x in contextItems) {
      final p = LocalPhotoStore.getPhoto(x.photoId);
      if (p != null) photos.add(p);
    }
    if (photos.isEmpty) return;
    final idx = photos.indexWhere((p) => p.id == m.photoId);
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TimelineSmartViewer(
          photos: photos,
          initialIndex: idx >= 0 ? idx : 0,
        ),
      ),
    );
  }

  Future<void> _openImportStudio() async {
    final imported = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => const ImportStudioScreen(),
      ),
    );
    await _loadTimeline();
    if (imported == true && mounted) {
      _safeSetState(() {
        _importHeaderUntil =
            DateTime.now().add(const Duration(milliseconds: 2300));
      });
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 2300)).then((_) {
          if (!mounted) return;
          if (_importHeaderUntil == null) return;
          if (DateTime.now().isBefore(_importHeaderUntil!)) return;
          _safeSetState(() => _importHeaderUntil = null);
        }),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✨ Your memories are ready'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: _undoLastImport,
          ),
        ),
      );
    }
  }

  Future<void> _undoLastImport() async {
    final prefs = await SharedPreferences.getInstance();
    final photoIds =
        prefs.getStringList(_lastImportPhotoIdsKey) ?? const <String>[];
    final albumIds =
        prefs.getStringList(_lastImportAlbumIdsKey) ?? const <String>[];
    final at = prefs.getInt(_lastImportAtKey) ?? 0;
    if (at == 0 || (photoIds.isEmpty && albumIds.isEmpty)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to undo')),
      );
      return;
    }

    await LocalPhotoStore.init();
    for (final id in photoIds) {
      LocalPhotoStore.deletePhoto(id);
    }
    for (final id in albumIds.reversed) {
      final photos = LocalPhotoStore.listPhotosInAlbum(id);
      if (photos.isEmpty) {
        LocalPhotoStore.deleteAlbum(id);
      }
    }
    await prefs.remove(_lastImportPhotoIdsKey);
    await prefs.remove(_lastImportAlbumIdsKey);
    await prefs.remove(_lastImportAtKey);
    await _loadTimeline();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import undone')),
    );
  }



  @override
  Widget build(BuildContext context) {
    final data = _visibleData();
    final mediaCount = _result.media.length;
    // Keep computed counts for hero and empty-state.
    final user = FirebaseAuth.instance.currentUser;
    final nameRaw = (user?.displayName ?? '').trim();
    final fallback = (user?.email ?? 'there').split('@').first;
    final displayName = nameRaw.isNotEmpty ? nameRaw : fallback;
    final now = DateTime.now();
    final weekFrom = now.subtract(const Duration(days: 7));
    final momentsThisWeek =
        data.items.where((m) => m.takenAt.isAfter(weekFrom)).length;
    final lastTakenAt = data.items.isEmpty
        ? null
        : data.items
            .map((m) => m.takenAt)
            .reduce((a, b) => a.isAfter(b) ? a : b);
    final lastAddedDaysAgo = lastTakenAt == null
        ? null
        : now.difference(lastTakenAt).inDays.clamp(0, 3650);
    final heroLine = momentsThisWeek > 0
        ? 'You captured $momentsThisWeek moment${momentsThisWeek == 1 ? '' : 's'} this week'
        : (lastAddedDaysAgo == null
            ? null
            : (lastAddedDaysAgo == 0
                ? 'Last memory added today'
                : 'Last memory added $lastAddedDaysAgo day${lastAddedDaysAgo == 1 ? '' : 's'} ago'));

    return MainAppShell(
      currentRoute: AppRoutes.timeline,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        offset: _showIntro ? Offset.zero : const Offset(0, 0.04),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 240),
          opacity: _showIntro ? 1 : 0,
          child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
            child: _TimelineHero(
              name: displayName,
              heroLine: heroLine,
              mediaCount: mediaCount,
              albumCount: LocalAlbumService.listRootAlbumSummaries().length,
              onInvite: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invite Friends')),
                );
              },
            ),
          ),
          if (_offer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Dismissible(
                key: ValueKey<String>('offer_${_offer!.title}_${_offer!.body}'),
                direction: DismissDirection.up,
                onDismissed: (_) => _safeSetState(() => _offer = null),
                child: GlassContainer(
                  radius: 16,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            unawaited(AnalyticsService.logEvent('banner_clicked', params: {
                              'title': _offer!.title,
                            }));
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _offer!.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _offer!.body,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Dismiss',
                        onPressed: () => _safeSetState(() => _offer = null),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_offer == null && _personalizedBanner != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: GlassContainer(
                radius: 16,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          unawaited(AnalyticsService.logEvent('banner_clicked', params: {
                            'title': _personalizedBanner!.title,
                            'source': 'personalized',
                          }));
                          if (_personalizedBanner!.target == 'profile') {
                            Navigator.pushNamed(context, AppRoutes.profileCompletion);
                          } else {
                            Navigator.pushNamed(context, AppRoutes.dashboard);
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _personalizedBanner!.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _personalizedBanner!.subtitle,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Dismiss',
                      onPressed: () => _safeSetState(() => _personalizedBanner = null),
                      icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          if (_loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (data.items.isEmpty)
            Expanded(
              child: Center(
                child: GlassContainer(
                  radius: 28,
                  padding: const EdgeInsets.all(28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.photo_camera_outlined,
                          color: Colors.white70,
                          size: 46,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Turn your photos into memories ✨',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Import your photos and we’ll organize everything for you',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: AppPrimaryButton(
                            onPressed: _openImportStudio,
                            icon: Icons.add_photo_alternate_outlined,
                            text: 'Add Media',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                    child: (_importHeaderUntil != null &&
                            DateTime.now().isBefore(_importHeaderUntil!))
                        ? const Padding(
                            padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                            child: GlassContainer(
                              key: ValueKey('import_ready_header'),
                              radius: 18,
                              padding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '✨ Your memories are ready',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox(
                            key: ValueKey('import_ready_header_empty'),
                            height: 0,
                          ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: GestureDetector(
                        key: const ValueKey('grid_clean'),
                        child: CustomScrollView(
                        key: const PageStorageKey<String>('timeline_smart_scroll'),
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          if (_recommendations.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                                child: GlassContainer(
                                  radius: 18,
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Recommended for you',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ..._recommendations.take(2).map((r) => Padding(
                                            padding: const EdgeInsets.only(bottom: 6),
                                            child: Text(
                                              '• ${r.title}: ${r.description}',
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.82),
                                                fontSize: 12,
                                              ),
                                            ),
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ..._monthSections(data.items),
                        ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
        ),
      ),
    );
  }

  List<Widget> _monthSections(List<SmartMediaItem> items) {
      final byMonth = <String, List<SmartMediaItem>>{};
    for (final m in items) {
      final key = DateFormat('MMMM y').format(m.takenAt);
      byMonth.putIfAbsent(key, () => []).add(m);
    }
    final keys = byMonth.keys.toList();
    keys.sort((a, b) {
      final aDt = DateFormat('MMMM y').parse(a);
      final bDt = DateFormat('MMMM y').parse(b);
      return bDt.compareTo(aDt);
    });

    final out = <Widget>[];
    for (final key in keys) {
      final list = byMonth[key]!..sort((a, b) => b.takenAt.compareTo(a.takenAt));
      out.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Text(
              key,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      );
      out.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final m = list[i];
                final tile = _MediaTile(
                  item: m,
                  isSynced: _syncedAlbumIds.contains(m.albumId),
                  photoSync: _photoSync[m.photoId],
                  memoryBytes: _photoBytes[m.photoId],
                  onTap: () => _openItem(m, list),
                  onLongPress: () => _toggleFavorite(m),
                );
                if (i >= 20) return tile;
                final duration =
                    Duration(milliseconds: 200 + (i.clamp(0, 19) * 16));
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  builder: (context, t, child) => Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, (1 - t) * 10),
                      child: child,
                    ),
                  ),
                  child: tile,
                );
              },
              childCount: list.length,
            ),
          ),
        ),
      );
    }
    return out;
  }
}

class _TimelineHero extends StatelessWidget {
  final String name;
  final String? heroLine;
  final int mediaCount;
  final int albumCount;
  final VoidCallback onInvite;

  const _TimelineHero({
    required this.name,
    required this.heroLine,
    required this.mediaCount,
    required this.albumCount,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, $name 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (heroLine ?? 'Relive your best memories today').trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Center(
                child: Text(
                  name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassContainer(
          radius: 24,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '✨ Relive your best moments',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$mediaCount memories • $albumCount albums',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AppSecondaryButton(
                    onPressed: onInvite,
                    text: 'Invite Friends',
                    icon: Icons.ios_share_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Invite friends to relive this memory ❤️',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$mediaCount memories organized',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: AppSecondaryButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Explore Memories')),
                    );
                  },
                  icon: Icons.auto_awesome_outlined,
                  text: 'Explore Memories',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MediaTile extends StatelessWidget {
  final SmartMediaItem item;
  final bool isSynced;
  final PhotoSyncStatus? photoSync;
  final Uint8List? memoryBytes;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _MediaTile({
    required this.item,
    required this.isSynced,
    this.photoSync,
    this.memoryBytes,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final path = item.thumbPath ?? item.localPath;
    final aiTag = _aiPreviewTag(item);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: Hero(
        tag: 'smart-photo-${item.photoId}',
        child: _PressScale(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          onLongPress: () async {
            await HapticFeedback.lightImpact();
            onLongPress();
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  buildTimelinePhotoImage(
                    url: null,
                    thumbUrl: null,
                    localPath: path,
                    localThumbnailPath: item.thumbPath,
                    memoryBytes: memoryBytes,
                    fit: BoxFit.cover,
                  ),
                  if (item.isVideo)
                    const Align(
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  if (item.isDuplicate)
                    Positioned(
                      left: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Dup',
                          style: TextStyle(color: Colors.white, fontSize: 9),
                        ),
                      ),
                    ),
                  if (item.favorite)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Icon(
                        Icons.favorite,
                        color: Colors.pinkAccent.shade100,
                        size: 18,
                      ),
                    ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: _SyncGlyph(
                      albumSynced: isSynced,
                      photoSync: photoSync,
                    ),
                  ),
                  if ((aiTag ?? '').isNotEmpty)
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          aiTag!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _aiPreviewTag(SmartMediaItem m) {
    final preferred = <String>['beach', 'night', 'trip'];
    for (final p in preferred) {
      final hit = m.tagNames.where((t) => t.toLowerCase() == p).toList();
      if (hit.isNotEmpty) {
        final v = hit.first;
        return v.substring(0, 1).toUpperCase() + v.substring(1);
      }
    }
    if (m.tagNames.isEmpty) return null;
    final v = m.tagNames.first;
    if (v.isEmpty) return null;
    return v.substring(0, 1).toUpperCase() + v.substring(1);
  }
}

class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Future<void> Function()? onLongPress;
  final BorderRadius borderRadius;

  const _PressScale({
    required this.child,
    required this.onTap,
    required this.borderRadius,
    this.onLongPress,
  });

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 110),
      scale: _down ? 0.985 : 1,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress == null ? null : () => widget.onLongPress!(),
        onHighlightChanged: (v) => setState(() => _down = v),
        borderRadius: widget.borderRadius,
        child: widget.child,
      ),
    );
  }
}

class _SyncGlyph extends StatelessWidget {
  final bool albumSynced;
  final PhotoSyncStatus? photoSync;

  const _SyncGlyph({
    required this.albumSynced,
    this.photoSync,
  });

  @override
  Widget build(BuildContext context) {
    final s = photoSync;
    String emoji = '📱';
    if (s == PhotoSyncStatus.synced || (albumSynced && s == null)) {
      emoji = '☁️';
    } else if (s == PhotoSyncStatus.uploading) {
      emoji = '🔄';
    } else if (s == PhotoSyncStatus.failed) {
      emoji = '⚠️';
    }
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        shape: BoxShape.circle,
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 12)),
    );
  }
}

// NOTE: Legacy timeline "tool" widgets removed in UX refactor.
