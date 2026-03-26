import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import '../../layout/main_app_shell.dart';
import '../../models/timeline_album_summary.dart';
import '../../routes/app_routes.dart';
import '../../services/local_album_service.dart';
import '../../services/local_photo_store.dart';
import '../../core/services/user_api_service.dart';
import '../../services/auth_service.dart';
import '../timeline/album_detail_screen.dart';
import '../timeline/timeline_photo_image.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<TimelineAlbumSummary> _albums = const <TimelineAlbumSummary>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _loading = true);
    try {
      await LocalPhotoStore.init();
      final albums = LocalAlbumService.listAlbumSummaries();
      if (!mounted) return;
      setState(() {
        _albums = albums;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _renameUser() async {
    final user = FirebaseAuth.instance.currentUser;
    final nextName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A0E2A),
      builder: (context) {
        return _EditNameSheet(
          initialName: (user?.displayName ?? '').trim(),
        );
      },
    );

    if (nextName == null || nextName.isEmpty) return;
    try {
      await user?.updateDisplayName(nextName.trim());
      await UserApiService.updateMe(name: nextName.trim());
      await FirebaseAuth.instance.currentUser?.reload();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save username: $e')),
      );
    }
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
    ).then((_) => _loadProfileData());
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : (user?.email?.split('@').first ?? 'User');
    final email = (user?.email ?? '').trim();

    final rootAlbumCount =
        _albums.where((album) => album.album.level == 1).length;
    final subAlbumCount =
        _albums.where((album) => album.album.level >= 2).length;
    final imageCount =
        _albums.fold<int>(0, (total, album) => total + album.photoCount);

    return MainAppShell(
      currentRoute: AppRoutes.profile,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileHeader(
                displayName: displayName,
                email: email,
                photoUrl: (user?.photoURL ?? '').trim(),
                onEditName: _renameUser,
              ),
              const SizedBox(height: 18),
              _StatsRow(
                rootAlbumCount: rootAlbumCount,
                subAlbumCount: subAlbumCount,
                imageCount: imageCount,
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Photo Highlights',
                onViewAll: () => Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.dashboard,
                ),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_albums.isEmpty)
                const _ProfileEmptyAlbums()
              else
                _AlbumHighlightsList(
                  albums: _albums.take(6).toList(),
                  onAlbumTap: _openAlbum,
                ),
              const SizedBox(height: 26),
              const _ProfileMenu(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String email;
  final String photoUrl;
  final VoidCallback onEditName;

  const _ProfileHeader({
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.onEditName,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initials(displayName.isNotEmpty ? displayName : email);
    return GlassContainer(
      radius: 28,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: ClipOval(
              child: photoUrl.isNotEmpty
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _ProfileAvatarFallback(initials: initials),
                    )
                  : _ProfileAvatarFallback(initials: initials),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit name',
                      onPressed: onEditName,
                      icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                    ),
                  ],
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.64),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String value) {
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

class _ProfileAvatarFallback extends StatelessWidget {
  final String initials;

  const _ProfileAvatarFallback({
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
          fontSize: 20,
        ),
      ),
    );
  }
}

class _EditNameSheet extends StatefulWidget {
  final String initialName;

  const _EditNameSheet({
    required this.initialName,
  });

  @override
  State<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends State<_EditNameSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    FocusScope.of(context).unfocus();
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Name',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.done,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your name',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int rootAlbumCount;
  final int subAlbumCount;
  final int imageCount;

  const _StatsRow({
    required this.rootAlbumCount,
    required this.subAlbumCount,
    required this.imageCount,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          _StatItem(value: '$rootAlbumCount', label: 'Albums'),
          const _Divider(),
          _StatItem(value: '$subAlbumCount', label: 'Sub Albums'),
          const _Divider(),
          _StatItem(value: '$imageCount', label: 'Images'),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;

  const _SectionHeader({required this.title, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: onViewAll,
          borderRadius: BorderRadius.circular(12),
          child: const Row(
            children: [
              Text('View All', style: TextStyle(color: Colors.white60)),
              SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18, color: Colors.white54),
            ],
          ),
        ),
      ],
    );
  }
}

class _AlbumHighlightsList extends StatelessWidget {
  final List<TimelineAlbumSummary> albums;
  final ValueChanged<TimelineAlbumSummary> onAlbumTap;

  const _AlbumHighlightsList({
    required this.albums,
    required this.onAlbumTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: albums
          .map(
            (album) {
              final cover = album.coverPhoto;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onAlbumTap(album),
                  child: GlassContainer(
                    radius: 20,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 76,
                          height: 76,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: buildTimelinePhotoImage(
                              url: cover?.serverUrl,
                              thumbUrl: cover?.thumbUrl,
                              localPath: cover?.localPath ?? '',
                              localThumbnailPath: cover?.localThumbnailPath,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                album.album.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${album.photoCount} images',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.66),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Level ${album.album.level}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.48),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white54),
                      ],
                    ),
                  ),
                ),
              );
            },
          )
          .toList(),
    );
  }
}

class _ProfileEmptyAlbums extends StatelessWidget {
  const _ProfileEmptyAlbums();

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      radius: 20,
      padding: const EdgeInsets.all(18),
      child: Text(
        'No album highlights yet. Create albums from the timeline and they will appear here.',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.72),
          height: 1.4,
        ),
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MenuTile(
          icon: Icons.person_outline,
          title: 'Account Settings',
          onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
        ),
        _MenuTile(
          icon: Icons.notifications_none,
          title: 'Notification Settings',
          onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
        ),
        _MenuTile(
          icon: Icons.help_outline,
          title: 'Help & Support',
          onTap: () {},
        ),
        _MenuTile(
          icon: Icons.power_settings_new,
          title: 'Sign Out',
          danger: true,
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            await AuthService.logout();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (_) => false,
              );
            }
          },
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool danger;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.redAccent : Colors.white.withValues(alpha: 0.88);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: color, fontSize: 15),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.34),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
