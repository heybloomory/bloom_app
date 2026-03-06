/// Helpers for BunnyCDN Image Optimizer / Transform URLs.
///
/// Examples:
/// - https://bloomory.b-cdn.net/image.jpg?width=300&height=200
/// - https://bloomory.b-cdn.net/image.jpg?class=thumbnail
class CdnUrl {
  static String thumbnail(
    String original, {
    int width = 300,
    int height = 200,
    bool useClassThumbnail = false,
  }) {
    if (original.isEmpty) return original;
    final sep = original.contains('?') ? '&' : '?';
    if (useClassThumbnail) {
      return '$original${sep}class=thumbnail';
    }
    return '$original${sep}width=$width&height=$height';
  }
}
