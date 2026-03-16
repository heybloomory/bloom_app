import 'package:flutter/material.dart';

import '../../layout/main_app_shell.dart';
import '../../models/timeline_album_summary.dart';
import '../../models/album_model.dart';
import '../../models/photo_model.dart';
import '../../routes/app_routes.dart';
import '../../services/local_album_service.dart';
import '../../core/services/timeline_api_service.dart';
import '../../core/services/auth_session.dart';
import 'album_detail_screen.dart';
import 'album_grid.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  List<TimelineAlbumSummary> _albums = const <TimelineAlbumSummary>[];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    setState(() {
      _loading = true;
    });

    try {
      // Try remote timeline first
      final remote =
          await TimelineApiService.fetchTimeline(limit: 50, offset: 0);
      final albums = remote.map<TimelineAlbumSummary>((memory) {
        final id = (memory['id'] ?? '').toString();
        final title = (memory['title'] ?? '').toString();
        final createdAtStr = (memory['createdAt'] ?? memory['created_at'] ?? '').toString();
        final updatedAtStr = (memory['updatedAt'] ?? memory['updated_at'] ?? '').toString();

        DateTime createdAt = DateTime.now();
        if (createdAtStr.isNotEmpty) {
          createdAt = DateTime.tryParse(createdAtStr) ?? createdAt;
        }
        DateTime updatedAt = createdAt;
        if (updatedAtStr.isNotEmpty) {
          updatedAt = DateTime.tryParse(updatedAtStr) ?? createdAt;
        }

        final album = TimelineAlbum(
          id: id.isEmpty ? 'memory_${createdAt.millisecondsSinceEpoch}' : id,
          title: title.isEmpty ? 'Untitled memory' : title,
          createdAt: createdAt,
          updatedAt: updatedAt,
          backendAlbumId: id.isEmpty ? null : id,
        );

        // No local photos yet; remote timeline only exposes memory-level data.
        return TimelineAlbumSummary(
          album: album,
          photos: <Photo>[],
        );
      }).toList();

      setState(() {
        _albums = albums;
      });
    } catch (e) {
      // If unauthorized, clear token so user is sent back to login on next action.
      final msg = e.toString();
      if (msg.contains('Unauthorized (401)')) {
        await AuthSession.clear();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (_) => false,
        );
        return;
      }

      // Fallback to local albums if remote fails.
      setState(() {
        _albums = LocalAlbumService.listAlbumSummaries();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _createAlbum() async {
    final titleCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create album'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: titleCtrl,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Album title',
              hintText: 'Weekend trip, Family, Favorites...',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter an album title';
              }
              return null;
            },
            onFieldSubmitted: (_) {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
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

    if (created != true || !mounted) return;

    final album = LocalAlbumService.createAlbum(titleCtrl.text.trim());
    _loadAlbums();
    _openAlbum(_albums.firstWhere(
      (item) => item.album.id == album.id,
      orElse: () => TimelineAlbumSummary(album: album, photos: const []),
    ));
  }

  void _openAlbum(TimelineAlbumSummary album) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => TimelineAlbumDetailScreen(
          albumId: album.album.id,
          albumTitle: album.album.title,
        ),
      ),
    ).then((_) => _loadAlbums());
  }

  @override
  Widget build(BuildContext context) {
    final albumCount = _albums.length;
    final photoCount =
        _albums.fold<int>(0, (total, album) => total + album.photoCount);
    final pendingCount =
        _albums.fold<int>(0, (total, album) => total + album.pendingCount);

    return MainAppShell(
      currentRoute: AppRoutes.timeline,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: _TimelineHeader(
              albumCount: albumCount,
              photoCount: photoCount,
              pendingCount: pendingCount,
              onRefresh: () {
                // fire-and-forget; UI shows loading state
                _loadAlbums();
              },
              onCreateAlbum: _createAlbum,
            ),
          ),
          if (_loading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else
            Expanded(
              child: AlbumGrid(
                albums: _albums,
                onAlbumTap: _openAlbum,
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineHeader extends StatelessWidget {
  final int albumCount;
  final int photoCount;
  final int pendingCount;
  final VoidCallback onRefresh;
  final VoidCallback onCreateAlbum;

  const _TimelineHeader({
    required this.albumCount,
    required this.photoCount,
    required this.pendingCount,
    required this.onRefresh,
    required this.onCreateAlbum,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Timeline Albums',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, color: Colors.white70),
              ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                onPressed: onCreateAlbum,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('New Album'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Google Photos-inspired local album flow: add photos instantly, then sync when you choose.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricChip(
                icon: Icons.photo_album_outlined,
                label: '$albumCount albums',
              ),
              _MetricChip(
                icon: Icons.image_outlined,
                label: '$photoCount local photos',
              ),
              _MetricChip(
                icon: Icons.cloud_upload_outlined,
                label: pendingCount == 0
                    ? 'Everything synced or local-ready'
                    : '$pendingCount waiting to sync',
                highlight: pendingCount > 0,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;

  const _MetricChip({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight ? const Color(0xFFF2C66D) : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.06),
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
