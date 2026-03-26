import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Full-screen playback: network URL (Bunny / CDN) or local file path.
class VideoPlayerScreen extends StatefulWidget {
  final String? networkUrl;
  final String? filePath;
  final String title;

  const VideoPlayerScreen.network({
    super.key,
    required String url,
    this.title = 'Video',
  })  : networkUrl = url,
        filePath = null;

  const VideoPlayerScreen.file({
    super.key,
    required String path,
    this.title = 'Video',
  })  : networkUrl = null,
        filePath = path;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final VideoPlayerController c;
      final u = widget.networkUrl;
      final f = widget.filePath;
      if (u != null && u.isNotEmpty) {
        c = VideoPlayerController.networkUrl(Uri.parse(u));
      } else if (f != null && f.isNotEmpty && !kIsWeb) {
        c = VideoPlayerController.file(File(f));
      } else {
        throw StateError('No video source');
      }
      await c.initialize();
      if (!mounted) return;
      c.addListener(() {
        if (mounted) setState(() {});
      });
      setState(() {
        _controller = c;
        _busy = false;
      });
      await c.play();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: _busy
                    ? const CircularProgressIndicator(color: Colors.white54)
                    : _error != null
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : c != null && c.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: c.value.aspectRatio == 0
                                    ? 16 / 9
                                    : c.value.aspectRatio,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    VideoPlayer(c),
                                    if (c.value.isBuffering)
                                      const CircularProgressIndicator(
                                        color: Colors.white54,
                                      ),
                                    IconButton(
                                      iconSize: 64,
                                      onPressed: () {
                                        if (c.value.isPlaying) {
                                          c.pause();
                                        } else {
                                          c.play();
                                        }
                                        setState(() {});
                                      },
                                      icon: Icon(
                                        c.value.isPlaying
                                            ? Icons.pause_circle_filled
                                            : Icons.play_circle_filled,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
              ),
            ),
            if (c != null && c.value.isInitialized)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () async {
                        await c.setVolume(c.value.volume > 0 ? 0 : 1);
                        setState(() {});
                      },
                      icon: Icon(
                        c.value.volume > 0
                            ? Icons.volume_up
                            : Icons.volume_off,
                        color: Colors.white70,
                      ),
                    ),
                    Expanded(
                      child: VideoProgressIndicator(
                        c,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Color(0xFF6F5CF2),
                          bufferedColor: Colors.white24,
                          backgroundColor: Colors.white10,
                        ),
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
}
