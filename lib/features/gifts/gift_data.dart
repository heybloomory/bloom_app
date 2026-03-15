import 'gift_models.dart';

// Demo catalog data (assets bundled in the repo).
// Later you can swap this with Firestore or a backend catalog.

class GiftData {
  static const String _img1 = 'assets/images/sample.jpg';
  static const String _img2 = 'assets/images/sample.jpg';
  static const String _img3 = 'assets/images/sample.jpg';
  static const String _img4 = 'assets/images/sample.jpg';

  /// In-app demo catalog.
  ///
  /// This is intentionally mutable so the "Add Gift" modal can append new demo
  /// products without needing a backend yet.
  static final List<GiftProduct> products = [
    const GiftProduct(
      id: 'pfc_heart',
      category: 'photo_frame_collages',
      title: 'Romantic Heart Collage',
      price: 69,
      rating: 4.8,
      images: [_img1],
    ),
    const GiftProduct(
      id: 'pfc_wood',
      category: 'photo_frame_collages',
      title: 'Elegant Wooden Collage',
      price: 69,
      rating: 4.7,
      images: [_img2],
    ),
    const GiftProduct(
      id: 'pfc_travel',
      category: 'photo_frame_collages',
      title: 'Travel Memories Collage',
      price: 79,
      rating: 4.6,
      images: [_img3],
    ),
    const GiftProduct(
      id: 'pfc_anniversary',
      category: 'photo_frame_collages',
      title: 'Anniversary Heart Collage',
      price: 69,
      rating: 4.9,
      images: [_img4],
    ),

    const GiftProduct(
      id: 'cpa_soft',
      category: 'custom_photo_albums',
      title: 'Classic Softcover Album',
      price: 59,
      rating: 4.6,
      images: [_img1],
    ),
    const GiftProduct(
      id: 'cpa_hard',
      category: 'custom_photo_albums',
      title: 'Premium Hardcover Album',
      price: 89,
      rating: 4.8,
      images: [_img2],
    ),

    const GiftProduct(
      id: 'ek_nameplate',
      category: 'engraved_keepsakes',
      title: 'Engraved Nameplate',
      price: 49,
      rating: 4.5,
      images: [_img3],
    ),
    const GiftProduct(
      id: 'ek_keychain',
      category: 'engraved_keepsakes',
      title: 'Engraved Keychain',
      price: 29,
      rating: 4.4,
      images: [_img4],
    ),
  ];

  static void addProduct(GiftProduct product) {
    products.insert(0, product);
  }

  static GiftProduct byId(String id) {
    return products.firstWhere((p) => p.id == id);
  }

  static List<GiftProduct> byCategory(String category) {
    return products.where((p) => p.category == category).toList();
  }
}
