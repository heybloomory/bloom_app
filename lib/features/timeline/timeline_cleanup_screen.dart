import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../layout/main_app_shell.dart';
import '../../models/smart_media_models.dart';
import '../../routes/app_routes.dart';
import '../../services/device_file_delete.dart';
import '../../services/local_photo_store.dart';
import '../../services/local_smart_media_processing_engine.dart';
import 'timeline_photo_image.dart';

/// Local cleanup: duplicates, blurry (placeholder), screenshots, large videos.
class TimelineCleanupScreen extends StatefulWidget {
  const TimelineCleanupScreen({super.key});

  @override
  State<TimelineCleanupScreen> createState() => _TimelineCleanupScreenState();
}

class _TimelineCleanupScreenState extends State<TimelineCleanupScreen> {
  SmartProcessingResult? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await LocalSmartMediaProcessingEngine.process();
    if (mounted) {
      setState(() {
        _result = r;
        _loading = false;
      });
    }
  }

  static const _largeVideoBytes = 50 * 1024 * 1024;

  List<SmartMediaItem> get _dup =>
      _result?.media.where((m) => m.isDuplicate).toList() ?? [];
  List<SmartMediaItem> get _shots =>
      _result?.media.where((m) => m.isScreenshot).toList() ?? [];
  List<SmartMediaItem> get _largeVideos => _result?.media
          .where((m) => m.isVideo && m.fileSizeBytes >= _largeVideoBytes)
          .toList() ??
      [];
  List<SmartMediaItem> get _blurry =>
      _result?.media.where((m) => m.isBlurry).toList() ?? [];

  Future<void> _removeFromBloomory(SmartMediaItem m) async {
    await LocalPhotoStore.init();
    LocalPhotoStore.deletePhoto(m.photoId);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from Bloomory (local only)')),
      );
    }
  }

  Future<void> _deleteFromDevice(SmartMediaItem m) async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deleting device files is not supported on web.'),
          ),
        );
      }
      return;
    }
    final ok = await deleteDeviceFileIfExists(m.localPath);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File not found or could not delete.')),
      );
      return;
    }
    await _removeFromBloomory(m);
  }

  Future<void> _keepBestInGroup(String? groupId) async {
    if (groupId == null || groupId.isEmpty) return;
    final group = _result?.media
            .where((m) => m.duplicateGroupId == groupId)
            .toList() ??
        [];
    final best = group.where((m) => m.isBest).toList();
    if (best.isEmpty) return;
    final keepId = best.first.photoId;
    await LocalPhotoStore.init();
    for (final m in group) {
      if (m.photoId != keepId) {
        LocalPhotoStore.deletePhoto(m.photoId);
      }
    }
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kept best photo; removed other duplicates locally')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainAppShell(
      currentRoute: AppRoutes.timeline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Expanded(
                  child: Text(
                    'Clean Up',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                ),
              ],
            ),
          ),
          if (_loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  _section(
                    title: 'Duplicates',
                    subtitle: 'Same-size items in an album (heuristic)',
                    items: _dup,
                    extra: _dup.isNotEmpty
                        ? TextButton(
                            onPressed: () async {
                              final ids = _dup
                                  .map((m) => m.duplicateGroupId)
                                  .whereType<String>()
                                  .toSet();
                              for (final id in ids) {
                                await _keepBestInGroup(id);
                              }
                            },
                            child: const Text('Keep Best (all groups)'),
                          )
                        : null,
                  ),
                  _section(
                    title: 'Blurry',
                    subtitle: _blurry.isEmpty
                        ? 'No blurry flags yet (engine placeholder)'
                        : '${_blurry.length} items',
                    items: _blurry,
                  ),
                  _section(
                    title: 'Screenshots',
                    subtitle: '${_shots.length} items',
                    items: _shots,
                  ),
                  _section(
                    title: 'Large videos',
                    subtitle: '≥ 50 MB',
                    items: _largeVideos,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required String subtitle,
    required List<SmartMediaItem> items,
    Widget? extra,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
            ),
            if (extra != null) ...[const SizedBox(height: 8), extra],
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(
                'Nothing here',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              )
            else ...[
              SizedBox(
                height: 62,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: items.take(10).map((m) {
                    return Container(
                      width: 62,
                      height: 62,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: buildTimelinePhotoImage(
                        url: null,
                        thumbUrl: null,
                        localPath: m.thumbPath ?? m.localPath,
                        localThumbnailPath: m.thumbPath,
                        fit: BoxFit.cover,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              ...items.take(20).map(_tile),
            ],
            if (items.length > 20)
              Text(
                '+ ${items.length - 20} more…',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tile(SmartMediaItem m) {
    final sizeLabel = m.fileSizeBytes > 0
        ? '${(m.fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '';
    return ListTile(
      dense: true,
      title: Text(
        m.albumTitle,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      subtitle: Text(
        '${m.localPath.split(RegExp(r'[/\\]')).last} $sizeLabel',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => _removeFromBloomory(m),
            child: const Text('Remove'),
          ),
          TextButton(
            onPressed: () => _deleteFromDevice(m),
            child: const Text('Delete device'),
          ),
        ],
      ),
    );
  }
}
