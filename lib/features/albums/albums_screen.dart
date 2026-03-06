import 'package:flutter/material.dart';

import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/services/album_api_service.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = AlbumApiService.listRootAlbums();
  }

  void _reload() {
    setState(() => _future = AlbumApiService.listRootAlbums());
  }

  Future<void> _createAlbumDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Create Album'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
          ],
        );
      },
    );

    if (ok != true) return;

    final title = titleCtrl.text.trim();
    if (title.isEmpty) return;

    try {
      await AlbumApiService.createAlbum(
        title: title,
        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        parentId: null,
      );
      _reload();
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Albums',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _createAlbumDialog,
                  icon: const Icon(Icons.create_new_folder),
                  label: const Text('New Album'),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Pick from device/PC',
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.localMedia),
                  icon: const Icon(Icons.photo_library_outlined, color: Colors.white70),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final albums = snapshot.data!;
                  if (albums.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('No albums yet', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _createAlbumDialog,
                            icon: const Icon(Icons.create_new_folder),
                            label: const Text('Create Album'),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    itemCount: albums.length,
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 260,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.35,
                    ),
                    itemBuilder: (context, index) {
                      final a = (albums[index] as Map).cast<String, dynamic>();
                      final id = (a['_id'] ?? '').toString();
                      final title = (a['title'] ?? 'Album').toString();

                      return GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.albumDetail,
                            arguments: {
                              'albumId': id,
                              'albumTitle': title,
                            },
                          );
                        },
                        child: GlassContainer(
                          radius: 18,
                          padding: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.10),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.photo_album, color: Colors.white70, size: 44),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
