import '../ai/ask_bloomory_screen.dart';
import '../chat/chat_list_view.dart';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/services/album_api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showFilter = false;

  // ✅ Timeline filter state (drives what shows in the grid)
  _TimelineFilterState _filter = const _TimelineFilterState();

  @override
  void initState() {
    super.initState();

    // ✅ Ensure API-created albums also show up in Timeline (Firestore mirror).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await AlbumApiService.listRootAlbums();
      } catch (_) {
        // Ignore (no token / offline / etc.)
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainAppShell(
      currentRoute: AppRoutes.dashboard,
      child: Stack(
        children: [
          _TimelineView(
            onOpenFilter: () => setState(() => _showFilter = true),
            filter: _filter,
          ),

          // ✅ Fixed floating bottom bar (doesn't scroll with timeline)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _ChatAiFloatingBar(
              onOpenChat: () => _openChatAiSheet(context, initialTab: 0),
              onOpenAi: () => _openChatAiSheet(context, initialTab: 1),
            ),
          ),

          if (_showFilter)
            _FilterOverlay(
              onClose: () => setState(() => _showFilter = false),
              initial: _filter,
              onApply: (next) {
                setState(() {
                  _filter = next;
                  _showFilter = false;
                });
              },
              onClear: () {
                setState(() {
                  _filter = const _TimelineFilterState();
                  _showFilter = false;
                });
              },
            ),
        ],
      ),
    );
  }

  void _openChatAiSheet(BuildContext context, {required int initialTab}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChatAiBottomSheet(initialTab: initialTab),
    );
  }
}

class _ChatAiFloatingBar extends StatelessWidget {
  final VoidCallback onOpenChat;
  final VoidCallback onOpenAi;

  const _ChatAiFloatingBar({
    required this.onOpenChat,
    required this.onOpenAi,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: GlassContainer(
        radius: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: _PillAction(
                icon: Icons.chat_bubble_outline,
                label: 'Chat',
                onTap: onOpenChat,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PillAction(
                icon: Icons.auto_awesome,
                label: 'AI',
                onTap: onOpenAi,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PillAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatAiBottomSheet extends StatelessWidget {
  final int initialTab;
  const _ChatAiBottomSheet({required this.initialTab});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(left: 12, right: 12, bottom: 12 + bottomInset),
          child: GlassContainer(
            radius: 28,
            padding: const EdgeInsets.all(12),
            child: DefaultTabController(
              length: 2,
              initialIndex: initialTab.clamp(0, 1),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    tabs: [
                      Tab(text: 'Chat'),
                      Tab(text: 'AI Tools'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _ChatTab(scrollController: scrollController),
                        _AiTab(scrollController: scrollController),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
class _ChatTab extends StatelessWidget {
  final ScrollController scrollController;
  const _ChatTab({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return const ChatListView();
  }
}

// class _ChatTab extends StatelessWidget {
//   final ScrollController scrollController;
//   const _ChatTab({required this.scrollController});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Expanded(
//           child: ListView(
//             controller: scrollController,
//             children: const [
//               SizedBox(height: 10),
//               Text(
//                 'Chat (placeholder)\n\nConnect this to your chat backend / support bot later.',
//                 style: TextStyle(color: Colors.white70, height: 1.35),
//               ),
//               SizedBox(height: 18),
//             ],
//           ),
//         ),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.06),
//             borderRadius: BorderRadius.circular(18),
//             border: Border.all(color: Colors.white.withOpacity(0.10)),
//           ),
//           child: Row(
//             children: [
//               const Expanded(
//                 child: Text(
//                   'Type a message…',
//                   style: TextStyle(color: Colors.white54),
//                 ),
//               ),
//               IconButton(
//                 onPressed: null,
//                 icon: const Icon(Icons.send, color: Colors.white38),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

class _AiTab extends StatelessWidget {
  final ScrollController scrollController;
  const _AiTab({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    const items = <_AiToolItem>[
      _AiToolItem('Ask me anything', Icons.chat_bubble_outline),
      _AiToolItem('Duplicate detection', Icons.content_copy),
      _AiToolItem('Best photo selection', Icons.star_border),
      _AiToolItem('Auto tagging', Icons.tag),
      _AiToolItem('Auto organization', Icons.folder_copy_outlined),
      _AiToolItem('Auto enhancement', Icons.auto_fix_high),
      _AiToolItem('Filters (Snapchat-like)', Icons.filter_vintage_outlined),
    ];

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.only(top: 10, bottom: 14),
      itemCount: items.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Text(
            'AI Tools (UI only)\n\nWire these buttons to your on-device models / cloud APIs when ready.',
            style: TextStyle(color: Colors.white70, height: 1.35),
          );
        }

        final item = items[index - 1];
        final title = item.title;
        final icon = item.icon;
        return InkWell(
          borderRadius: BorderRadius.circular(18),
       onTap: () {
  if (title == 'Ask me anything') {
    // Close the bottom sheet first
    Navigator.of(context).pop();

    // Then open the Ask screen using the root navigator
    Future.microtask(() {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => const AskBloomoryScreen()),
      );
    });

    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$title coming soon'),
      behavior: SnackBarBehavior.floating,
    ),
  );
},

          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.7)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AiToolItem {
  final String title;
  final IconData icon;
  const _AiToolItem(this.title, this.icon);
}

class _TimelineView extends StatelessWidget {
  final VoidCallback onOpenFilter;
  final _TimelineFilterState filter;

  const _TimelineView({required this.onOpenFilter, required this.filter});

  @override
  Widget build(BuildContext context) {
    final albumsStream = FirebaseFirestore.instance
        .collection('albums')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return SingleChildScrollView(
      // Leave room for the floating bottom bar
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ No top "bar box" — keep the page clean.
          const Padding(
            padding: EdgeInsets.only(left: 2, bottom: 10),
            child: Text(
              'Timeline',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          _SearchBar(
            filterLabel: filter.label,
            onFilterTap: onOpenFilter,
            onCreateAlbum: () => _showCreateAlbumDialog(context),
          ),
          const SizedBox(height: 18),

          // ✅ Timeline Firestore Albums grouped by month
          StreamBuilder<QuerySnapshot>(
            stream: albumsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                final msg = snapshot.error.toString();
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    msg.contains('permission-denied')
                        ? 'Firestore rules blocking read.\nAllow read OR login.'
                        : 'Error loading albums: $msg',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No albums yet',
                          style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.albums),
                        icon: const Icon(Icons.photo_album),
                        label: const Text('Open Albums'),
                      ),
                    ],
                  ),
                );
              }

              // ✅ Apply filters client-side (fast + keeps UI simple)
              final filtered = _applyFilter(docs, filter);
              final sections = _groupAlbumsByMonth(filtered);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final section in sections) ...[
                    _SectionTitle(title: section.title),
                    const SizedBox(height: 12),
                    _AlbumRowFirestore(albums: section.albums),
                    const SizedBox(height: 22),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Group by Month Year based on createdAt
  List<_TimelineSection> _groupAlbumsByMonth(List<QueryDocumentSnapshot> docs) {
    final Map<String, List<_AlbumFirestore>> map = {};

    for (final d in docs) {
      final data = d.data() as Map<String, dynamic>;

      final title = (data['title'] ?? data['name'] ?? 'Album').toString();
      final coverUrl = (data['coverUrl'] ?? data['thumbUrl'])?.toString();
      final folder1 = (data['folder1'] ?? data['folder'] ?? data['category'])
          ?.toString();
      final folder2 = (data['folder2'] ?? data['subfolder'])?.toString();
      final countRaw = (data['memoryCount'] ?? data['count'] ?? 0);
      final count = countRaw is int ? countRaw : int.tryParse('$countRaw') ?? 0;

      DateTime createdAt = DateTime.now();
      final ts = data['createdAt'];
      if (ts is Timestamp) createdAt = ts.toDate();

      final sectionKey = _monthYearLabel(createdAt);

      map.putIfAbsent(sectionKey, () => []);
      map[sectionKey]!.add(
        _AlbumFirestore(
          id: d.id,
          title: title,
          coverUrl: coverUrl,
          count: count,
          createdAt: createdAt,
          folder1: folder1,
          folder2: folder2,
        ),
      );
    }

    // maintain order as per stream (already desc), but keep map insertion order
    final keys = map.keys.toList();
    return keys
        .map((k) => _TimelineSection(title: k, albums: map[k]!))
        .toList();
  }

  String _monthYearLabel(DateTime dt) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  List<QueryDocumentSnapshot> _applyFilter(
    List<QueryDocumentSnapshot> docs,
    _TimelineFilterState filter,
  ) {
    final now = DateTime.now();

    DateTime? threshold;
    switch (filter.time) {
      case _TimeFilter.all:
        threshold = null;
        break;
      case _TimeFilter.recent:
        threshold = now.subtract(const Duration(days: 30));
        break;
      case _TimeFilter.week:
        threshold = now.subtract(const Duration(days: 7));
        break;
      case _TimeFilter.month:
        threshold = now.subtract(const Duration(days: 30));
        break;
    }

    final f1 = filter.folder1?.trim();
    final f2 = filter.folder2?.trim();

    final out = docs.where((d) {
      final data = d.data() as Map<String, dynamic>;

      // createdAt
      DateTime createdAt = DateTime.now();
      final ts = data['createdAt'];
      if (ts is Timestamp) createdAt = ts.toDate();
      if (threshold != null && createdAt.isBefore(threshold)) return false;

      // folder filters (optional)
      if (f1 != null && f1.isNotEmpty) {
        final a1 = (data['folder1'] ?? data['folder'] ?? data['category'])
            ?.toString()
            .trim();
        if (a1 == null || a1.toLowerCase() != f1.toLowerCase()) return false;
      }
      if (f2 != null && f2.isNotEmpty) {
        final a2 = (data['folder2'] ?? data['subfolder'])?.toString().trim();
        if (a2 == null || a2.toLowerCase() != f2.toLowerCase()) return false;
      }

      return true;
    }).toList();

    out.sort((a, b) {
      DateTime da = DateTime.now();
      DateTime db = DateTime.now();
      final tsa = (a.data() as Map<String, dynamic>)['createdAt'];
      final tsb = (b.data() as Map<String, dynamic>)['createdAt'];
      if (tsa is Timestamp) da = tsa.toDate();
      if (tsb is Timestamp) db = tsb.toDate();

      final cmp = da.compareTo(db);
      return filter.sort == _SortMode.newest ? -cmp : cmp;
    });

    return out;
  }

  Future<void> _showCreateAlbumDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _CreateAlbumDialog(),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final String filterLabel;
  final VoidCallback onFilterTap;
  final VoidCallback onCreateAlbum;

  const _SearchBar({
    required this.filterLabel,
    required this.onFilterTap,
    required this.onCreateAlbum,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 28,
      child: Row(
        children: [
          InkWell(
            onTap: onFilterTap,
            borderRadius: BorderRadius.circular(18),
            child: GlassContainer(
              radius: 18,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.filter_alt, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    filterLabel,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.expand_more,
                      color: Colors.white70, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.search, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Search your memories...',
              style: TextStyle(color: Colors.white.withOpacity(0.65)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onCreateAlbum,
            borderRadius: BorderRadius.circular(18),
            child: const GlassContainer(
              radius: 18,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.white70, size: 18),
                  SizedBox(width: 6),
                  Text('Create Album',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onFilterTap,
            borderRadius: BorderRadius.circular(18),
            child: const GlassContainer(
              radius: 18,
              padding: EdgeInsets.all(10),
              child: Icon(Icons.tune, color: Colors.white70, size: 18),
            ),
          ),

          // ✅ Profile (top-right) – keeps parity with the previous UI
          const SizedBox(width: 10),
          InkWell(
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
            borderRadius: BorderRadius.circular(18),
            child: const GlassContainer(
              radius: 18,
              padding: EdgeInsets.all(10),
              child: Icon(Icons.person_outline, color: Colors.white70, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$title  ›',
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _AlbumRowFirestore extends StatelessWidget {
  final List<_AlbumFirestore> albums;
  const _AlbumRowFirestore({required this.albums});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;

        // ✅ Target tile width (auto-adjusts to fill)
        const targetTileWidth = 210.0;

        // how many cards can fit
        final crossAxisCount = ((constraints.maxWidth + spacing) /
                (targetTileWidth + spacing))
            .floor()
            .clamp(2, 6);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: albums.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 1.35, // ✅ similar shape to your cards
          ),
          itemBuilder: (_, i) => _AlbumCardFirestore(data: albums[i]),
        );
      },
    );
  }
}


class _AlbumCardFirestore extends StatelessWidget {
  final _AlbumFirestore data;
  const _AlbumCardFirestore({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dashboard is still backed by Firestore demo albums (IDs are not Mongo ObjectIds).
        // Open the real Albums screen (Mongo + Bunny) instead of calling /api/albums/:id with a Firestore ID.
        Navigator.pushNamed(context, AppRoutes.albums);
      },
      child: GlassContainer(
        radius: 18,
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Positioned.fill(
                child: (data.coverUrl == null || data.coverUrl!.isEmpty)
                    ? Container(
                        color: Colors.white.withOpacity(0.10),
                        child: const Center(
                          child: Icon(Icons.photo_album,
                              color: Colors.white70, size: 36),
                        ),
                      )
                    : Image.network(
                        data.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.white.withOpacity(0.10),
                          child: const Center(
                            child: Icon(Icons.broken_image,
                                color: Colors.white70),
                          ),
                        ),
                      ),
              ),

              // ✅ Folder label (1-level or 2-level)
              Positioned(
                left: 10,
                top: 10,
                child: GlassContainer(
                  radius: 14,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        (data.folder1 != null && (data.folder2 == null || data.folder2!.trim().isEmpty))
                            ? Icons.folder
                            : Icons.folder_open,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        data.folderLabel,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // bottom overlay
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.0),
                        Colors.black.withOpacity(0.65),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        data.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.circle,
                              size: 8, color: Colors.white70),
                          const SizedBox(width: 6),
                          Text(
                            '${data.count} Photos',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
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

// -------------------- Create Album Dialog --------------------

class _CreateAlbumDialog extends StatefulWidget {
  const _CreateAlbumDialog();

  @override
  State<_CreateAlbumDialog> createState() => _CreateAlbumDialogState();
}

class _CreateAlbumDialogState extends State<_CreateAlbumDialog> {
  final _title = TextEditingController();
  final _folder1 = TextEditingController();
  final _folder2 = TextEditingController();
  final _coverUrl = TextEditingController();

  bool _useTwoLevels = false;
  bool _withImage = true;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _folder1.dispose();
    _folder2.dispose();
    _coverUrl.dispose();
    super.dispose();
  }

  String _picsumThumb(String seed) => 'https://picsum.photos/seed/$seed/500/350';
  String _picsumFull(String seed) => 'https://picsum.photos/seed/$seed/1200/900';

  String _seedFromTitle(String t) {
    final s = t.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return s.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : s;
  }

  Future<void> _create() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final f1 = _folder1.text.trim();
    final f2 = _folder2.text.trim();

    setState(() => _saving = true);
    try {
      final db = FirebaseFirestore.instance;
      final now = DateTime.now();
      final seed = _seedFromTitle(title);

      final String? cover = _withImage
          ? (_coverUrl.text.trim().isEmpty ? _picsumThumb(seed) : _coverUrl.text.trim())
          : null;

      final albumRef = db.collection('albums').doc();
      await albumRef.set({
        'title': title,
        'createdAt': Timestamp.fromDate(now),
        'memoryCount': _withImage ? 1 : 0,
        'coverUrl': cover,
        if (f1.isNotEmpty) 'folder1': f1,
        if (_useTwoLevels && f2.isNotEmpty) 'folder2': f2,
      });

      if (_withImage) {
        // Create 1 starter memory so the album truly has an image.
        final memRef = albumRef.collection('memories').doc();
        await memRef.set({
          'title': '$title #1',
          'description': 'Cover memory',
          'thumbUrl': cover,
          'imageUrl': _picsumFull(seed),
          'likeCount': 0,
          'createdAt': Timestamp.fromDate(now),
        });
      }

      if (mounted) Navigator.pop(context);
    } catch (_) {
      // keep UI silent; Firestore rules might block writes in demo mode
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.55)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: GlassContainer(
        radius: 22,
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Create Album',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _title,
                style: const TextStyle(color: Colors.white),
                decoration: _dec('Album title'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _folder1,
                      style: const TextStyle(color: Colors.white),
                      decoration: _dec('Folder level 1 (optional)'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GlassContainer(
                    radius: 14,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        const Text('2 levels', style: TextStyle(color: Colors.white70)),
                        const SizedBox(width: 8),
                        Switch(
                          value: _useTwoLevels,
                          onChanged: (v) => setState(() => _useTwoLevels = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_useTwoLevels) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _folder2,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('Folder level 2 (optional)'),
                ),
              ],
              const SizedBox(height: 12),
              _FilterSection(
                title: 'Album cover',
                child: Row(
                  children: [
                    _Chip(
                      text: 'With Image',
                      selected: _withImage,
                      onTap: () => setState(() => _withImage = true),
                    ),
                    const SizedBox(width: 10),
                    _Chip(
                      text: 'Without Image',
                      selected: !_withImage,
                      onTap: () => setState(() => _withImage = false),
                    ),
                  ],
                ),
              ),
              if (_withImage) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _coverUrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('Cover image URL (optional)'),
                ),
                const SizedBox(height: 6),
                Text(
                  'Leave URL empty to use a demo image automatically.',
                  style: TextStyle(color: Colors.white.withOpacity(0.60), fontSize: 12),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _create,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(_saving ? 'Creating...' : 'Create'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- Filter Overlay (unchanged) --------------------

class _FilterOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onClear;
  final _TimelineFilterState initial;
  final ValueChanged<_TimelineFilterState> onApply;

  const _FilterOverlay({
    required this.onClose,
    required this.onClear,
    required this.initial,
    required this.onApply,
  });

  @override
  State<_FilterOverlay> createState() => _FilterOverlayState();
}

class _FilterOverlayState extends State<_FilterOverlay> {
  late bool _newestFirst;
  late _TimeFilter _time;
  late TextEditingController _folder1;
  late TextEditingController _folder2;

  @override
  void initState() {
    super.initState();
    _newestFirst = widget.initial.sort == _SortMode.newest;
    _time = widget.initial.time;
    _folder1 = TextEditingController(text: widget.initial.folder1 ?? '');
    _folder2 = TextEditingController(text: widget.initial.folder2 ?? '');
  }

  @override
  void dispose() {
    _folder1.dispose();
    _folder2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Prevent render overflow on smaller heights / web resize.
    // (The overlay used a Column with min size; when content exceeds available
    // height Flutter throws: "BOTTOM OVERFLOWED BY ... PIXELS".)
    final maxHeight = MediaQuery.of(context).size.height - 170;

    return Positioned.fill(
      child: GestureDetector(
        onTap: widget.onClose,
        child: Container(
          color: Colors.black.withOpacity(0.35),
          child: GestureDetector(
            onTap: () {},
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 120, left: 16, right: 16),
                child: GlassContainer(
                  radius: 22,
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      // keep it usable on laptop heights and when the browser is resized
                      maxHeight: maxHeight.clamp(260.0, 680.0),
                      maxWidth: 980,
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.zero,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Search Filter',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: widget.onClear,
                            child: const Text('Clear'),
                          ),
                          IconButton(
                            onPressed: widget.onClose,
                            icon:
                                const Icon(Icons.close, color: Colors.white70),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      _FilterSection(
                        title: 'Sort By',
                        child: Row(
                          children: [
                            _Chip(
                              text: 'Date (Newest)',
                              selected: _newestFirst,
                              onTap: () => setState(() => _newestFirst = true),
                            ),
                            const SizedBox(width: 10),
                            _Chip(
                              text: 'Date (Oldest)',
                              selected: !_newestFirst,
                              onTap: () => setState(() => _newestFirst = false),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _FilterSection(
                        title: 'Time',
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _Chip(
                                text: 'All Time',
                                selected: _time == _TimeFilter.all,
                                onTap: () => setState(() => _time = _TimeFilter.all),
                              ),
                              const SizedBox(width: 10),
                              _Chip(
                                text: 'Recent',
                                selected: _time == _TimeFilter.recent,
                                onTap: () => setState(() => _time = _TimeFilter.recent),
                              ),
                              const SizedBox(width: 10),
                              _Chip(
                                text: 'This Week',
                                selected: _time == _TimeFilter.week,
                                onTap: () => setState(() => _time = _TimeFilter.week),
                              ),
                              const SizedBox(width: 10),
                              _Chip(
                                text: 'This Month',
                                selected: _time == _TimeFilter.month,
                                onTap: () => setState(() => _time = _TimeFilter.month),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _FilterSection(
                        title: 'Folder (Optional)',
                        child: Column(
                          children: [
                            TextField(
                              controller: _folder1,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Level 1 folder (e.g., Trips)',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.55)),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.06),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _folder2,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Level 2 folder (optional)',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.55)),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.06),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final f1 = _folder1.text.trim();
                            final f2 = _folder2.text.trim();
                            widget.onApply(
                              _TimelineFilterState(
                                sort: _newestFirst ? _SortMode.newest : _SortMode.oldest,
                                time: _time,
                                folder1: f1.isEmpty ? null : f1,
                                folder2: f2.isEmpty ? null : f2,
                              ),
                            );
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _FilterSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback? onTap;
  const _Chip({required this.text, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: GlassContainer(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check, color: Colors.white, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

// -------------------- Models --------------------

class _TimelineSection {
  final String title;
  final List<_AlbumFirestore> albums;
  const _TimelineSection({required this.title, required this.albums});
}

class _AlbumFirestore {
  final String id;
  final String title;
  final String? coverUrl;
  final int count;
  final DateTime createdAt;
  final String? folder1;
  final String? folder2;

  String get folderLabel {
    final f1 = folder1?.trim();
    final f2 = folder2?.trim();
    if (f1 == null || f1.isEmpty) return 'No Folder';
    if (f2 == null || f2.isEmpty) return f1;
    return '$f1 / $f2';
  }

  const _AlbumFirestore({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.count,
    required this.createdAt,
    required this.folder1,
    required this.folder2,
  });
}

enum _SortMode { newest, oldest }

enum _TimeFilter { all, recent, week, month }

class _TimelineFilterState {
  final _SortMode sort;
  final _TimeFilter time;
  final String? folder1;
  final String? folder2;

  const _TimelineFilterState({
    this.sort = _SortMode.newest,
    this.time = _TimeFilter.all,
    this.folder1,
    this.folder2,
  });

  String get label {
    final parts = <String>[];
    switch (time) {
      case _TimeFilter.all:
        parts.add('All Time');
        break;
      case _TimeFilter.recent:
        parts.add('Recent');
        break;
      case _TimeFilter.week:
        parts.add('This Week');
        break;
      case _TimeFilter.month:
        parts.add('This Month');
        break;
    }
    if (folder1 != null && folder1!.trim().isNotEmpty) {
      parts.add(folder1!.trim());
      if (folder2 != null && folder2!.trim().isNotEmpty) {
        parts.add(folder2!.trim());
      }
    }
    return parts.join(' • ');
  }
}
