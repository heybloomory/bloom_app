import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/glass_container.dart';
import '../../models/timeline_album_summary.dart';
import '../../services/face_index_service.dart';
import '../../services/local_album_service.dart';
import 'timeline_people_search_screen.dart';
import 'timeline_photo_image.dart';

class TimelineSearchFilterScreen extends StatefulWidget {
  const TimelineSearchFilterScreen({super.key});

  @override
  State<TimelineSearchFilterScreen> createState() =>
      _TimelineSearchFilterScreenState();
}

class _TimelineSearchFilterScreenState
    extends State<TimelineSearchFilterScreen> {
  late final TextEditingController _queryController;

  TimelineSearchScope _scope = TimelineSearchScope.all;
  TimelineSyncFilter _syncFilter = TimelineSyncFilter.all;
  TimelineLevelFilter _levelFilter = TimelineLevelFilter.all;
  String? _selectedPersonClusterId;
  bool _filtersExpanded = true;

  String _personLabel(String clusterId) {
    return FaceIndexService.displayNameForCluster(clusterId);
  }

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
    _queryController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _queryController.text.trim().isNotEmpty ||
      _scope != TimelineSearchScope.all ||
      _syncFilter != TimelineSyncFilter.all ||
      _levelFilter != TimelineLevelFilter.all ||
      _selectedPersonClusterId != null;

  int get _activeFilterCount {
    var count = 0;
    if (_queryController.text.trim().isNotEmpty) count += 1;
    if (_scope != TimelineSearchScope.all) count += 1;
    if (_syncFilter != TimelineSyncFilter.all) count += 1;
    if (_levelFilter != TimelineLevelFilter.all) count += 1;
    if (_selectedPersonClusterId != null) count += 1;
    return count;
  }

  void _collapseFilters() {
    setState(() {
      _filtersExpanded = false;
    });
  }

  void _resetFilters() {
    setState(() {
      _queryController.clear();
      _scope = TimelineSearchScope.all;
      _syncFilter = TimelineSyncFilter.all;
      _levelFilter = TimelineLevelFilter.all;
      _selectedPersonClusterId = null;
      _filtersExpanded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = LocalAlbumService.search(
      query: _queryController.text,
      scope: _scope,
      syncFilter: _syncFilter,
      levelFilter: _levelFilter,
      personClusterId: _selectedPersonClusterId,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF12061F), Color(0xFF1B0F2E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Search & Filter',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GlassContainer(
                  radius: 28,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _filtersExpanded ? 'Search Filters' : 'Filters Applied',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          if (_hasActiveFilters)
                            TextButton(
                              onPressed: _resetFilters,
                              child: const Text('Reset'),
                            ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _filtersExpanded = !_filtersExpanded;
                              });
                            },
                            icon: Icon(
                              _filtersExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.tune,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (_filtersExpanded) ...[
                        TextField(
                          controller: _queryController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, color: Colors.white70),
                            hintText: 'Search album name or image file name',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.06),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _FilterGroup<TimelineSearchScope>(
                          title: 'Search In',
                          value: _scope,
                          values: const [
                            TimelineSearchScope.all,
                            TimelineSearchScope.albums,
                            TimelineSearchScope.images,
                          ],
                          label: (value) => switch (value) {
                            TimelineSearchScope.all => 'All',
                            TimelineSearchScope.albums => 'Albums',
                            TimelineSearchScope.images => 'Images',
                          },
                          onChanged: (value) {
                            setState(() => _scope = value);
                            _collapseFilters();
                          },
                        ),
                        const SizedBox(height: 12),
                        _FilterGroup<TimelineSyncFilter>(
                          title: 'Sync Status',
                          value: _syncFilter,
                          values: const [
                            TimelineSyncFilter.all,
                            TimelineSyncFilter.localOnly,
                            TimelineSyncFilter.synced,
                            TimelineSyncFilter.pending,
                            TimelineSyncFilter.failed,
                          ],
                          label: (value) => switch (value) {
                            TimelineSyncFilter.all => 'All',
                            TimelineSyncFilter.localOnly => 'Local',
                            TimelineSyncFilter.synced => 'Synced',
                            TimelineSyncFilter.pending => 'Syncing',
                            TimelineSyncFilter.failed => 'Failed',
                          },
                          onChanged: (value) {
                            setState(() => _syncFilter = value);
                            _collapseFilters();
                          },
                        ),
                        const SizedBox(height: 12),
                        _FilterGroup<TimelineLevelFilter>(
                          title: 'Album Level',
                          value: _levelFilter,
                          values: const [
                            TimelineLevelFilter.all,
                            TimelineLevelFilter.root,
                            TimelineLevelFilter.subAlbum,
                          ],
                          label: (value) => switch (value) {
                            TimelineLevelFilter.all => 'All',
                            TimelineLevelFilter.root => 'Root',
                            TimelineLevelFilter.subAlbum => 'Sub-Albums',
                          },
                          onChanged: (value) {
                            setState(() => _levelFilter = value);
                            _collapseFilters();
                          },
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: _collapseFilters,
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Show Results'),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (_queryController.text.trim().isNotEmpty)
                              _ActiveFilterChip(
                                label: 'Search: ${_queryController.text.trim()}',
                              ),
                            if (_scope != TimelineSearchScope.all)
                              _ActiveFilterChip(
                                label: _scope == TimelineSearchScope.albums
                                    ? 'Albums'
                                    : 'Images',
                              ),
                            if (_syncFilter != TimelineSyncFilter.all)
                              _ActiveFilterChip(
                                label: switch (_syncFilter) {
                                  TimelineSyncFilter.localOnly => 'Local',
                                  TimelineSyncFilter.synced => 'Synced',
                                  TimelineSyncFilter.pending => 'Syncing',
                                  TimelineSyncFilter.failed => 'Failed',
                                  TimelineSyncFilter.all => 'All',
                                },
                              ),
                            if (_levelFilter != TimelineLevelFilter.all)
                              _ActiveFilterChip(
                                label: _levelFilter == TimelineLevelFilter.root
                                    ? 'Root'
                                    : 'Sub-Albums',
                              ),
                            if (_selectedPersonClusterId != null)
                              _ActiveFilterChip(
                                label: _personLabel(_selectedPersonClusterId!),
                              ),
                            if (!_hasActiveFilters)
                              Text(
                                'No filters applied. Tap the tune icon when you want to search.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.62),
                                ),
                              ),
                          ],
                        ),
                        if (_activeFilterCount > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            '$_activeFilterCount active filter${_activeFilterCount == 1 ? '' : 's'}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.60),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () async {
                    final selected = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TimelinePeopleSearchScreen(),
                      ),
                    );
                    if (selected == null || !mounted) return;
                    setState(() {
                      _selectedPersonClusterId = selected;
                      _filtersExpanded = false;
                    });
                  },
                  child: GlassContainer(
                    radius: 24,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.face_retouching_natural,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'People Search',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                _selectedPersonClusterId == null
                                    ? 'Detect faces, save them locally, and filter by person.'
                                    : 'Filtering by ${_personLabel(_selectedPersonClusterId!)}.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.70),
                                  height: 1.35,
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
                const SizedBox(height: 14),
                if (_selectedPersonClusterId != null && _filtersExpanded)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: GlassContainer(
                            radius: 20,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.face_retouching_natural,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'People filter: ${_personLabel(_selectedPersonClusterId!)}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedPersonClusterId = null;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView(
                    children: [
                      _SectionHeader(
                        title: 'Albums',
                        count: results.albumResults.length,
                      ),
                      const SizedBox(height: 10),
                      if (results.albumResults.isEmpty)
                        const _EmptyBlock(
                          message: 'No matching albums found.',
                        )
                      else
                        ...results.albumResults.map(
                          (result) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _AlbumResultTile(summary: result),
                          ),
                        ),
                      const SizedBox(height: 18),
                      _SectionHeader(
                        title: 'Images',
                        count: results.photoResults.length,
                      ),
                      const SizedBox(height: 10),
                      if (results.photoResults.isEmpty)
                        const _EmptyBlock(
                          message: 'No matching images found.',
                        )
                      else
                        ...results.photoResults.map(
                          (result) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PhotoResultTile(result: result),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterGroup<T> extends StatelessWidget {
  final String title;
  final T value;
  final List<T> values;
  final String Function(T value) label;
  final ValueChanged<T> onChanged;

  const _FilterGroup({
    required this.title,
    required this.value,
    required this.values,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: values.map((entry) {
            final selected = entry == value;
            return InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onChanged(entry),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.28)
                        : Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Text(
                  label(entry),
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: selected ? 1 : 0.76,
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  final String label;

  const _ActiveFilterChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AlbumResultTile extends StatelessWidget {
  final TimelineAlbumSummary summary;

  const _AlbumResultTile({
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => Navigator.pop(context, summary),
      child: GlassContainer(
        radius: 22,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: 0.06),
              ),
              child: summary.coverPhoto == null
                  ? const Icon(
                      Icons.folder_open_outlined,
                      color: Colors.white70,
                      size: 28,
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: buildTimelinePhotoImage(
                        url: summary.coverPhoto!.serverUrl,
                        thumbUrl: summary.coverPhoto!.thumbUrl,
                        localPath: summary.coverPhoto!.localPath,
                        localThumbnailPath:
                            summary.coverPhoto!.localThumbnailPath,
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
                    summary.album.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${summary.photoCount} image${summary.photoCount == 1 ? '' : 's'} • level ${summary.album.level}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.70),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

class _PhotoResultTile extends StatelessWidget {
  final TimelinePhotoSearchResult result;

  const _PhotoResultTile({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final photo = result.photo;
    final fileName = (photo.originalFileName ?? '').trim().isNotEmpty
        ? photo.originalFileName!.trim()
        : photo.localPath.split('/').last;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => Navigator.pop(context, result.albumSummary),
      child: GlassContainer(
        radius: 22,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: 68,
                height: 68,
                child: buildTimelinePhotoImage(
                  url: photo.serverUrl,
                  thumbUrl: photo.thumbUrl,
                  localPath: photo.localPath,
                  localThumbnailPath: photo.localThumbnailPath,
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
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    result.albumSummary.album.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, y').format(photo.createdAt),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
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
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  final String message;

  const _EmptyBlock({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Text(
        message,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.70),
        ),
      ),
    );
  }
}
