import 'package:flutter/material.dart';

/// Renders either an asset image or a network image depending on [path].
///
/// We keep this tiny helper so "Add Gift" can accept multiple image URLs
/// without adding extra packages.
class GiftImage extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;

  const GiftImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  bool get _isNetwork => path.startsWith('http://') || path.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    if (_isNetwork) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      width: width,
      height: height,
      color: Colors.white10,
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported, color: Colors.white54),
    );
  }
}
