import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/widgets/glass_container.dart';
import '../../layout/main_app_shell.dart';
import '../../models/album_model.dart';
import '../../models/timeline_album_summary.dart';
import '../../routes/app_routes.dart';
import '../../services/local_album_service.dart';
import '../../services/local_photo_store.dart';
import 'album_detail_screen.dart';
import 'album_grid.dart';
import 'timeline_search_filter_screen.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  List<TimelineAlbumSummary> _albums = const <TimelineAlbumSummary>[];
  bool _loading = false;
  bool _disposed = false;

  void _safeSetState(VoidCallback fn) {
    if (_disposed || !mounted) {
      debugPrint('[UI] mounted check failed (TimelineScreen)');
      return;
    }
    setState(fn);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startHeavyWork());
  }

  Future<void> _startHeavyWork() async {
    if (_disposed || !mounted) return;
    await _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    if (_disposed) return;
    _safeSetState(() {
      _loading = true;
    });

    try {
      await LocalPhotoStore.init();
      if (_disposed) return;
      final albums = LocalAlbumService.listRootAlbumSummaries();
      if (_disposed) return;
      _safeSetState(() {
        _albums = albums;
      });
    } catch (e) {
      if (_disposed || !mounted) return;
      _safeSetState(() {
        _albums = const <TimelineAlbumSummary>[];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load local albums: $e')),
      );
    } finally {
      if (!_disposed && mounted) {
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

    if (created != true || _disposed || !mounted) return;

    try {
      await LocalPhotoStore.init();
    } catch (e) {
      if (_disposed || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open local library: $e')),
      );
      return;
    }

    late final TimelineAlbum album;
    try {
      album = LocalAlbumService.createAlbum(titleCtrl.text.trim());
    } catch (e) {
      if (_disposed || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create album: $e')),
      );
      return;
    }
    if (_disposed || !mounted) return;
    await _loadAlbums();
    _openAlbum(
      TimelineAlbumSummary(album: album, photos: const []),
    );
  }

  Future<void> _openSearchAndFilter() async {
    final selected = await Navigator.push<TimelineAlbumSummary>(
      context,
      MaterialPageRoute(
        builder: (_) => const TimelineSearchFilterScreen(),
      ),
    );
    if (_disposed || !mounted || selected == null) return;
    _openAlbum(selected);
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
    ).then((_) {
      if (_disposed || !mounted) return;
      _loadAlbums();
    });
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
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: _TimelineTopBar(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: _TimelineHeader(
              albumCount: albumCount,
              photoCount: photoCount,
              pendingCount: pendingCount,
              onRefresh: _loadAlbums,
              onCreateAlbum: _createAlbum,
              onOpenSearch: _openSearchAndFilter,
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

class _TimelineTopBar extends StatelessWidget {
  const _TimelineTopBar();

  Future<void> _openMenuSheet(BuildContext context) async {
    final selectedRoute = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1A0E2A),
      builder: (context) {
        return const SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 14),
                _MenuRouteTile(
                  icon: Icons.timeline,
                  label: 'Timeline',
                  route: AppRoutes.dashboard,
                ),
                _MenuRouteTile(
                  icon: Icons.card_giftcard,
                  label: 'Gift',
                  route: AppRoutes.gifts,
                ),
                _MenuRouteTile(
                  icon: Icons.design_services,
                  label: 'Service',
                  route: AppRoutes.service,
                ),
                _MenuRouteTile(
                  icon: Icons.menu_book,
                  label: 'Learn',
                  route: AppRoutes.learn,
                ),
                _MenuRouteTile(
                  icon: Icons.lock_outline,
                  label: 'Vault',
                  route: AppRoutes.vault,
                ),
                _MenuRouteTile(
                  icon: Icons.settings,
                  label: 'Settings',
                  route: AppRoutes.settings,
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedRoute == null || !context.mounted) return;
    if (ModalRoute.of(context)?.settings.name == selectedRoute) return;
    Navigator.pushReplacementNamed(context, selectedRoute);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = (user?.photoURL ?? '').trim();
    final displayName = (user?.displayName ?? '').trim();
    final email = (user?.email ?? '').trim();
    final seed = displayName.isNotEmpty ? displayName : email;
    final initials = _initialsFrom(seed);

    return Row(
      children: [
        _TopBarButton(
          icon: Icons.menu,
          onTap: () => _openMenuSheet(context),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: photoUrl.isNotEmpty
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _ProfileFallback(initials: initials),
                    )
                  : _ProfileFallback(initials: initials),
            ),
          ),
        ),
      ],
    );
  }

  static String _initialsFrom(String value) {
    final words = value
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (words.isEmpty) return 'U';
    if (words.length == 1) {
      final text = words.first.trim();
      return text.substring(0, text.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${words.first[0]}${words[1][0]}'.toUpperCase();
  }
}

class _TimelineHeader extends StatelessWidget {
  final int albumCount;
  final int photoCount;
  final int pendingCount;
  final VoidCallback onRefresh;
  final VoidCallback onCreateAlbum;
  final VoidCallback onOpenSearch;

  const _TimelineHeader({
    required this.albumCount,
    required this.photoCount,
    required this.pendingCount,
    required this.onRefresh,
    required this.onCreateAlbum,
    required this.onOpenSearch,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      radius: 30,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
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
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _HeaderIconButton(
                icon: Icons.tune,
                tooltip: 'Filter',
                onTap: onOpenSearch,
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                icon: Icons.refresh,
                tooltip: 'Refresh',
                onTap: onRefresh,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeaderChip(
                icon: Icons.folder_open_outlined,
                label: '$albumCount albums',
              ),
              _HeaderChip(
                icon: Icons.image_outlined,
                label: '$photoCount images',
              ),
              if (pendingCount > 0)
                _HeaderChip(
                  icon: Icons.cloud_upload_outlined,
                  label: '$pendingCount pending',
                  color: const Color(0xFFF2C66D),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: onCreateAlbum,
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('Create Album'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopBarButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _ProfileFallback extends StatelessWidget {
  final String initials;

  const _ProfileFallback({
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7B61FF), Color(0xFF5030B5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _MenuRouteTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const _MenuRouteTile({
    required this.icon,
    required this.label,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.white),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: () => Navigator.pop(context, route),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _HeaderChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: chipColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: chipColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
