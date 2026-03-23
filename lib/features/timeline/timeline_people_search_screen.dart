import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import '../../services/face_index_service.dart';
import 'timeline_photo_image.dart';

enum _PersonAction { rename, merge, separate }

class TimelinePeopleSearchScreen extends StatefulWidget {
  const TimelinePeopleSearchScreen({super.key});

  @override
  State<TimelinePeopleSearchScreen> createState() =>
      _TimelinePeopleSearchScreenState();
}

class _TimelinePeopleSearchScreenState extends State<TimelinePeopleSearchScreen> {
  bool _scanning = false;
  bool _merging = false;
  bool _separating = false;
  List<FacePersonGroup> _groups = const <FacePersonGroup>[];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  void _loadGroups() {
    setState(() {
      _groups = FaceIndexService.listPeopleGroups();
    });
  }

  Future<void> _scanFaces() async {
    setState(() => _scanning = true);
    try {
      final summary = await FaceIndexService.refreshFaceIndex();
      _loadGroups();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Scanned ${summary.processedPhotos} photos, found ${summary.totalFaces} faces across ${summary.totalPeople} people groups.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Face scan failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _mergeGroup(FacePersonGroup baseGroup) async {
    if (_groups.length < 2 || _merging || _separating) return;
    final mergeCandidate = await showModalBottomSheet<FacePersonGroup>(
      context: context,
      backgroundColor: const Color(0xFF1A0E2A),
      builder: (context) {
        final candidates = _groups
            .where((group) => group.clusterId != baseGroup.clusterId)
            .toList();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Merge into ${baseGroup.displayName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose the duplicate person group to merge with this one.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: candidates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final group = candidates[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        tileColor: Colors.white.withValues(alpha: 0.06),
                        leading: SizedBox(
                          width: 42,
                          height: 42,
                          child: ClipOval(
                            child: buildTimelinePhotoImage(
                              url: null,
                              thumbUrl: null,
                              localPath:
                                  group.sampleFace?.thumbnailPath.isNotEmpty ==
                                          true
                                      ? group.sampleFace!.thumbnailPath
                                      : group.samplePhoto.localPath,
                            ),
                          ),
                        ),
                        title: Text(
                          group.displayName,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${group.photoCount} images',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                        onTap: () => Navigator.pop(context, group),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (mergeCandidate == null || !mounted) return;

    setState(() => _merging = true);
    try {
      await FaceIndexService.mergePeopleGroups(
        keepClusterId: baseGroup.clusterId,
        mergeClusterId: mergeCandidate.clusterId,
      );
      _loadGroups();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${mergeCandidate.displayName} merged into ${baseGroup.displayName}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Merge failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _merging = false);
    }
  }

  Future<void> _separateGroup(FacePersonGroup baseGroup) async {
    if (_merging || _separating) return;
    final candidates = FaceIndexService.listSplitCandidates(baseGroup.clusterId);
    if (candidates.length <= 1) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This person group has nothing to separate yet.'),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<FaceSplitCandidate>(
      context: context,
      backgroundColor: const Color(0xFF1A0E2A),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Separate from ${baseGroup.displayName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose the merged face group that should become its own person again.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: candidates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final candidate = candidates[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        tileColor: Colors.white.withValues(alpha: 0.06),
                        leading: SizedBox(
                          width: 44,
                          height: 44,
                          child: ClipOval(
                            child: buildTimelinePhotoImage(
                              url: null,
                              thumbUrl: null,
                              localPath: candidate.thumbnailPath,
                            ),
                          ),
                        ),
                        title: Text(
                          'Face set ${index + 1}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${candidate.imageCount} images',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                        onTap: () => Navigator.pop(context, candidate),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) return;

    setState(() => _separating = true);
    try {
      final newClusterId = await FaceIndexService.separatePersonGroup(
        clusterId: baseGroup.clusterId,
        faceHash: selected.faceHash,
      );
      _loadGroups();
      if (!mounted || newClusterId == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${FaceIndexService.displayNameForCluster(newClusterId)} separated from ${baseGroup.displayName}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Separate failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _separating = false);
    }
  }

  Future<void> _renameGroup(FacePersonGroup group) async {
    final controller = TextEditingController(text: group.displayName);
    final nextName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A0E2A),
          title: const Text(
            'Name This Person',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter a name',
              hintStyle: TextStyle(color: Colors.white54),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('Clear'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (nextName == null || !mounted) return;

    await FaceIndexService.renamePersonGroup(
      clusterId: group.clusterId,
      name: nextName,
    );
    _loadGroups();
  }

  @override
  Widget build(BuildContext context) {
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
                        'People Search',
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
                      const Text(
                        'Detect faces from saved timeline images and group similar faces together for local people search.',
                        style: TextStyle(
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _scanning ? null : _scanFaces,
                        icon: _scanning
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.face_retouching_natural),
                        label: Text(_scanning ? 'Scanning Faces...' : 'Scan Faces'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _groups.isEmpty
                      ? const _PeopleEmptyState()
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 240,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.78,
                          ),
                          itemCount: _groups.length,
                          itemBuilder: (context, index) {
                            final group = _groups[index];
                            return _PersonCard(
                              group: group,
                              onRename: () => _renameGroup(group),
                              onMerge: (_merging || _separating)
                                  ? null
                                  : () => _mergeGroup(group),
                              onSeparate: (_merging || _separating)
                                  ? null
                                  : () => _separateGroup(group),
                            );
                          },
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

class _PersonCard extends StatelessWidget {
  final FacePersonGroup group;
  final VoidCallback? onRename;
  final VoidCallback? onMerge;
  final VoidCallback? onSeparate;

  const _PersonCard({
    required this.group,
    this.onRename,
    this.onMerge,
    this.onSeparate,
  });

  @override
  Widget build(BuildContext context) {
    final photo = group.samplePhoto;
    final face = group.sampleFace;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.pop(context, group.clusterId);
      },
      child: GlassContainer(
        radius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Stack(
          children: [
            Positioned(
              top: -4,
              right: -6,
              child: PopupMenuButton<_PersonAction>(
                tooltip: 'Person actions',
                color: const Color(0xFF241136),
                onSelected: (action) {
                  switch (action) {
                    case _PersonAction.rename:
                      onRename?.call();
                      break;
                    case _PersonAction.merge:
                      onMerge?.call();
                      break;
                    case _PersonAction.separate:
                      onSeparate?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<_PersonAction>(
                    value: _PersonAction.rename,
                    child: Text(
                      'Rename',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const PopupMenuItem<_PersonAction>(
                    value: _PersonAction.merge,
                    child: Text(
                      'Merge',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const PopupMenuItem<_PersonAction>(
                    value: _PersonAction.separate,
                    child: Text(
                      'Separate',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.more_horiz,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFC857).withValues(alpha: 0.70),
                        width: 1.6,
                      ),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFFD978).withValues(alpha: 0.28),
                          Colors.white.withValues(alpha: 0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFC857).withValues(alpha: 0.18),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: buildTimelinePhotoImage(
                        url: null,
                        thumbUrl: null,
                        localPath: face?.thumbnailPath.isNotEmpty == true
                            ? face!.thumbnailPath
                            : photo.localPath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    group.displayName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${group.photoCount} image${group.photoCount == 1 ? '' : 's'}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.70),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to filter',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.48),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeopleEmptyState extends StatelessWidget {
  const _PeopleEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassContainer(
        radius: 28,
        padding: const EdgeInsets.all(24),
        child: Text(
          'No people index yet. Run Scan Faces to detect and save faces from your local images.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
