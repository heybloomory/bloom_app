import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/glass_container.dart';
import '../../models/album_model.dart';
import '../../models/photo_model.dart';
import '../../services/import_processing_service.dart';
import '../../services/local_album_service.dart';
import '../../services/local_photo_store.dart';
import '../local_media/platform/desktop_support.dart' as desk;

class ImportStudioScreen extends StatefulWidget {
  const ImportStudioScreen({super.key});

  @override
  State<ImportStudioScreen> createState() => _ImportStudioScreenState();
}

class _ImportStudioScreenState extends State<ImportStudioScreen> {
  static const _previewAlbumId = '__import_preview__';
  static const _lastImportPhotoIdsKey = 'last_import_photo_ids_v1';
  static const _lastImportAlbumIdsKey = 'last_import_album_ids_v1';
  static const _lastImportAtKey = 'last_import_at_v1';

  bool _scanning = false;
  bool _processing = false;
  bool _saving = false;
  bool _recommendedApplied = false;
  Timer? _debounce;

  List<Photo> _importPreviewPhotos = const <Photo>[];
  List<Photo> _processedPreview = const <Photo>[];
  Map<String, List<Photo>> _groups = const {};

  bool removeDuplicates = true;
  bool bestOnly = true;
  bool detectScreenshots = false;
  bool autoGroup = true;
  bool autoTag = true;

  int get _beforeCount => _importPreviewPhotos.length;
  int get _afterCount => _processedPreview.length;

  @override
  void initState() {
    super.initState();
    _reprocess();
  }

  bool get _isMobile {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  void _applyRecommendedDefaults() {
    setState(() {
      removeDuplicates = true;
      bestOnly = true;
      autoGroup = true;
      autoTag = true;
      _recommendedApplied = true;
    });
  }

  void _scheduleReprocess() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      _reprocess();
    });
  }

  Future<void> _scanGallery() async {
    if (_scanning) return;
    setState(() => _scanning = true);
    try {
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.image,
          withData: true,
        );
        if (result == null) return;
        final list = <Photo>[];
        for (final f in result.files) {
          if (f.bytes == null) continue;
          list.add(
            Photo(
              id: 'preview_${DateTime.now().microsecondsSinceEpoch}_${list.length}',
              albumId: _previewAlbumId,
              localPath: f.name,
              originalFileName: f.name,
              bytes: f.bytes,
              createdAt: DateTime.now(),
            ),
          );
        }
        setState(() => _importPreviewPhotos = list);
      } else if (_isMobile) {
        final perm = await PhotoManager.requestPermissionExtend();
        if (!perm.isAuth) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission denied. Please allow Photos access.')),
          );
          return;
        }
        final paths = await PhotoManager.getAssetPathList(
          type: RequestType.image,
          filterOption: FilterOptionGroup(
            orders: [
              const OrderOption(type: OrderOptionType.createDate, asc: false),
            ],
          ),
        );
        if (paths.isEmpty) {
          setState(() => _importPreviewPhotos = const <Photo>[]);
          return;
        }
        final album = paths.first;
        final assets = await album.getAssetListPaged(page: 0, size: 800);
        final list = <Photo>[];
        for (final a in assets) {
          final file = await a.file;
          if (file == null) continue;
          list.add(
            Photo(
              id: 'preview_${a.id}',
              albumId: _previewAlbumId,
              localPath: file.path,
              originalFileName: a.title,
              sourceId: a.id,
              createdAt: a.createDateTime,
            ),
          );
          if (list.length % 50 == 0) {
            await Future<void>.delayed(Duration.zero);
          }
        }
        setState(() => _importPreviewPhotos = list);
      } else {
        // Desktop: simulate "gallery scan" with multi-select picker (no directory enumeration here).
        final result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.image,
          withData: false,
        );
        if (result == null) return;
        final list = <Photo>[];
        for (final f in result.files) {
          final path = (f.path ?? '').trim();
          if (path.isEmpty) continue;
          list.add(
            Photo(
              id: 'preview_$path',
              albumId: _previewAlbumId,
              localPath: path,
              originalFileName: f.name,
              createdAt: DateTime.now(),
            ),
          );
        }
        setState(() => _importPreviewPhotos = list);
      }
      _applyRecommendedDefaults();
      await _reprocess();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not scan gallery: $e')),
      );
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _scanFolder() async {
    if (_scanning) return;
    setState(() => _scanning = true);
    try {
      if (kIsWeb) {
        // Web: directory picking isn't reliable; simulate folder scan via multi-select.
        final result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.image,
          withData: true,
        );
        if (result == null) return;
        final list = <Photo>[];
        for (final f in result.files) {
          if (f.bytes == null) continue;
          list.add(
            Photo(
              id: 'preview_${DateTime.now().microsecondsSinceEpoch}_${list.length}',
              albumId: _previewAlbumId,
              localPath: f.name,
              originalFileName: f.name,
              bytes: f.bytes,
              createdAt: DateTime.now(),
            ),
          );
        }
        setState(() => _importPreviewPhotos = list);
      } else {
        final path = await desk.pickDirectoryPath();
        if (path == null || path.trim().isEmpty) return;
        final files = await desk.listImageFilesInDir(path);
        final list = <Photo>[];
        for (final f in files.take(2000)) {
          list.add(
            Photo(
              id: 'preview_${f.path}',
              albumId: _previewAlbumId,
              localPath: f.path,
              originalFileName: f.path.split(Platform.pathSeparator).last,
              createdAt: f.modified,
            ),
          );
          if (list.length % 50 == 0) {
            await Future<void>.delayed(Duration.zero);
          }
        }
        setState(() => _importPreviewPhotos = list);
      }
      _applyRecommendedDefaults();
      await _reprocess();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not scan folder: $e')),
      );
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _reprocess() async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      if (_importPreviewPhotos.isEmpty) {
        setState(() {
          _processedPreview = const <Photo>[];
          _groups = const {};
        });
        return;
      }
      final result = await ImportProcessingService.processPhotos(
        _importPreviewPhotos,
        options: ImportProcessingOptions(
          removeDuplicates: removeDuplicates,
          bestOnly: bestOnly,
          detectScreenshots: detectScreenshots,
          autoGroup: autoGroup,
          autoTag: autoTag,
        ),
      );
      setState(() {
        _processedPreview = result.photos;
        _groups = result.groups;
      });
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _addToTimeline() async {
    if (_saving || _processedPreview.isEmpty) return;
    setState(() => _saving = true);
    try {
      await LocalPhotoStore.init();

      // Create month albums and optional day sub-albums.
      final monthAlbumIds = <String, String>{}; // yyyy-mm -> albumId
      final dayAlbumIds = <String, String>{}; // yyyy-mm-dd -> subAlbumId
      final createdAlbumIds = <String>[];
      final createdPhotoIds = <String>[];

      TimelineAlbum ensureMonthAlbum(DateTime dt) {
        final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
        final existing = monthAlbumIds[key];
        if (existing != null) {
          return LocalPhotoStore.getAlbum(existing)!;
        }
        final title = _monthTitle(dt);
        final created = LocalAlbumService.createAlbum(title);
        monthAlbumIds[key] = created.id;
        createdAlbumIds.add(created.id);
        return created;
      }

      TimelineAlbum ensureDayAlbum(TimelineAlbum monthAlbum, DateTime dt) {
        final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        final existing = dayAlbumIds[key];
        if (existing != null) {
          return LocalPhotoStore.getAlbum(existing)!;
        }
        final title = _dayTitle(dt);
        final created = LocalAlbumService.createAlbum(title, parentAlbumId: monthAlbum.id);
        dayAlbumIds[key] = created.id;
        createdAlbumIds.add(created.id);
        return created;
      }

      final items = List<Photo>.from(_processedPreview)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      var saved = 0;
      for (final p in items) {
        final month = ensureMonthAlbum(p.createdAt);
        final targetAlbum = autoGroup ? ensureDayAlbum(month, p.createdAt) : month;

        final localPath = p.localPath.trim().isNotEmpty
            ? p.localPath.trim()
            : ((p.originalFileName ?? '').trim().isNotEmpty
                ? (p.originalFileName ?? '').trim()
                : 'import_${DateTime.now().microsecondsSinceEpoch}_$saved');

        final added = LocalPhotoStore.addPhoto(
          albumId: targetAlbum.id,
          localPath: localPath,
          originalFileName: p.originalFileName,
          sourceId: p.sourceId,
          bytes: kIsWeb ? p.bytes : null,
          createdAt: p.createdAt,
        );
        createdPhotoIds.add(added.id);

        saved++;
        if (saved % 50 == 0) {
          await Future<void>.delayed(Duration.zero);
        }
      }

      for (final id in monthAlbumIds.values) {
        LocalPhotoStore.ensureAlbumCover(id);
      }
      for (final id in dayAlbumIds.values) {
        LocalPhotoStore.ensureAlbumCover(id);
      }

      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_lastImportPhotoIdsKey, createdPhotoIds);
      await prefs.setStringList(_lastImportAlbumIdsKey, createdAlbumIds);
      await prefs.setInt(_lastImportAtKey, DateTime.now().millisecondsSinceEpoch);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add to timeline: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _quickImport() async {
    if (_scanning || _processing || _saving) return;
    _applyRecommendedDefaults();
    await _scanGallery();
    if (!mounted) return;
    if (_processedPreview.isEmpty) return;
    await _addToTimeline();
  }

  String _monthTitle(DateTime dt) {
    const months = [
      'January','February','March','April','May','June','July','August','September','October','November','December'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  String _dayTitle(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final scanned = _importPreviewPhotos.isNotEmpty;
    final busy = _scanning || _processing || _saving;

    return Scaffold(
      backgroundColor: const Color(0xFF120A1B),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                children: [
              Row(
                children: [
                  AppIconCircleButton(
                    onPressed: busy ? null : () => Navigator.pop(context),
                    icon: Icons.arrow_back,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Import Media',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AppSecondaryButton(
                    onPressed: busy ? null : _quickImport,
                    text: '⚡ Auto Organize (Recommended)',
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 10),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'We’ll automatically clean and organize your photos',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              GlassContainer(
                radius: 24,
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    AppSecondaryButton(
                      onPressed: busy ? null : _scanGallery,
                      icon: Icons.photo_library_outlined,
                      text: _scanning ? 'Scanning…' : 'Scan Gallery',
                    ),
                    AppSecondaryButton(
                      onPressed: busy ? null : _scanFolder,
                      icon: Icons.folder_open_outlined,
                      text: _scanning ? 'Scanning…' : 'Scan Folder',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (!scanned)
                Expanded(
                  child: Center(
                    child: GlassContainer(
                      radius: 28,
                      padding: const EdgeInsets.all(28),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Scan to preview',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Nothing is saved until you tap “Add to Timeline”.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_recommendedApplied)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassContainer(
                            radius: 18,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Text(
                              '✨ Recommended cleanup applied',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          Text(
                            '$_beforeCount photos found',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          if (_processing)
                            Text(
                              'Processing…',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1,
                          ),
                          itemCount: _processedPreview.length,
                          itemBuilder: (_, i) => _PreviewTile(photo: _processedPreview[i]),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GlassContainer(
                        radius: 24,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Smart Cleanup',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                AppSecondaryButton(
                                  text: 'Optimize photos',
                                  onPressed: () {
                                    setState(() {
                                      final next = !(removeDuplicates && bestOnly);
                                      removeDuplicates = next;
                                      bestOnly = next;
                                    });
                                    _scheduleReprocess();
                                  },
                                  selected: removeDuplicates && bestOnly,
                                ),
                                AppSecondaryButton(
                                  text: 'Detect screenshots',
                                  onPressed: () {
                                    setState(() => detectScreenshots = !detectScreenshots);
                                    _scheduleReprocess();
                                  },
                                  selected: detectScreenshots,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Smart Organization',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                AppSecondaryButton(
                                  text: 'Auto group events',
                                  onPressed: () {
                                    setState(() => autoGroup = !autoGroup);
                                    _scheduleReprocess();
                                  },
                                  selected: autoGroup,
                                ),
                                AppSecondaryButton(
                                  text: 'Auto tag photos',
                                  onPressed: () {
                                    setState(() => autoTag = !autoTag);
                                    _scheduleReprocess();
                                  },
                                  selected: autoTag,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  'Before: $_beforeCount',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'After: $_afterCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                if (autoGroup && _groups.isNotEmpty) ...[
                                  const SizedBox(width: 12),
                                  Text(
                                    '${_groups.length} event${_groups.length == 1 ? '' : 's'}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.70),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: AppPrimaryButton(
                          onPressed: busy ? null : _addToTimeline,
                          icon: Icons.check_circle_outline,
                          text: _saving ? 'Adding…' : 'Add to Timeline',
                          isLoading: _saving,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
            if (_processing || _saving)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.45),
                    child: Center(
                      child: GlassContainer(
                        radius: 22,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        child: const Text(
                          'Processing your memories…',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  final Photo photo;

  const _PreviewTile({required this.photo});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: GlassContainer(
        radius: 18,
        padding: EdgeInsets.zero,
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    if (kIsWeb) {
      final bytes = photo.bytes;
      if (bytes != null && bytes.isNotEmpty) {
        return Image.memory(bytes, fit: BoxFit.cover);
      }
      return Container(color: Colors.white.withValues(alpha: 0.06));
    }

    final p = photo.localPath.trim();
    if (p.isNotEmpty) {
      return Image.file(File(p), fit: BoxFit.cover, errorBuilder: (_, __, ___) {
        return Container(color: Colors.white.withValues(alpha: 0.06));
      });
    }
    return Container(color: Colors.white.withValues(alpha: 0.06));
  }
}

