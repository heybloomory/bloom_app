import 'package:flutter/material.dart';
import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';
import '../albums/album_detail_screen.dart';


class SharedMemoriesScreen extends StatefulWidget {
  const SharedMemoriesScreen({super.key});

  @override
  State<SharedMemoriesScreen> createState() => _SharedMemoriesScreenState();
}

class _SharedMemoriesScreenState extends State<SharedMemoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainAppShell(
        currentRoute: AppRoutes.sharedMemories,
        // title: 'Shared Memories',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabs
          Material(
            color: Colors.transparent,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              tabs: const [
                Tab(text: 'Shared with me'),
                Tab(text: 'Shared by me'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _MemoryGrid(tabLabel: 'Shared with me'),
                _MemoryGrid(tabLabel: 'Shared by me'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryGrid extends StatelessWidget {
  final String tabLabel;

  const _MemoryGrid({required this.tabLabel});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1200 ? 5 : width > 800 ? 4 : 3;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        itemCount: 12,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemBuilder: (context, index) {
          return _SharedMemoryCard(
            title: '$tabLabel Memory ${index + 1}',
          );
        },
      ),
    );
  }
}

class _SharedMemoryCard extends StatelessWidget {
  final String title;

  const _SharedMemoryCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
onTap: () {
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => const AlbumDetailScreen(albumId: 'shared'),
  ),
);

},


        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: const Icon(
                    Icons.image,
                    size: 48,
                    color: Colors.white70,
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
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
