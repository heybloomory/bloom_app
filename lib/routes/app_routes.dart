import 'package:flutter/material.dart';

// Core screens
import '../features/splash/splash_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/profile_completion_screen.dart';

// Dashboard / Timeline
import '../features/timeline/timeline_screen.dart';

// Albums & Memories
import '../features/albums/albums_screen.dart';
import '../features/albums/album_detail_screen.dart';
import '../features/memories/shared_memories_screen.dart';

// Local device media
import '../features/local_media/local_media_screen.dart';


// Settings
import '../features/settings/settings_screen.dart';

// Profile
import '../features/profile/profile_screen.dart';

// Primary tabs
import '../features/gifts/gifts_screen.dart';
import '../features/gifts/gift_category_screen.dart';
import '../features/gifts/gift_product_screen.dart';
import '../features/gifts/gift_customize_screen.dart';
import '../features/gifts/gift_checkout_screen.dart';
import '../features/service/service_screen.dart';
import '../features/service/service_destination_screen.dart';
import '../features/service/service_destination_detail_screen.dart';
import '../features/service/service_booking_screen.dart';
import '../features/learn/learn_screen.dart';
import '../features/learn/learn_course_detail_screen.dart';
import '../features/learn/learn_lesson_player_screen.dart';
import '../features/vault/vault_screen.dart';

// Settings sub-pages
import '../features/settings/notifications_settings_screen.dart';

// Vault flow
import '../features/vault/vault_private_unlock_screen.dart';
import '../features/vault/vault_private_memories_screen.dart';
import '../features/vault/vault_family_screen.dart';
import '../features/vault/vault_time_locked_screen.dart';
import '../features/vault/vault_legacy_access_screen.dart';
import '../features/vault/vault_security_trust_screen.dart';
import '../features/vault/vault_manage_storage_screen.dart';

class AppRoutes {
  // Core
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const profileCompletion = '/profile-completion';
  static const profile = '/profile';

  // Primary tabs
  static const gifts = '/gifts';
  static const service = '/service';
  static const learn = '/learn';
  static const vault = '/vault';

  // Learn flow
  static const learnCourseDetail = '/learn/course';
  static const learnLessonPlayer = '/learn/lesson';

  // Vault flow
  static const vaultPrivateUnlock = '/vault/private/unlock';
  static const vaultPrivateMemories = '/vault/private/memories';
  static const vaultFamily = '/vault/family';
  static const vaultTimeLocked = '/vault/time-locked';
  static const vaultLegacyAccess = '/vault/legacy';
  static const vaultSecurityTrust = '/vault/security';
  static const vaultManageStorage = '/vault/manage-storage';

  // Services flow
  static const serviceDestination = '/service/destination';
  static const serviceDestinationDetail = '/service/destination/detail';
  static const serviceBooking = '/service/booking';

  // Gifts flow
  static const giftCategory = '/gifts/category';
  static const giftProduct = '/gifts/product';
  static const giftCustomize = '/gifts/customize';
  static const giftCheckout = '/gifts/checkout';

  // Main
  static const dashboard = '/dashboard';
  static const timeline = '/dashboard'; // timeline tab uses dashboard route for nav
  static const albums = '/albums';
  static const sharedMemories = '/shared-memories';

  // User
  static const settings = '/settings';
  static const settingsNotifications = '/settings/notifications';
  static const albumDetail = '/album-detail';
  static const localMedia = '/local-media';

  static final Map<String, WidgetBuilder> routes = {
    profile: (_) => const ProfileScreen(),
    splash: (_) => const SplashPage(),
    login: (_) => const LoginPage(),
    register: (_) => const LoginPage(),
    profileCompletion: (_) => const ProfileCompletionScreen(),

    dashboard: (_) => const TimelineScreen(),
    albums: (_) => const AlbumsScreen(),
	    localMedia: (_) => const LocalMediaScreen(),
albumDetail: (context) {
  final args = ModalRoute.of(context)?.settings.arguments;
  final map = args is Map ? args : const {};

  final albumId = (map['albumId'] ?? '').toString();
  return AlbumDetailScreen(albumId: albumId);
},

    sharedMemories: (_) => const SharedMemoriesScreen(),

    settings: (_) => const SettingsScreen(),
    settingsNotifications: (_) => const NotificationsSettingsScreen(),

    // Primary tabs
    gifts: (_) => const GiftsScreen(),
    service: (_) => const ServiceScreen(),
    learn: (_) => const LearnScreen(),
    vault: (_) => const VaultScreen(),

    // Learn flow
    learnCourseDetail: (context) => LearnCourseDetailScreen.fromRoute(context),
    learnLessonPlayer: (context) => LearnLessonPlayerScreen.fromRoute(context),

    // Vault flow
    vaultPrivateUnlock: (_) => const VaultPrivateUnlockScreen(),
    vaultPrivateMemories: (_) => const VaultPrivateMemoriesScreen(),
    vaultFamily: (_) => const VaultFamilyScreen(),
    vaultTimeLocked: (_) => const VaultTimeLockedScreen(),
    vaultLegacyAccess: (_) => const VaultLegacyAccessScreen(),
    vaultSecurityTrust: (_) => const VaultSecurityTrustScreen(),
    vaultManageStorage: (_) => const VaultManageStorageScreen(),

    // Services flow
    serviceDestination: (context) => ServiceDestinationScreen.fromRoute(context),
    serviceDestinationDetail: (context) => ServiceDestinationDetailScreen.fromRoute(context),
    serviceBooking: (context) => ServiceBookingScreen.fromRoute(context),

    // Gifts flow
    giftCategory: (context) => GiftCategoryScreen.fromRoute(context),
    giftProduct: (context) => GiftProductScreen.fromRoute(context),
    giftCustomize: (context) => GiftCustomizeScreen.fromRoute(context),
    giftCheckout: (context) => GiftCheckoutScreen.fromRoute(context),
  };
}
