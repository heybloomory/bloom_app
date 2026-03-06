import 'package:cloud_firestore/cloud_firestore.dart';

class DemoSeed {
  static Future<void> seedIfEmpty() async {
    final db = FirebaseFirestore.instance;

    final albumsSnap = await db.collection('albums').limit(1).get();
    if (albumsSnap.docs.isNotEmpty) return; // already has data

    await seedNow();
  }

  /// ✅ Use this when you want to re-test from scratch
  /// WARNING: deletes albums + all memories under them.
  static Future<void> resetAndSeed() async {
    final db = FirebaseFirestore.instance;

    final albums = await db.collection('albums').get();
    for (final a in albums.docs) {
      // delete memories
      final mems = await a.reference.collection('memories').get();
      for (final m in mems.docs) {
        // delete comments (optional)
        final comments = await m.reference.collection('comments').get();
        for (final c in comments.docs) {
          await c.reference.delete();
        }
        // delete likes (optional)
        final likes = await m.reference.collection('likes').get();
        for (final l in likes.docs) {
          await l.reference.delete();
        }
        await m.reference.delete();
      }
      await a.reference.delete();
    }

    await seedNow();
  }

  static Future<void> seedNow() async {
    final db = FirebaseFirestore.instance;
    final now = DateTime.now();

    // ✅ More albums + month spread for Timeline sections
    final demoAlbums = [
      {
        'title': 'Goa Trip',
        'seedBase': 'goa',
        'count': 10,
        'monthOffset': 0,
        'folder1': 'Trips',
        'folder2': 'Goa'
      },
      {
        'title': 'Campus Life',
        'seedBase': 'campus',
        'count': 8,
        'monthOffset': 0,
        'folder1': 'Life'
      },
      {
        'title': 'Family Moments',
        'seedBase': 'family',
        'count': 12,
        'monthOffset': 0,
        'folder1': 'Family'
      },

      {
        'title': 'Birthday Party',
        'seedBase': 'birthday',
        'count': 14,
        'monthOffset': 1,
        'folder1': 'Events'
      },
      {'title': 'Road Trip', 'seedBase': 'road', 'count': 9, 'monthOffset': 1},
      {'title': 'Gym Progress', 'seedBase': 'gym', 'count': 7, 'monthOffset': 1},

      {
        'title': 'Dubai Nights',
        'seedBase': 'dubai',
        'count': 11,
        'monthOffset': 2,
        'folder1': 'Trips',
        'folder2': 'Dubai'
      },
      {'title': 'Beach Day', 'seedBase': 'beach', 'count': 10, 'monthOffset': 2},
      {'title': 'Cafe Hopping', 'seedBase': 'cafe', 'count': 8, 'monthOffset': 2},

      {
        'title': 'Snow Manali',
        'seedBase': 'snow',
        'count': 9,
        'monthOffset': 3,
        'folder1': 'Trips',
        'folder2': 'Manali'
      },
      {'title': 'Wedding Shoot', 'seedBase': 'wedding', 'count': 16, 'monthOffset': 3},
      {'title': 'Friends Reunion', 'seedBase': 'friends', 'count': 12, 'monthOffset': 3},

      {'title': 'New Year 2026', 'seedBase': 'newyear', 'count': 15, 'monthOffset': 4},
      {'title': 'Concert Night', 'seedBase': 'concert', 'count': 9, 'monthOffset': 4},
      {'title': 'Street Food', 'seedBase': 'food', 'count': 10, 'monthOffset': 4},
    ];

    final batch = db.batch();

    for (final a in demoAlbums) {
      final albumRef = db.collection('albums').doc();

      final title = a['title'] as String;
      final seedBase = a['seedBase'] as String;
      final count = a['count'] as int;
      final monthOffset = a['monthOffset'] as int;

      // Spread by month so Timeline sections look real
      final createdAt = DateTime(now.year, now.month - monthOffset, 10, 12, 0);

      final coverUrl = _thumbUrl('$seedBase-0');

      batch.set(albumRef, {
        'title': title,
        'coverUrl': coverUrl,
        'memoryCount': count,
        'createdAt': Timestamp.fromDate(createdAt),
        if (a['folder1'] != null) 'folder1': a['folder1'],
        if (a['folder2'] != null) 'folder2': a['folder2'],
      });

      for (int i = 0; i < count; i++) {
        final memRef = albumRef.collection('memories').doc();
        final seed = '$seedBase-$i';

        batch.set(memRef, {
          'title': '$title #${i + 1}',
          'description': 'Demo photo for testing like & comments',
          'thumbUrl': _thumbUrl(seed),
          'imageUrl': _imageUrl(seed),
          'likeCount': 0,
          'createdAt': Timestamp.fromDate(createdAt),
        });
      }
    }

    await batch.commit();
  }

  static String _imageUrl(String seed) =>
      'https://picsum.photos/seed/$seed/1200/900';

  static String _thumbUrl(String seed) =>
      'https://picsum.photos/seed/$seed/500/350';
}
