import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';
import '../../core/services/album_api_service.dart';
import '../../core/services/firestore_sync_service.dart';
import '../../core/services/media_api_service.dart';
import '../../core/utils/cdn_url.dart';
import '../../core/utils/image_compress.dart';
import '../../core/utils/id_util.dart';

class AlbumDetailScreen extends StatefulWidget {
  final String albumId;

  const AlbumDetailScreen({super.key, required this.albumId});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = AlbumApiService.getAlbum(widget.albumId);
  }

  void _reload() {
    setState(() => _future = AlbumApiService.getAlbum(widget.albumId));
  }

  Future<void> _createSubAlbumDialog({required int currentLevel}) async {
    if (currentLevel >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only 2 levels allowed.')),
      );
      return;
    }

    final titleCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Sub-Album'),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
        ],
      ),
    );

    if (ok != true) return;
    final title = titleCtrl.text.trim();
    if (title.isEmpty) return;

    try {
      await AlbumApiService.createAlbum(title: title, parentId: widget.albumId);
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _pickAndUploadImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      for (final f in result.files) {
        if (f.bytes == null) continue;
        // ✅ Compress before upload (quality ~60) so large photos are reduced client-side.
        final originalName = (f.name.isNotEmpty)
            ? f.name
            : 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final compressedBytes = await ImageCompress.compressToJpeg(
          f.bytes!,
          quality: 60,
        );

        // ✅ Create & upload a real thumbnail file (preferred over CDN transform links).
        final thumbBytes = await ImageCompress.thumbnailJpeg(
          compressedBytes,
          quality: 70,
          width: 300,
          height: 200,
        );

        final uploadName = ImageCompress.toJpegName(originalName);
        final thumbName = 'thumb_${ImageCompress.toJpegName(originalName)}';

        final media = await MediaApiService.uploadToAlbum(
          albumId: widget.albumId,
          bytes: compressedBytes,
          fileName: uploadName,
          thumbnailBytes: thumbBytes,
          thumbnailFileName: thumbName,
        );

        // Mirror to Firestore so likes/comments + Timeline metadata work.
        try {
          await FirestoreSyncService.upsertMediaFromApi(
            albumId: widget.albumId,
            media: media,
          );
        } catch (_) {}
      }

      _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploaded ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width < 600
        ? 2
        : width < 1000
            ? 3
            : 4;

    return MainAppShell(
      currentRoute: AppRoutes.albums,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!;
            final album = (data['album'] as Map).cast<String, dynamic>();
            final children = (data['children'] as List<dynamic>? ?? []);
            final media = (data['media'] as List<dynamic>? ?? []);

            final title = (album['title'] ?? 'Album').toString();
            final level = (album['level'] ?? 1) as int;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text('${media.length} Images', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    if (level == 1)
                      ElevatedButton.icon(
                        onPressed: () => _createSubAlbumDialog(currentLevel: level),
                        icon: const Icon(Icons.create_new_folder),
                        label: const Text('Sub-Album'),
                      ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _pickAndUploadImages,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Add Image'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
                  ],
                ),

                const SizedBox(height: 18),

                if (children.isNotEmpty) ...[
                  const Text('Sub-Albums', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: children.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final c = (children[i] as Map).cast<String, dynamic>();
                        final id = (c['_id'] ?? '').toString();
                        final t = (c['title'] ?? 'Album').toString();
                        return InkWell(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.albumDetail,
                              arguments: {'albumId': id, 'albumTitle': t},
                            );
                          },
                          child: Container(
                            width: 180,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.folder, size: 28),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(t, maxLines: 2, overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                const Text('Images', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),

                Expanded(
                  child: media.isEmpty
                      ? const Center(child: Text('No images yet'))
                      : GridView.builder(
                          itemCount: media.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemBuilder: (context, index) {
                            final m = (media[index] as Map).cast<String, dynamic>();
                            final fullUrl = (m['url'] ?? m['mediaUrl'] ?? m['imageUrl'] ?? '').toString();
                            var thumbUrl = (m['thumbUrl'] ?? m['thumbnailUrl'] ?? m['thumb_url'] ?? m['thumb'] ?? '').toString();
                            if (thumbUrl.isEmpty && fullUrl.isNotEmpty) {
                              // ✅ BunnyCDN thumbnail transform reference
                              thumbUrl = CdnUrl.thumbnail(fullUrl, width: 300, height: 200);
                            }

                            return GestureDetector(
                              onTap: () {
                                final items = media
                                    .map((x) => (x as Map).cast<String, dynamic>())
                                    .map((x) => _MediaItem(
                                          url: (x['url'] ?? x['mediaUrl'] ?? x['imageUrl'] ?? '').toString(),
                                          id: (() {
                                            final raw = (x['id'] ?? x['_id'] ?? x['mediaId'] ?? x['memoryId'] ?? '').toString();
                                            final u = (x['url'] ?? x['mediaUrl'] ?? x['imageUrl'] ?? '').toString();
                                            return raw.isNotEmpty ? raw : (u.isNotEmpty ? IdUtil.fromUrl(u) : '');
                                          })(),
                                        ))
                                    .where((it) => it.url.isNotEmpty)
                                    .toList();

                                final initial = items.indexWhere((it) => it.url == fullUrl);

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => _AlbumImageModal(
                                      albumId: widget.albumId,
                                      items: items,
                                      initialIndex: initial >= 0 ? initial : 0,
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  color: Colors.grey.shade300,
                                  child: thumbUrl.isEmpty
                                      ? const Center(child: Icon(Icons.image_not_supported))
                                      : Image.network(
                                          thumbUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Center(
                                            child: Icon(Icons.broken_image),
                                          ),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Full-screen viewer matching the reference: vertical swipe, black stage, back button.
class _AlbumImageModal extends StatefulWidget {
  final String albumId;
  final List<_MediaItem> items;
  final int initialIndex;

  const _AlbumImageModal({
    required this.albumId,
    required this.items,
    required this.initialIndex,
  });

  @override
  State<_AlbumImageModal> createState() => _AlbumImageModalState();
}

class _AlbumImageModalState extends State<_AlbumImageModal> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Image')),
        body: const Center(child: Text('No images')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                scrollDirection: Axis.vertical,
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final url = widget.items[index].url;
                  return Container(
                    width: double.infinity,
                    color: Colors.black,
                    child: url.isEmpty
                        ? const Center(
                            child: Icon(Icons.image, size: 96, color: Colors.white70),
                          )
                        : InteractiveViewer(
                            child: Image.network(
                              url,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image, color: Colors.white70),
                              ),
                            ),
                          ),
                  );
                },
              ),
            ),
            // Like / Comment / Share bar (Firestore-backed, matches reference behavior)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final page = (_controller.page ?? widget.initialIndex.toDouble()).round();
                  final safeIndex = page.clamp(0, widget.items.length - 1);
                  final mediaId = widget.items[safeIndex].id;
                  return Row(
                    children: [
                      Expanded(
                        child: _MemoryActions(
                          albumId: widget.albumId,
                          memoryId: mediaId,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('Swipe ↑↓', style: TextStyle(color: Colors.grey)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaItem {
  final String id;
  final String url;
  const _MediaItem({required this.id, required this.url});
}

class _MemoryActions extends StatefulWidget {
  final String albumId;
  final String memoryId;

  const _MemoryActions({required this.albumId, required this.memoryId});

  @override
  State<_MemoryActions> createState() => _MemoryActionsState();
}

class _MemoryActionsState extends State<_MemoryActions> {
  final _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> _memoryRef() {
    return FirebaseFirestore.instance
        .collection('albums')
        .doc(widget.albumId)
        .collection('memories')
        .doc(widget.memoryId);
  }

  DocumentReference<Map<String, dynamic>> _likeRef(String uid) {
    return _memoryRef().collection('likes').doc(uid);
  }

  Future<void> _toggleLike() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to like')),
      );
      return;
    }

    final memRef = _memoryRef();
    final likeRef = _likeRef(user.uid);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final likeSnap = await tx.get(likeRef);
      if (likeSnap.exists) {
        tx.delete(likeRef);
        tx.set(memRef, {'likeCount': FieldValue.increment(-1)}, SetOptions(merge: true));
      } else {
        tx.set(likeRef, {
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.set(memRef, {'likeCount': FieldValue.increment(1)}, SetOptions(merge: true));
      }
    });
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsBottomSheet(
        albumId: widget.albumId,
        memoryId: widget.memoryId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final memRef = _memoryRef();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: memRef.snapshots(),
      builder: (context, memSnap) {
        final likeCount = (memSnap.data?.data()?['likeCount'] ?? 0);
        final likeCountInt = (likeCount is int) ? likeCount : int.tryParse('$likeCount') ?? 0;

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: user == null ? null : _likeRef(user.uid).snapshots(),
          builder: (context, likeSnap) {
            final isLiked = user != null && (likeSnap.data?.exists ?? false);

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.black,
                      ),
                      onPressed: _toggleLike,
                    ),
                    Text('$likeCountInt'),
                  ],
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: memRef.collection('comments').snapshots(),
                  builder: (context, cs) {
                    final commentCount = cs.data?.docs.length ?? 0;
                    return Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.comment),
                          onPressed: _openComments,
                        ),
                        Text('$commentCount'),
                      ],
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {},
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CommentsBottomSheet extends StatefulWidget {
  final String albumId;
  final String memoryId;

  const _CommentsBottomSheet({required this.albumId, required this.memoryId});

  @override
  State<_CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<_CommentsBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsRef = FirebaseFirestore.instance
        .collection('albums')
        .doc(widget.albumId)
        .collection('memories')
        .doc(widget.memoryId)
        .collection('comments')
        .orderBy('createdAt', descending: true);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: commentsRef.snapshots(),
                  builder: (context, snap) {
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(child: Text('No comments yet'));
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final d = docs[i].data() as Map<String, dynamic>;
                        final text = (d['text'] ?? '').toString();
                        final userId = (d['userId'] ?? '').toString();
                        return ListTile(
                          leading: const Icon(Icons.account_circle),
                          title: Text(text),
                          subtitle: Text(userId.isEmpty ? '' : userId),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Write a comment…',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final user = _auth.currentUser;
                      final text = _controller.text.trim();
                      if (text.isEmpty) return;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please login to comment')),
                        );
                        return;
                      }
                      await FirebaseFirestore.instance
                          .collection('albums')
                          .doc(widget.albumId)
                          .collection('memories')
                          .doc(widget.memoryId)
                          .collection('comments')
                          .add({
                        'text': text,
                        'userId': user.uid,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      _controller.clear();
                    },
                    child: const Text('Send'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
