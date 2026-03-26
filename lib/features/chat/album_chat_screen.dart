import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/album_chat_socket.dart';
import '../../layout/main_app_shell.dart';
import '../../models/photo_model.dart';
import '../../services/local_photo_store.dart';
import '../timeline/timeline_photo_image.dart';
import '../timeline/timeline_smart_viewer.dart';
import '../../routes/app_routes.dart';

class AlbumChatScreen extends StatefulWidget {
  final String albumId;
  final String albumTitle;

  const AlbumChatScreen({
    super.key,
    required this.albumId,
    required this.albumTitle,
  });

  @override
  State<AlbumChatScreen> createState() => _AlbumChatScreenState();
}

class _AlbumChatScreenState extends State<AlbumChatScreen> {
  late final AlbumChatSocket _socket = AlbumChatSocket.forAlbum(widget.albumId);
  late final TextEditingController _textCtrl;
  StreamSubscription<AlbumChatMessage>? _sub;
  List<AlbumChatMessage> _messages = const [];
  Timer? _typingTimer;
  bool _showTyping = false;
  static final _timeFmt = DateFormat('MMM d, h:mm a');

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await LocalPhotoStore.init();
      } catch (_) {}
    });
    _socket.connectIfNeeded();
    _messages = _socket.history;
    _socket.sendMessage(sender: 'System', text: 'Rahul joined this memory');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You joined this memory 🎉')),
      );
    });
    _sub = _socket.messages.listen((_) {
      if (!mounted) return;
      setState(() => _messages = _socket.history);
    });
  }

  void _sendLatestPhoto() {
    List<Photo> photos = const [];
    try {
      photos = LocalPhotoStore.listPhotosInAlbum(widget.albumId);
    } catch (_) {}
    if (photos.isEmpty) return;
    final latest = photos.first;
    _socket.sendMessage(
      sender: 'You',
      text: 'added a photo',
      photoId: latest.id,
    );
    setState(() => _messages = _socket.history);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _typingTimer?.cancel();
    _textCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _socket.sendMessage(sender: 'You', text: text);
    _textCtrl.clear();
    _typingTimer?.cancel();
    setState(() {
      _showTyping = true;
    });
    _typingTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _showTyping = false);
    });
    setState(() => _messages = _socket.history);
  }

  @override
  Widget build(BuildContext context) {
    return MainAppShell(
      currentRoute: AppRoutes.timeline,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                Expanded(
                  child: Text(
                    'Chat · ${widget.albumTitle}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Relive this memory together',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length + (_showTyping ? 1 : 0),
              itemBuilder: (context, i) {
                if (_showTyping && i == 0) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'User typing...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }
                final base = _showTyping ? 1 : 0;
                final m = _messages[_messages.length - 1 - (i - base)];
                final mine = m.sender == 'You';
                final bubbleColor = mine
                    ? const Color(0xFF6F5CF2)
                    : Colors.white.withValues(alpha: 0.12);
                final opacity = m.pending ? 0.65 : 1.0;
                return TweenAnimationBuilder<double>(
                  key: ValueKey(m.id),
                  duration: const Duration(milliseconds: 220),
                  tween: Tween(begin: 0, end: 1),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, child) => Transform.translate(
                    offset: Offset((1 - t) * (mine ? 14 : -14), 0),
                    child: Opacity(opacity: opacity * t, child: child),
                  ),
                  child: Align(
                    alignment:
                        mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                m.sender,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _timeFmt.format(m.createdAt.toLocal()),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if ((m.emoji ?? '').isNotEmpty)
                            Text(
                              m.emoji!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                              ),
                            )
                          else
                            Text(
                              m.text,
                              style: const TextStyle(color: Colors.white),
                            ),
                          if ((m.photoId ?? '').isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _inlinePhoto(m.photoId!),
                          ],
                          if (m.pending)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Sending…',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final e in ['❤️', '🔥', '😂', '👍', '🎉'])
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: IconButton(
                            onPressed: () {
                              _socket.sendReaction(photoId: 'album', emoji: e);
                              setState(() => _messages = _socket.history);
                            },
                            icon: Text(e, style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _sendLatestPhoto,
                      icon: const Icon(Icons.photo, color: Colors.white),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _textCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Message album...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    IconButton(
                      onPressed: _send,
                      icon: const Icon(Icons.send, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inlinePhoto(String photoId) {
    final photo = LocalPhotoStore.getPhoto(photoId);
    if (photo == null) {
      return Text(
        '[photo]',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.75),
          fontSize: 11,
        ),
      );
    }
    return InkWell(
      onTap: () {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => TimelineSmartViewer(photos: [photo], initialIndex: 0),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 120,
          height: 120,
          child: buildTimelinePhotoImage(
            url: photo.serverUrl,
            thumbUrl: photo.thumbUrl,
            localPath: photo.localPath,
            localThumbnailPath: photo.localThumbnailPath,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
