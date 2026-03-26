import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/photo_model.dart';
import 'timeline_photo_image.dart';
import 'video_player_screen.dart';

/// Lightweight full-screen viewer for a list of local [Photo]s (hero-friendly).
class TimelineSmartViewer extends StatelessWidget {
  final List<Photo> photos;
  final int initialIndex;

  const TimelineSmartViewer({
    super.key,
    required this.photos,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text('No photos', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    final safeIndex = initialIndex.clamp(0, photos.length - 1);
    return _TimelineSmartViewerBody(
      photos: photos,
      initialIndex: safeIndex,
    );
  }
}

class _TimelineSmartViewerBody extends StatefulWidget {
  final List<Photo> photos;
  final int initialIndex;

  const _TimelineSmartViewerBody({
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<_TimelineSmartViewerBody> createState() =>
      _TimelineSmartViewerBodyState();
}

class _TimelineSmartViewerBodyState extends State<_TimelineSmartViewerBody> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.photos.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final p = widget.photos[i];
                return Center(
                  child: Hero(
                    tag: 'smart-photo-${p.id}',
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: buildTimelinePhotoImage(
                        url: p.serverUrl,
                        thumbUrl: p.thumbUrl,
                        localPath: p.localPath,
                        localThumbnailPath: p.localThumbnailPath,
                        memoryBytes: p.bytes,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 4,
              left: 4,
              right: 4,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      '${_index + 1} / ${widget.photos.length}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  if (photo.isVideoHint)
                    IconButton(
                      onPressed: () => _openVideo(context, photo),
                      icon: const Icon(
                        Icons.play_circle_filled,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openVideo(BuildContext context, Photo photo) {
    final url = photo.serverUrl?.trim();
    if (url != null && url.isNotEmpty && url.startsWith('http')) {
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => VideoPlayerScreen.network(
            url: url,
            title: 'Video',
          ),
        ),
      );
      return;
    }
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Local video playback is not available on web.'),
        ),
      );
      return;
    }
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => VideoPlayerScreen.file(
          path: photo.localPath,
          title: 'Video',
        ),
      ),
    );
  }
}

extension on Photo {
  bool get isVideoHint {
    final n = (originalFileName ?? localPath).toLowerCase();
    return n.endsWith('.mp4') ||
        n.endsWith('.mov') ||
        n.endsWith('.webm') ||
        n.endsWith('.m4v');
  }
}
