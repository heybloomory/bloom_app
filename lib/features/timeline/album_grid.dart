import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

import '../../core/widgets/glass_container.dart';
import '../../models/photo_model.dart';
import '../../models/timeline_album_summary.dart';
import 'timeline_photo_image.dart';

class AlbumGrid extends StatelessWidget {
  final List<TimelineAlbumSummary> albums;
  final void Function(TimelineAlbumSummary album) onAlbumTap;

  const AlbumGrid({
    super.key,
    required this.albums,
    required this.onAlbumTap,
  });

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return const _AlbumEmptyState();
    }

    const spacing = 16.0;
    const targetTileWidth = 220.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            ((constraints.maxWidth + spacing) / (targetTileWidth + spacing))
                .floor()
                .clamp(1, 5);

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 0.83,
          ),
          itemCount: albums.length,
          itemBuilder: (_, index) => _AlbumCard(
            album: albums[index],
            onTap: () => onAlbumTap(albums[index]),
          ),
        );
      },
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final TimelineAlbumSummary album;
  final VoidCallback onTap;

  const _AlbumCard({
    required this.album,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cover = album.coverPhoto;
    final latest = album.latestPhotoAt ?? album.album.updatedAt;
    final earliest = album.earliestPhotoAt ?? album.album.createdAt;
    final dateLabel = _dateRangeLabel(earliest, latest);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: GlassContainer(
        radius: 24,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      child: _buildCover(cover),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _StatusBadge(
                      icon: Icons.photo_library_outlined,
                      label: '${album.photoCount}',
                    ),
                  ),
                  if (album.pendingCount > 0)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _StatusBadge(
                        icon: Icons.cloud_upload_outlined,
                        label: '${album.pendingCount} pending',
                        accentColor: const Color(0xFFF2C66D),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        height: 86,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.55),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.album.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${album.photoCount} item${album.photoCount == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: 12,
                    ),
                  ),
                  if (album.failedCount > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${album.failedCount} failed to sync',
                      style: const TextStyle(
                        color: Color(0xFFFFB4A4),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(Photo? cover) {
    final coverBytes = album.album.coverBytes;
    final coverPath = (album.album.coverPath ?? '').trim();
    if (kIsWeb && coverBytes != null && coverBytes.isNotEmpty) {
      return Image.memory(coverBytes, fit: BoxFit.cover);
    }
    if (!kIsWeb && coverPath.isNotEmpty) {
      return buildTimelinePhotoImage(
        url: null,
        thumbUrl: null,
        localPath: coverPath,
        fit: BoxFit.cover,
      );
    }
    return cover == null
                          ? Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.10),
                                    Colors.white.withValues(alpha: 0.04),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.photo_album_outlined,
                                  color: Colors.white70,
                                  size: 48,
                                ),
                              ),
                            )
                          : buildTimelinePhotoImage(
                              url: cover.serverUrl,
                              thumbUrl: cover.thumbUrl,
                              localPath: cover.localPath,
                              localThumbnailPath: cover.localThumbnailPath,
                              memoryBytes: cover.bytes,
                              fit: BoxFit.cover,
                            );
  }

  String _dateRangeLabel(DateTime start, DateTime end) {
    final fmt = DateFormat('MMM d');
    final sameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    if (sameDay) {
      return 'Updated ${DateFormat('MMM d, y').format(end)}';
    }
    return '${fmt.format(start)} - ${DateFormat('MMM d, y').format(end)}';
  }
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accentColor;

  const _StatusBadge({
    required this.icon,
    required this.label,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
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
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumEmptyState extends StatelessWidget {
  const _AlbumEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassContainer(
          radius: 28,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  color: Colors.white70,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No local albums yet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create an album, add local photos, and sync to the server only when you are ready.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
