import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/glass_container.dart';
import '../../layout/main_app_shell.dart';
import '../../models/album_model.dart';
import '../../models/photo_model.dart';
import '../../models/timeline_album_summary.dart';
import '../../routes/app_routes.dart';
import '../../services/album_media_picker_service.dart';
import '../../services/local_album_media_import_service.dart';
import '../../services/local_album_service.dart';
import '../../services/local_photo_store.dart';
import '../../services/photo_sync_service.dart';
import 'timeline_photo_image.dart';

class TimelineAlbumDetailScreen extends StatefulWidget {
  final String albumId;
  final String albumTitle;

  const TimelineAlbumDetailScreen({
    super.key,
    required this.albumId,
    required this.albumTitle,
  });

  @override
  State<TimelineAlbumDetailScreen> createState() =>
      _TimelineAlbumDetailScreenState();
}

class _TimelineAlbumDetailScreenState extends State<TimelineAlbumDetailScreen> {
  TimelineAlbum? _album;
  List<Photo> _photos = const <Photo>[];
  List<TimelineAlbumSummary> _childAlbums = const <TimelineAlbumSummary>[];
  bool _loading = true;
  bool _importing = false;
  bool _syncing = false;
  bool _disposed = false;

  void _safeSetState(VoidCallback fn) {
    if (_disposed || !mounted) {
      debugPrint('[UI] mounted check failed (AlbumDetail)');
      return;
    }
    setState(fn);
  }

  Future<void> _openPhotoViewer(int initialIndex) async {
    if (_photos.isEmpty) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => _TimelinePhotoViewer(
          albumTitle: _album?.title ?? widget.albumTitle,
          photos: _photos,
          initialIndex: initialIndex,
          onPhotoUpdated: (photo) async {
            LocalPhotoStore.updatePhoto(photo);
            await _reload();
          },
        ),
      ),
    );
    if (_disposed || !mounted) return;
    await _reload();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    if (_disposed || !mounted) return;
    _safeSetState(() {
      _loading = true;
    });
    try {
      await LocalPhotoStore.init();
      final album = LocalPhotoStore.getAlbum(widget.albumId);
      final photos = LocalPhotoStore.listPhotosInAlbum(widget.albumId);
      final childAlbums = LocalAlbumService.listChildAlbumSummaries(widget.albumId);
      if (_disposed || !mounted) return;
      _safeSetState(() {
        _album = album;
        _photos = photos;
        _childAlbums = childAlbums;
        _loading = false;
      });
    } catch (e) {
      if (_disposed || !mounted) return;
      _safeSetState(() {
        _album = null;
        _photos = const <Photo>[];
        _childAlbums = const <TimelineAlbumSummary>[];
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load album: $e')),
      );
    }
  }

  Future<void> _createSubAlbum() async {
    final album = _album;
    if (album == null) return;
    if (album.level >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only 2 album levels are supported.')),
      );
      return;
    }

    final titleCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Sub-Album'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: titleCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Sub-album name',
              hintText: 'Ceremony, Family, Highlights...',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter a sub-album name';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (created != true || _disposed || !mounted) return;

    try {
      final child = LocalAlbumService.createAlbum(
        titleCtrl.text.trim(),
        parentAlbumId: album.id,
      );
      await _reload();
      if (!mounted) return;
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => TimelineAlbumDetailScreen(
            albumId: child.id,
            albumTitle: child.title,
          ),
        ),
      ).then((_) => _reload());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create sub-album: $e')),
      );
    }
  }

  Future<void> _addPhotos() async {
    if (_importing) return;

    _safeSetState(() => _importing = true);
    try {
      final pickResult = await AlbumMediaPickerService.pickImages();
      if (pickResult.isEmpty) {
        if (_disposed || !mounted) return;
        final message = pickResult.noGalleryMediaLikely
            ? 'No images were selected. If the emulator has no gallery photos, import sample images into the emulator or choose from Files.'
            : 'No images selected.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return;
      }

      final result = await LocalAlbumMediaImportService.importPickedMedia(
        albumId: widget.albumId,
        items: pickResult.items,
      );
      await _reload();

      if (_disposed || !mounted) return;
      final baseMessage = result.duplicateCount > 0
          ? 'Added ${result.addedCount} photo${result.addedCount == 1 ? '' : 's'} • skipped ${result.duplicateCount} duplicate${result.duplicateCount == 1 ? '' : 's'}'
          : 'Added ${result.addedCount} photo${result.addedCount == 1 ? '' : 's'}';
      final message = pickResult.usedDocumentFallback
          ? '$baseMessage • picked through Files fallback'
          : baseMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (_disposed || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyImportError(e))),
      );
    } finally {
      if (!_disposed && mounted) {
        setState(() => _importing = false);
      }
    }
  }

  String _friendlyImportError(Object error) {
    final text = error.toString();
    if (text.toLowerCase().contains('permission')) {
      return 'Photo access was denied. Please allow media access and try again.';
    }
    return 'Could not add photos: $text';
  }

  Future<void> _syncToServer() async {
    if (_syncing) return;

    _safeSetState(() => _syncing = true);
    try {
      await PhotoSyncService.syncAlbum(widget.albumId);
      await _reload();
      if (_disposed || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Album synced to server')),
      );
    } catch (e) {
      await _reload();
      if (_disposed || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    } finally {
      if (!_disposed && mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final album = _album;
    final pendingCount = _photos
        .where((photo) =>
            photo.syncStatus == PhotoSyncStatus.localOnly ||
            photo.syncStatus == PhotoSyncStatus.uploading)
        .length;
    final failedCount = _photos
        .where((photo) => photo.syncStatus == PhotoSyncStatus.failed)
        .length;
    final syncedCount = _photos
        .where((photo) => photo.syncStatus == PhotoSyncStatus.synced)
        .length;

    return MainAppShell(
      currentRoute: AppRoutes.timeline,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                children: [
                  if (album == null && _photos.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'This album could not be loaded. You can still add photos.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  _AlbumHero(
                    albumTitle: album?.title ?? widget.albumTitle,
                    photoCount: _photos.length,
                    pendingCount: pendingCount,
                    syncedCount: syncedCount,
                    failedCount: failedCount,
                    onBack: () => Navigator.pop(context),
                    onAddPhotos: _addPhotos,
                    onSync: _syncToServer,
                    onCreateSubAlbum: album?.level == 1 ? _createSubAlbum : null,
                    importing: _importing,
                    syncing: _syncing,
                    latestUpdate: album?.updatedAt,
                    childAlbumCount: _childAlbums.length,
                    level: album?.level ?? 1,
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          if (_childAlbums.isNotEmpty || (album?.level ?? 1) == 1)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: _SubAlbumSection(
                                childAlbums: _childAlbums,
                                canCreateSubAlbum: (album?.level ?? 1) == 1,
                                onCreateSubAlbum: _createSubAlbum,
                                onOpenAlbum: (child) {
                                  Navigator.push<void>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TimelineAlbumDetailScreen(
                                        albumId: child.album.id,
                                        albumTitle: child.album.title,
                                      ),
                                    ),
                                  ).then((_) => _reload());
                                },
                              ),
                            ),
                          _photos.isEmpty
                              ? _AlbumEmptyState(onAddPhotos: _addPhotos)
                              : _PhotoGrid(
                                  photos: _photos,
                                  onPhotoTap: _openPhotoViewer,
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _AlbumHero extends StatelessWidget {
  final String albumTitle;
  final int photoCount;
  final int pendingCount;
  final int syncedCount;
  final int failedCount;
  final bool importing;
  final bool syncing;
  final DateTime? latestUpdate;
  final int childAlbumCount;
  final int level;
  final VoidCallback onBack;
  final VoidCallback onAddPhotos;
  final VoidCallback onSync;
  final VoidCallback? onCreateSubAlbum;

  const _AlbumHero({
    required this.albumTitle,
    required this.photoCount,
    required this.pendingCount,
    required this.syncedCount,
    required this.failedCount,
    required this.importing,
    required this.syncing,
    required this.latestUpdate,
    required this.childAlbumCount,
    required this.level,
    required this.onBack,
    required this.onAddPhotos,
    required this.onSync,
    required this.onCreateSubAlbum,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      radius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      albumTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      latestUpdate == null
                          ? level == 1
                              ? 'Root album'
                              : 'Level 2 album'
                          : 'Updated ${DateFormat('MMM d, y • h:mm a').format(latestUpdate!)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.70),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(
                icon: Icons.image_outlined,
                label: '$photoCount photo${photoCount == 1 ? '' : 's'}',
              ),
              _InfoChip(
                icon: Icons.cloud_done_outlined,
                label: '$syncedCount synced',
              ),
              _InfoChip(
                icon: Icons.cloud_upload_outlined,
                label: '$pendingCount waiting',
                highlight: pendingCount > 0,
              ),
              _InfoChip(
                icon: Icons.folder_copy_outlined,
                label: '$childAlbumCount sub-albums',
              ),
              if (failedCount > 0)
                _InfoChip(
                  icon: Icons.error_outline,
                  label: '$failedCount failed',
                  danger: true,
                ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: importing ? null : onAddPhotos,
                icon: importing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_photo_alternate_outlined),
                label: Text(importing ? 'Selecting...' : 'Add Photos'),
              ),
              if (onCreateSubAlbum != null)
                OutlinedButton.icon(
                  onPressed: onCreateSubAlbum,
                  icon: const Icon(Icons.create_new_folder_outlined),
                  label: const Text('Create Sub-Album'),
                ),
              OutlinedButton.icon(
                onPressed: (syncing || (pendingCount == 0 && failedCount == 0))
                    ? null
                    : onSync,
                icon: syncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(syncing ? 'Syncing...' : 'Sync to Server'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;
  final bool danger;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.highlight = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? const Color(0xFFFFB4A4)
        : highlight
            ? const Color(0xFFF2C66D)
            : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumEmptyState extends StatelessWidget {
  final VoidCallback onAddPhotos;

  const _AlbumEmptyState({
    required this.onAddPhotos,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      radius: 28,
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            child: const Icon(
              Icons.image_search_outlined,
              color: Colors.white70,
              size: 36,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No local images yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add images from this device. They appear immediately from local storage, and the saved path remains available for future visits.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAddPhotos,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Add Images'),
          ),
        ],
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final List<Photo> photos;
  final ValueChanged<int> onPhotoTap;

  const _PhotoGrid({
    required this.photos,
    required this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 640
            ? 2
            : constraints.maxWidth < 980
                ? 3
                : 4;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) => _PhotoTile(
            photo: photos[index],
            onTap: () => onPhotoTap(index),
          ),
        );
      },
    );
  }
}

class _SubAlbumSection extends StatelessWidget {
  final List<TimelineAlbumSummary> childAlbums;
  final bool canCreateSubAlbum;
  final VoidCallback onCreateSubAlbum;
  final void Function(TimelineAlbumSummary album) onOpenAlbum;

  const _SubAlbumSection({
    required this.childAlbums,
    required this.canCreateSubAlbum,
    required this.onCreateSubAlbum,
    required this.onOpenAlbum,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      radius: 26,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Sub-Albums',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (canCreateSubAlbum)
                OutlinedButton.icon(
                  onPressed: onCreateSubAlbum,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Sub-Album'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (childAlbums.isEmpty)
            Text(
              canCreateSubAlbum
                  ? 'Use one more level inside this album to organize the local image library professionally.'
                  : 'No sub-albums here yet.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                height: 1.4,
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 720;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: compact ? 1 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: compact ? 2.5 : 2.2,
                  ),
                  itemCount: childAlbums.length,
                  itemBuilder: (context, index) {
                    final summary = childAlbums[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => onOpenAlbum(summary),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                              child: const Icon(
                                Icons.folder_open_outlined,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    summary.album.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${summary.photoCount} image${summary.photoCount == 1 ? '' : 's'}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.70),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white54,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final Photo photo;
  final VoidCallback onTap;

  const _PhotoTile({
    required this.photo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: GlassContainer(
        radius: 22,
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              buildTimelinePhotoImage(
                url: photo.serverUrl,
                thumbUrl: photo.thumbUrl,
                localPath: photo.localPath,
                localThumbnailPath: photo.localThumbnailPath,
                fit: BoxFit.cover,
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Row(
                  children: [
                    Expanded(child: _SyncStatusPill(status: photo.syncStatus)),
                  ],
                ),
              ),
              if (photo.syncStatus == PhotoSyncStatus.failed &&
                  (photo.errorMessage ?? '').isNotEmpty)
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      photo.errorMessage!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncStatusPill extends StatelessWidget {
  final PhotoSyncStatus status;

  const _SyncStatusPill({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final IconData icon;
    late final Color color;

    switch (status) {
      case PhotoSyncStatus.localOnly:
        label = 'Local only';
        icon = Icons.phone_iphone_outlined;
        color = const Color(0xFFB9E3FF);
        break;
      case PhotoSyncStatus.uploading:
        label = 'Syncing';
        icon = Icons.sync;
        color = const Color(0xFFF2C66D);
        break;
      case PhotoSyncStatus.synced:
        label = 'Synced';
        icon = Icons.cloud_done_outlined;
        color = const Color(0xFFB5F2C4);
        break;
      case PhotoSyncStatus.failed:
        label = 'Failed';
        icon = Icons.error_outline;
        color = const Color(0xFFFFB4A4);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelinePhotoViewer extends StatefulWidget {
  final String albumTitle;
  final List<Photo> photos;
  final int initialIndex;
  final ValueChanged<Photo> onPhotoUpdated;

  const _TimelinePhotoViewer({
    required this.albumTitle,
    required this.photos,
    required this.initialIndex,
    required this.onPhotoUpdated,
  });

  @override
  State<_TimelinePhotoViewer> createState() => _TimelinePhotoViewerState();
}

class _TimelinePhotoViewerState extends State<_TimelinePhotoViewer> {
  late final PageController _controller;
  late int _currentIndex;
  late List<Photo> _photos;

  Photo get _currentPhoto => _photos[_currentIndex];

  @override
  void initState() {
    super.initState();
    _photos = List<Photo>.from(widget.photos);
    _currentIndex = widget.initialIndex.clamp(0, _photos.length - 1);
    _controller = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    final photo = _currentPhoto;
    final nextLiked = !photo.isLikedByMe;
    final nextCount = nextLiked
        ? photo.likeCount + 1
        : (photo.likeCount > 0 ? photo.likeCount - 1 : 0);
    final updated = photo.copyWith(
      isLikedByMe: nextLiked,
      likeCount: nextCount,
    );
    _photos[_currentIndex] = updated;
    widget.onPhotoUpdated(updated);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openComments() async {
    final updated = await showModalBottomSheet<Photo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhotoCommentsSheet(photo: _currentPhoto),
    );
    if (updated == null) return;
    _photos[_currentIndex] = updated;
    widget.onPhotoUpdated(updated);
    if (!mounted) return;
    setState(() {});
  }

  void _goToRelative(int delta) {
    final next = _currentIndex + delta;
    if (next < 0 || next >= _photos.length) return;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = _currentPhoto;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: _photos.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                final item = _photos[index];
                return Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: buildTimelinePhotoImage(
                      url: item.serverUrl,
                      thumbUrl: item.thumbUrl,
                      localPath: item.localPath,
                      localThumbnailPath: item.localThumbnailPath,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          widget.albumTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${_currentIndex + 1} / ${_photos.length}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            if (_currentIndex > 0)
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _ViewerNavButton(
                    icon: Icons.chevron_left,
                    onTap: () => _goToRelative(-1),
                  ),
                ),
              ),
            if (_currentIndex < _photos.length - 1)
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _ViewerNavButton(
                    icon: Icons.chevron_right,
                    onTap: () => _goToRelative(1),
                  ),
                ),
              ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: GlassContainer(
                radius: 24,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _toggleLike,
                            icon: Icon(
                              photo.isLikedByMe
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: photo.isLikedByMe
                                  ? const Color(0xFFFF7D8F)
                                  : Colors.white,
                            ),
                          ),
                          Text(
                            '${photo.likeCount}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: _openComments,
                            icon: const Icon(
                              Icons.mode_comment_outlined,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${photo.comments.length}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewerNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ViewerNavButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.42),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

class _PhotoCommentsSheet extends StatefulWidget {
  final Photo photo;

  const _PhotoCommentsSheet({
    required this.photo,
  });

  @override
  State<_PhotoCommentsSheet> createState() => _PhotoCommentsSheetState();
}

class _PhotoCommentsSheetState extends State<_PhotoCommentsSheet> {
  late final TextEditingController _controller;
  late List<PhotoComment> _comments;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _comments = List<PhotoComment>.from(widget.photo.comments);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    final fallbackName = (user?.email ?? 'You').split('@').first;
    final authorName = (user?.displayName ?? '').trim().isNotEmpty
        ? user!.displayName!.trim()
        : fallbackName;
    setState(() {
      _comments = <PhotoComment>[
        PhotoComment(
          authorName: authorName,
          text: text,
          createdAt: DateTime.now(),
        ),
        ..._comments,
      ];
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: GlassContainer(
            radius: 28,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Comments',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _comments.isEmpty
                      ? Center(
                          child: Text(
                            'No comments yet',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.70),
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: _comments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.10),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          comment.authorName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        DateFormat('MMM d, h:mm a')
                                            .format(comment.createdAt),
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.55),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    comment.text,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Send'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        widget.photo.copyWith(comments: _comments),
                      );
                    },
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
