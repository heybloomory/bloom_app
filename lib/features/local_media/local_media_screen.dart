import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../core/debug/timeline_crash_debug.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'platform/desktop_support.dart' as desk;

/// Local Media Manager
/// - Web: user picks multiple images (browser security can't read folders by path)
/// - Desktop (mac/windows/linux): user selects a folder path, app remembers it, timeline shows images from that folder
/// - Mobile (android/ios): user selects a gallery Album, app remembers it, timeline shows images from that album
///
/// Albums (DB albums) are app-level albums stored locally (SharedPreferences) as a list of media keys.
/// Media keys:
///   - file:/abs/path/to/image.jpg
///   - asset:<assetId>
///   - web:<index>  (only valid for current session)
class LocalMediaScreen extends StatefulWidget {
  const LocalMediaScreen({super.key});

  @override
  State<LocalMediaScreen> createState() => _LocalMediaScreenState();
}

enum _SourceType { webFiles, desktopFolder, mobileAlbum }

class _LocalMediaScreenState extends State<LocalMediaScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabs;

  // Source selection
  _SourceType? _sourceType;
  String? _desktopFolderPath;
  String? _mobileAlbumId;

  /// True after Photos permission was denied or revoked (mobile gallery).
  bool _photosPermissionRevoked = false;

  // Timeline data
  bool _loadingTimeline = false;
  String? _timelineError;

  // Web picked files (session-only)
  List<PlatformFile> _webPicked = [];

  // Desktop files
  List<_DesktopImageFile> _desktopFiles = [];

  // Mobile assets
  AssetPathEntity? _mobileAlbum;
  List<AssetEntity> _mobileAssets = [];
  int _mobilePage = 0;
  bool _mobileHasMore = true;
  bool _mobilePaging = false;

  /// Prevents overlapping timeline refresh scans.
  bool _timelineScanInProgress = false;

  bool _disposed = false;

  // Selection
  final Set<String> _selectedKeys = <String>{};

  // DB albums
  final Map<String, List<String>> _dbAlbums = {}; // albumName -> mediaKeys

  static const _prefsKeySourceType = 'local_media_source_type_v1';
  static const _prefsKeyDesktopPath = 'local_media_desktop_folder_v1';
  static const _prefsKeyMobileAlbumId = 'local_media_mobile_album_id_v1';
  static const _prefsKeyDbAlbums = 'local_media_db_albums_v1';

  void _log(String msg) {
    debugPrint('[LocalMedia] $msg');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startHeavyWork();
    });
  }

  /// After first frame: prefs + timeline scan (PhotoManager / folder listing).
  Future<void> _startHeavyWork() async {
    if (_disposed || !mounted) return;
    try {
      await _loadPrefsAndInit();
    } catch (e, st) {
      debugPrint('[LocalMedia] _startHeavyWork error: $e\n$st');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposed = true;
    _tabs.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_recheckPhotoPermissionOnResume());
    }
  }

  /// On resume: re-check gallery permission; stop scanning if revoked.
  Future<void> _recheckPhotoPermissionOnResume() async {
    if (_disposed || !mounted || kIsWeb || _isDesktop()) return;
    if ((_sourceType ?? _inferBestSourceType(null)) != _SourceType.mobileAlbum) {
      return;
    }
    try {
      final perm = await PhotoManager.requestPermissionExtend();
      if (!perm.isAuth) {
        _handlePhotosPermissionRevoked();
      } else {
        if (_photosPermissionRevoked) {
          _safeSetState(() => _photosPermissionRevoked = false);
        }
        if (_mobileAlbumId != null && _mobileAlbumId!.trim().isNotEmpty) {
          await _loadMobileAlbum();
        }
      }
    } catch (e, st) {
      debugPrint('[LocalMedia] permission recheck: $e\n$st');
    }
  }

  void _handlePhotosPermissionRevoked() {
    _timelineScanInProgress = false;
    _safeSetState(() {
      _photosPermissionRevoked = true;
      _timelineError = null;
      _mobileAssets = [];
      _mobileAlbum = null;
      _mobileHasMore = false;
      _mobilePaging = false;
    });
  }

  void _safeSetState(VoidCallback fn) {
    if (_disposed || !mounted) {
      debugPrint('[UI] mounted check failed (LocalMedia)');
      return;
    }
    setState(fn);
  }

  Future<void> _loadPrefsAndInit() async {
    _log('db load start');
    final prefs = await SharedPreferences.getInstance();

    // Load albums
    final albumsJson = prefs.getString(_prefsKeyDbAlbums);
    if (albumsJson != null && albumsJson.trim().isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(albumsJson);
        for (final entry in decoded.entries) {
          final v = entry.value;
          if (v is List) {
            _dbAlbums[entry.key] = v.map((e) => e.toString()).toList();
          }
        }
      } catch (_) {}
    }

    // Load source
    final st = prefs.getString(_prefsKeySourceType);
    _desktopFolderPath = prefs.getString(_prefsKeyDesktopPath);
    _mobileAlbumId = prefs.getString(_prefsKeyMobileAlbumId);

    _sourceType = _inferBestSourceType(st);
    _log('db load done; source=$_sourceType');

    if (mounted && !_disposed) setState(() {});
    if (_disposed) return;
    await _refreshTimeline();
  }

  _SourceType _inferBestSourceType(String? stored) {
    if (kIsWeb) return _SourceType.webFiles;

    // Desktop platforms (folder by path)
    if (_isDesktop()) return _SourceType.desktopFolder;

    // Mobile
    return _SourceType.mobileAlbum;
  }

  bool _isDesktop() {
    if (kIsWeb) return false;
    return desk.isDesktopPlatform;
  }

  Future<void> _saveSourcePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeySourceType, (_sourceType ?? _SourceType.webFiles).name);
    if (_desktopFolderPath != null) await prefs.setString(_prefsKeyDesktopPath, _desktopFolderPath!);
    if (_mobileAlbumId != null) await prefs.setString(_prefsKeyMobileAlbumId, _mobileAlbumId!);
  }

  Future<void> _saveDbAlbums() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyDbAlbums, jsonEncode(_dbAlbums));
  }

  Future<void> _refreshTimeline() async {
    if (_timelineScanInProgress) {
      debugPrint('[Scan] skipped (already in progress)');
      return;
    }
    _timelineScanInProgress = true;
    debugPrint('[Scan] started');
    logScanStart('LocalMedia._refreshTimeline');
    if (!mounted || _disposed) {
      _timelineScanInProgress = false;
      debugPrint('[Scan] finished');
      logScanEnd('LocalMedia._refreshTimeline aborted (not mounted)');
      return;
    }
    setState(() {
      _loadingTimeline = true;
      _timelineError = null;
      _selectedKeys.clear();
    });

    try {
      _log('timeline scan start; source=$_sourceType');
      if (kIsWeb) {
        // Web: only show picked files; we can't load by path without user picking again.
        // Don't auto-prompt; show CTA.
      } else if (_isDesktop()) {
        await _loadDesktopFolder();
      } else {
        await _loadMobileAlbum();
      }
      _log('timeline scan end');
    } catch (e, stack) {
      logTimelineLoadCrash('LocalMedia._refreshTimeline', e, stack);
      _log('Timeline crash: $e\n$stack');
      if (mounted && !_disposed) {
        setState(() {
          _timelineError = e.toString();
        });
      } else {
        _timelineError = e.toString();
      }
    } finally {
      _timelineScanInProgress = false;
      debugPrint('[Scan] finished');
      logScanEnd('LocalMedia._refreshTimeline');
      if (mounted && !_disposed) {
        setState(() => _loadingTimeline = false);
      }
    }
  }

  // -------------------- WEB --------------------
  Future<void> _pickWebImages() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: true, // required for web preview
    );
    if (result == null) return;

    if (!mounted || _disposed) return;
    setState(() {
      _webPicked = result.files.where((f) => f.bytes != null).toList();
      _selectedKeys.clear();
    });
  }

  // -------------------- DESKTOP --------------------
  Future<void> _chooseDesktopFolder() async {
    final path = await desk.pickDirectoryPath();
    if (path == null) return;

    if (!mounted || _disposed) return;
    setState(() {
      _desktopFolderPath = path;
      _selectedKeys.clear();
    });

    _sourceType = _SourceType.desktopFolder;
    await _saveSourcePrefs();
    await _loadDesktopFolder();
  }

  Future<void> _loadDesktopFolder() async {
    if (_desktopFolderPath == null || _desktopFolderPath!.trim().isEmpty) {
      _safeSetState(() => _desktopFiles = []);
      return;
    }
    final files = await desk.listImageFilesInDir(_desktopFolderPath!);
    if (_disposed || !mounted) return;
    final mapped =
        files.map((f) => _DesktopImageFile(path: f.path, modified: f.modified)).toList();
    debugPrint('[Memory] batch processed count=${mapped.length} (desktop folder)');
    _safeSetState(() => _desktopFiles = mapped);
  }

  // -------------------- MOBILE --------------------
  Future<void> _chooseMobileAlbum() async {
    final PermissionState perm = await PhotoManager.requestPermissionExtend();
    _log('permission status chooseMobileAlbum=$perm');
    if (!perm.isAuth) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission denied. Please allow Photos access.')),
      );
      setState(() {
        _photosPermissionRevoked = true;
        _timelineError = null;
      });
      return;
    }
    if (mounted && !_disposed) {
      setState(() => _photosPermissionRevoked = false);
    }

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );

    if (!mounted) return;

    final chosen = await showModalBottomSheet<AssetPathEntity>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView.builder(
          itemCount: paths.length,
          itemBuilder: (_, i) {
            final p = paths[i];
            return ListTile(
              title: Text(p.name),
              subtitle: FutureBuilder<int>(
                future: p.assetCountAsync,
                builder: (_, snap) => Text('Items: ${snap.data ?? 0}'),
              ),
              onTap: () => Navigator.pop(context, p),
            );
          },
        ),
      ),
    );

    if (chosen == null) return;

    if (!mounted || _disposed) return;
    setState(() {
      _mobileAlbum = chosen;
      _mobileAlbumId = chosen.id;
      _mobileAssets = [];
      _mobilePage = 0;
      _mobileHasMore = true;
      _selectedKeys.clear();
    });

    _sourceType = _SourceType.mobileAlbum;
    await _saveSourcePrefs();
    await _loadMoreMobileAssets(reset: true);
  }

  Future<void> _loadMobileAlbum() async {
    final PermissionState perm = await PhotoManager.requestPermissionExtend();
    _log('permission status loadMobileAlbum=$perm');
    if (!perm.isAuth) {
      if (mounted && !_disposed) {
        setState(() {
          _photosPermissionRevoked = true;
          _timelineError = null;
          _mobileAssets = [];
          _mobileAlbum = null;
          _mobileHasMore = false;
        });
      }
      return;
    }
    if (mounted && !_disposed) {
      setState(() => _photosPermissionRevoked = false);
    }

    // If we don't have a selected album, do nothing; user will pick.
    if (_mobileAlbumId == null || _mobileAlbumId!.trim().isEmpty) return;

    // Resolve album by id
    final paths = await PhotoManager.getAssetPathList(type: RequestType.image);
    final found = paths.where((p) => p.id == _mobileAlbumId).toList();
    if (found.isEmpty) return;

    _mobileAlbum = found.first;
    await _loadMoreMobileAssets(reset: true);
  }

  Future<void> _loadMoreMobileAssets({bool reset = false}) async {
    if (_mobileAlbum == null) return;
    if (_mobilePaging) return;
    if (!_mobileHasMore && !reset) return;
    if (_timelineScanInProgress && !reset) return;

    if (!mounted || _disposed) return;
    setState(() => _mobilePaging = true);

    try {
      if (reset) {
        _mobilePage = 0;
        _mobileHasMore = true;
        _mobileAssets = [];
      }

      /// Strict page size for memory / UI responsiveness (50–100 range).
      const pageSize = 80;
      final raw = await _mobileAlbum!.getAssetListPaged(
        page: _mobilePage,
        size: pageSize,
      );
      if (_disposed) return;

      final items = <AssetEntity>[];
      for (final a in raw) {
        if (!_validateGalleryAsset(a)) continue;
        items.add(a);
      }

      if (raw.isEmpty) {
        _mobileHasMore = false;
      } else {
        if (items.isNotEmpty) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
        if (_disposed || !mounted) return;
        _mobileAssets = [..._mobileAssets, ...items];
        _mobilePage += 1;
        debugPrint(
          '[Memory] batch processed count=${items.length} total=${_mobileAssets.length}',
        );
        if (raw.length < pageSize) _mobileHasMore = false;
      }
      _log('mobile assets loaded size=${_mobileAssets.length}');
    } catch (e, stack) {
      logTimelineLoadCrash('LocalMedia._loadMoreMobileAssets', e, stack);
      _log('Timeline crash: $e\n$stack');
      if (mounted && !_disposed) {
        setState(() {
          _timelineError = 'Failed to load media.';
        });
      }
    } finally {
      if (mounted && !_disposed) {
        setState(() => _mobilePaging = false);
      }
    }
  }


  // -------------------- SELECTION + ALBUMS --------------------
  Future<void> _createDbAlbum() async {
    final name = await _promptText('Create Album', 'Album name');
    if (name == null) return;
    final albumName = name.trim();
    if (albumName.isEmpty) return;
    if (_dbAlbums.containsKey(albumName)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Album already exists')));
      return;
    }
    setState(() => _dbAlbums[albumName] = []);
    await _saveDbAlbums();
  }

  Future<void> _addSelectedToAlbum() async {
    if (_selectedKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select images first')));
      return;
    }
    if (_dbAlbums.isEmpty) {
      await _createDbAlbum();
      if (_dbAlbums.isEmpty) return;
    }

    final album = await _pickAlbumDialog();
    if (album == null) return;

    final list = _dbAlbums[album] ?? <String>[];
    final before = list.length;
    for (final k in _selectedKeys) {
      if (!list.contains(k)) list.add(k);
    }
    _dbAlbums[album] = list;

    await _saveDbAlbums();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${list.length - before} items to "$album"')),
    );
  }

  Future<String?> _pickAlbumDialog() async {
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Select Album'),
        content: SizedBox(
          width: 420,
          child: ListView(
            shrinkWrap: true,
            children: _dbAlbums.keys.map((a) {
              final count = _dbAlbums[a]?.length ?? 0;
              return ListTile(
                title: Text(a),
                subtitle: Text('$count items'),
                onTap: () => Navigator.pop(context, a),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () async {
            Navigator.pop(context);
            await _createDbAlbum();
          }, child: const Text('New Album')),
        ],
      ),
    );
  }

  Future<String?> _promptText(String title, String hint) async {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('Save')),
        ],
      ),
    );
  }

  // -------------------- UI --------------------
  /// Banner when gallery access was denied or revoked after app resume.
  Widget? _buildPhotosPermissionBanner() {
    if (!_photosPermissionRevoked || kIsWeb || _isDesktop()) return null;
    return Material(
      color: const Color(0xFFB45309).withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.photo_library_outlined, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Photos permission required',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await PhotoManager.openSetting();
                } catch (e) {
                  debugPrint('[LocalMedia] openSetting: $e');
                }
              },
              child: const Text('Settings', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    logUiBuild('LocalMediaScreen');
    final permissionBanner = _buildPhotosPermissionBanner();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (permissionBanner != null) permissionBanner,
            _headerBar(),
            TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'Timeline'),
                Tab(text: 'Albums'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _timelineTab(),
                  _albumsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerBar() {
    final sourceLabel = kIsWeb
        ? 'Web Files'
        : _isDesktop()
            ? (_desktopFolderPath == null ? 'No Folder' : 'Folder: ${_desktopFolderPath!.split(desk.pathSeparator).last}')
            : (_mobileAlbum == null ? 'No Album' : 'Album: ${_mobileAlbum!.name}');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          const Text('Local Media', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(sourceLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _createDbAlbum,
            icon: const Icon(Icons.create_new_folder_outlined, size: 18),
            label: const Text('New Album'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _addSelectedToAlbum,
            icon: const Icon(Icons.playlist_add, size: 18),
            label: Text('Add (${_selectedKeys.length})'),
          ),
        ],
      ),
    );
  }

  Widget _timelineTab() {
    if (_loadingTimeline) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Scanning photos...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    if (_timelineError != null) {
      return Center(child: Text(_timelineError!));
    }

    if (kIsWeb) {
      return _webTimeline();
    }

    if (_isDesktop()) {
      return _desktopTimeline();
    }

    return _mobileTimeline();
  }

  Widget _webTimeline() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _pickWebImages,
                icon: const Icon(Icons.upload_file),
                label: const Text('Pick Images'),
              ),
              const SizedBox(width: 12),
              Text('Picked: ${_webPicked.length}'),
            ],
          ),
        ),
        Expanded(
          child: _webPicked.isEmpty
              ? const Center(child: Text('Pick images to show them in timeline.'))
              : _grid(
                  itemCount: _webPicked.length,
                  itemBuilder: (_, i) {
                    final f = _webPicked[i];
                    final key = 'web:$i';
                    final selected = _selectedKeys.contains(key);
                    return _thumb(
                      selected: selected,
                      onTap: () => _toggleSelect(key),
                      child: Image.memory(
                        f.bytes!,
                        fit: BoxFit.cover,
                        cacheWidth: 250,
                        cacheHeight: 250,
                        errorBuilder: (_, __, ___) =>
                            const Center(child: Icon(Icons.broken_image_outlined)),
                      ),
                      label: f.name,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _desktopTimeline() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _chooseDesktopFolder,
                icon: const Icon(Icons.folder_open),
                label: const Text('Select Folder'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _desktopFolderPath ?? 'No folder selected',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loadDesktopFolder,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: _desktopFiles.isEmpty
              ? const Center(child: Text('Select a folder to show images in timeline.'))
              : _grid(
                  itemCount: _desktopFiles.length,
                  itemBuilder: (_, i) {
                    final f = _desktopFiles[i];
                    final key = 'file:${f.path}';
                    final selected = _selectedKeys.contains(key);
                    final imageChild = desk.fileExists(f.path)
                        ? desk.buildFileImageWidget(f.path)
                        : const Center(child: Icon(Icons.broken_image_outlined));
                    return _thumb(
                      selected: selected,
                      onTap: () => _toggleSelect(key),
                      child: imageChild,
                      label: _basename(f.path),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _mobileTimeline() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _chooseMobileAlbum,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Select Album'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _mobileAlbum == null ? 'No album selected' : _mobileAlbum!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: () => _loadMoreMobileAssets(reset: true),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        if (_mobilePaging)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _mobileAssets.isEmpty
                        ? 'Scanning photos...'
                        : 'Processing ${_mobileAssets.length} photos...',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: _mobileAlbum == null
              ? const Center(child: Text('Select an album to show timeline.'))
              : _mobileAssets.isEmpty && !_mobilePaging
                  ? const Center(child: Text('No media found in selected album.'))
              : NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.pixels > n.metrics.maxScrollExtent - 600) {
                      _loadMoreMobileAssets();
                    }
                    return false;
                  },
                  child: _grid(
                    itemCount: _mobileAssets.length + (_mobilePaging ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= _mobileAssets.length) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final a = _mobileAssets[i];
                      if (a.id.trim().isEmpty) {
                        return const Center(child: Icon(Icons.broken_image_outlined));
                      }
                      final key = 'asset:${a.id}';
                      final selected = _selectedKeys.contains(key);
                      return _thumb(
                        selected: selected,
                        onTap: () => _toggleSelect(key),
                        child: _MobileSafeThumbnail(asset: a),
                        label: '',
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _albumsTab() {
    if (_dbAlbums.isEmpty) {
      return Center(
        child: ElevatedButton.icon(
          onPressed: _createDbAlbum,
          icon: const Icon(Icons.create_new_folder_outlined),
          label: const Text('Create your first album'),
        ),
      );
    }

    final names = _dbAlbums.keys.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: names.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final name = names[i];
        final count = _dbAlbums[name]?.length ?? 0;
        return ListTile(
          title: Text(name),
          subtitle: Text('$count items'),
          trailing: IconButton(
            tooltip: 'Delete album',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await _confirm('Delete "$name"?');
              if (!ok) return;
              setState(() => _dbAlbums.remove(name));
              await _saveDbAlbums();
            },
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => _DbAlbumDetailScreen(
              albumName: name,
              keys: List<String>.from(_dbAlbums[name] ?? const []),
              resolveThumb: _resolveThumbWidget,
              onRemoveKey: (k) async {
                final list = _dbAlbums[name] ?? <String>[];
                list.remove(k);
                _dbAlbums[name] = list;
                await _saveDbAlbums();
                if (mounted) setState(() {});
              },
            )),
          ),
        );
      },
    );
  }

  Future<bool> _confirm(String msg) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );
    return r ?? false;
  }

  void _toggleSelect(String key) {
    setState(() {
      if (_selectedKeys.contains(key)) {
        _selectedKeys.remove(key);
      } else {
        _selectedKeys.add(key);
      }
    });
  }

  Widget _grid({required int itemCount, required IndexedWidgetBuilder itemBuilder}) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }

  Widget _thumb({
    required bool selected,
    required VoidCallback onTap,
    required Widget child,
    required String label,
  }) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: child,
          ),
          if (selected)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(width: 3, color: Colors.lightGreenAccent),
              ),
            ),
          if (label.isNotEmpty)
            Positioned(
              left: 6,
              right: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _resolveThumbWidget(String key) {
    if (key.startsWith('file:')) {
      final path = key.substring('file:'.length);
      return desk.fileExists(path)
          ? desk.buildFileImageWidget(path)
          : const Center(child: Icon(Icons.broken_image_outlined));
    }
    if (key.startsWith('asset:')) {
      final id = key.substring('asset:'.length);
      // Try to resolve asset
      return FutureBuilder<AssetEntity?>(
        future: AssetEntity.fromId(id),
        builder: (_, snap) {
          final a = snap.data;
          if (a == null) return const Center(child: Icon(Icons.broken_image_outlined));
          if (!_validateGalleryAsset(a)) {
            return const Center(child: Icon(Icons.broken_image_outlined));
          }
          return _MobileSafeThumbnail(asset: a);
        },
      );
    }
    if (key.startsWith('web:')) {
      // Only valid for current session; map by index
      final idx = int.tryParse(key.substring('web:'.length));
      if (idx == null || idx < 0 || idx >= _webPicked.length) {
        return const Center(child: Icon(Icons.info_outline));
      }
      final bytes = _webPicked[idx].bytes;
      if (bytes == null) return const Center(child: Icon(Icons.info_outline));
      return Image.memory(bytes, fit: BoxFit.cover);
    }
    return const Center(child: Icon(Icons.image_not_supported_outlined));
  }

  String _basename(String path) {
    final parts = path.split(desk.pathSeparator);
    return parts.isEmpty ? path : parts.last;
  }
}

class _DesktopImageFile {
  final String path;
  final DateTime modified;
  _DesktopImageFile({required this.path, required this.modified});
}

/// Shared validation for gallery rows (logging uses [Scan] prefix).
bool _validateGalleryAsset(AssetEntity? asset) {
  if (asset == null) {
    debugPrint('[Scan] skipped invalid asset (null)');
    return false;
  }
  try {
    if (asset.id.trim().isEmpty) {
      debugPrint('[Scan] skipped invalid asset (empty id)');
      return false;
    }
    if (asset.type != AssetType.image) {
      debugPrint('[Scan] skipped invalid asset (non-image type)');
      return false;
    }
    final _ = asset.createDateTime;
    return true;
  } catch (e) {
    debugPrint('[Scan] skipped invalid asset: $e');
    return false;
  }
}

/// Max thumbnail edge ~250px; single attempt (used by retry helper).
Future<Uint8List?> _safeThumbnailBytesOnce(AssetEntity asset) async {
  try {
    final bytes =
        await asset.thumbnailDataWithSize(const ThumbnailSize(250, 250));
    if (bytes == null || bytes.isEmpty) return null;
    return bytes;
  } catch (e, st) {
    logThumbnailCrash(e, st);
    return null;
  }
}

/// One automatic retry before fallback (stability on transient gallery errors).
Future<Uint8List?> _loadThumbnailWithRetry(AssetEntity asset) async {
  try {
    var b = await _safeThumbnailBytesOnce(asset);
    if (b != null && b.isNotEmpty) return b;
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return await _safeThumbnailBytesOnce(asset);
  } catch (e, st) {
    logThumbnailCrash(e, st);
    return null;
  }
}

class _MobileSafeThumbnail extends StatefulWidget {
  final AssetEntity asset;

  const _MobileSafeThumbnail({required this.asset});

  @override
  State<_MobileSafeThumbnail> createState() => _MobileSafeThumbnailState();
}

class _MobileSafeThumbnailState extends State<_MobileSafeThumbnail> {
  Uint8List? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final b = await _loadThumbnailWithRetry(widget.asset);
      if (!mounted) return;
      setState(() {
        _bytes = b;
        _loading = false;
      });
    } catch (e, st) {
      logThumbnailCrash(e, st);
      if (!mounted) return;
      setState(() {
        _bytes = null;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _bytes = null;
    super.dispose();
  }

  static Widget _placeholder() => Container(
        color: Colors.white24,
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.white54),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    final b = _bytes;
    if (b == null || b.isEmpty) return _placeholder();
    return Image.memory(
      b,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      cacheWidth: 250,
      cacheHeight: 250,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }
}

class _DbAlbumDetailScreen extends StatelessWidget {
  final String albumName;
  final List<String> keys;
  final Widget Function(String key) resolveThumb;
  final Future<void> Function(String key) onRemoveKey;

  const _DbAlbumDetailScreen({
    required this.albumName,
    required this.keys,
    required this.resolveThumb,
    required this.onRemoveKey,
  });

  @override
  Widget build(BuildContext context) {
    final items = List<String>.from(keys);

    return Scaffold(
      appBar: AppBar(
        title: Text(albumName),
      ),
      body: items.isEmpty
          ? const Center(child: Text('No images in this album yet.'))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final k = items[i];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: resolveThumb(k),
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: InkWell(
                        onTap: () async {
                          await onRemoveKey(k);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed')));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
