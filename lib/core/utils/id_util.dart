import 'dart:convert';

/// Utility to create Firestore-safe document IDs from arbitrary strings (like URLs).
///
/// We avoid using raw URLs as doc IDs because they contain '/' and other
/// disallowed characters. This produces a compact, deterministic ID.
class IdUtil {
  static String fromString(String input, {int maxLen = 40}) {
    final bytes = utf8.encode(input);
    final b64 = base64Url.encode(bytes);
    // Firestore doc IDs can be long, but keep it reasonable.
    return b64.length <= maxLen ? b64 : b64.substring(0, maxLen);
  }

  static String fromUrl(String url) => fromString(url);
}
