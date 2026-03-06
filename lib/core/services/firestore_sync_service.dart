import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/id_util.dart';

/// Keeps Firestore "Timeline" data in sync with the backend API.
///
/// Why: Timeline page reads from Firestore (collection: albums). If albums/media are
/// created only via API, they won't appear. So we mirror minimal metadata to Firestore.
class FirestoreSyncService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> upsertAlbumFromApi(Map<String, dynamic> album) async {
    final id = (album['id'] ?? album['_id'] ?? album['albumId'])?.toString();
    if (id == null || id.isEmpty) return;

    final uid = _auth.currentUser?.uid;

    final title = (album['title'] ?? album['name'] ?? 'Album').toString();
    final coverUrl = (album['coverUrl'] ?? album['cover'] ?? album['cover_url'])?.toString();
    final thumbUrl = (album['thumbUrl'] ?? album['thumbnailUrl'] ?? album['thumb_url'])?.toString();

    // If API provides createdAt, use it; otherwise serverTimestamp.
    final createdAtRaw = album['createdAt'] ?? album['created_at'];

    await _db.collection('albums').doc(id).set(
      {
        'title': title,
        if (uid != null) 'ownerId': uid,
        if (coverUrl != null && coverUrl.isNotEmpty) 'coverUrl': coverUrl,
        if (thumbUrl != null && thumbUrl.isNotEmpty) 'thumbUrl': thumbUrl,
        // keep memoryCount if already exists; default 0
        'memoryCount': FieldValue.increment(0),
        'createdAt': createdAtRaw is Timestamp
            ? createdAtRaw
            : FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> upsertMediaFromApi({
    required String albumId,
    required Map<String, dynamic> media,
  }) async {
    final url = (media['url'] ?? media['cdnUrl'] ?? media['fileUrl'])?.toString();

    var mediaId = (media['id'] ?? media['_id'] ?? media['mediaId'] ?? media['memoryId'])?.toString();
    if (mediaId == null || mediaId.isEmpty) {
      if (url == null || url.isEmpty) return;
      mediaId = IdUtil.fromUrl(url);
    }
    final thumbUrl = (media['thumbUrl'] ?? media['thumbnailUrl'] ?? media['thumb_url'])?.toString();
    final createdAtRaw = media['createdAt'] ?? media['created_at'];

    final albumRef = _db.collection('albums').doc(albumId);
    final memRef = albumRef.collection('memories').doc(mediaId);

    await _db.runTransaction((tx) async {
      tx.set(
        memRef,
        {
          if (url != null && url.isNotEmpty) 'url': url,
          if (thumbUrl != null && thumbUrl.isNotEmpty) 'thumbUrl': thumbUrl,
          'createdAt': createdAtRaw is Timestamp
              ? createdAtRaw
              : FieldValue.serverTimestamp(),
          'likeCount': FieldValue.increment(0),
        },
        SetOptions(merge: true),
      );

      // Increment memoryCount
      tx.set(albumRef, {'memoryCount': FieldValue.increment(1)}, SetOptions(merge: true));

      // Set album cover only if not already set
      final albumSnap = await tx.get(albumRef);
      final existing = albumSnap.data();
      final hasCover = existing != null && ((existing['coverUrl'] ?? '').toString().isNotEmpty);
      if (!hasCover && url != null && url.isNotEmpty) {
        tx.set(
          albumRef,
          {
            'coverUrl': url,
            if (thumbUrl != null && thumbUrl.isNotEmpty) 'thumbUrl': thumbUrl,
          },
          SetOptions(merge: true),
        );
      }
    });
  }
}
