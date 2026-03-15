import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/glass_container.dart';
import '../../layout/main_app_shell.dart';
import '../../models/album_model.dart';
import '../../models/photo_model.dart';
import '../../routes/app_routes.dart';
import '../../services/album_media_picker_service.dart';
import '../../services/local_album_media_import_service.dart';
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
  bool _loading = true;
  bool _importing = false;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _album = LocalPhotoStore.getAlbum(widget.albumId);
      _photos = LocalPhotoStore.listPhotosInAlbum(widget.albumId);
      _loading = false;
    });
  }

  Future<void> _addPhotos() async {
    if (_importing) return;

    setState(() => _importing = true);
    try {
      final pickResult = await AlbumMediaPickerService.pickImages();
      if (pickResult.isEmpty) {
        if (!mounted) return;
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
      _reload();

      if (!mounted) return;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyImportError(e))),
      );
    } finally {
      if (mounted) {
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

    setState(() => _syncing = true);
    try {
      await PhotoSyncService.syncAlbum(widget.albumId);
      _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Album synced to server')),
      );
    } catch (e) {
      _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    } finally {
      if (mounted) {
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
                  _AlbumHero(
                    albumTitle: album?.title ?? widget.albumTitle,
                    photoCount: _photos.length,
                    pendingCount: pendingCount,
                    syncedCount: syncedCount,
                    failedCount: failedCount,
                    onBack: () => Navigator.pop(context),
                    onAddPhotos: _addPhotos,
                    onSync: _syncToServer,
                    importing: _importing,
                    syncing: _syncing,
                    latestUpdate: album?.updatedAt,
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: _photos.isEmpty
                        ? _AlbumEmptyState(onAddPhotos: _addPhotos)
                        : _PhotoGrid(photos: _photos),
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
  final VoidCallback onBack;
  final VoidCallback onAddPhotos;
  final VoidCallback onSync;

  const _AlbumHero({
    required this.albumTitle,
    required this.photoCount,
    required this.pendingCount,
    required this.syncedCount,
    required this.failedCount,
    required this.importing,
    required this.syncing,
    required this.latestUpdate,
    required this.onBack,
    required this.onAddPhotos,
    required this.onSync,
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
                          ? 'Local-first album'
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
    return Center(
      child: GlassContainer(
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
              'This album is empty',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add photos from your device. They will appear here instantly and stay local until you tap Sync to Server.',
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
              label: const Text('Add Photos'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final List<Photo> photos;

  const _PhotoGrid({
    required this.photos,
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
          padding: const EdgeInsets.only(bottom: 12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) => _PhotoTile(photo: photos[index]),
        );
      },
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final Photo photo;

  const _PhotoTile({
    required this.photo,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
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
