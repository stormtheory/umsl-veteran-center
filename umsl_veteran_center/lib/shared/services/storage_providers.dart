// lib/shared/services/storage_providers.dart
//
// Riverpod providers that expose SecureStorageService and derived async state
// to the rest of the app. All features read/write storage through these.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'secure_storage_service.dart';

// ---------------------------------------------------------------------------
// Singleton service provider
// ---------------------------------------------------------------------------

/// Single instance of SecureStorageService for the entire app lifetime.
final secureStorageProvider = Provider<SecureStorageService>(
  (_) => SecureStorageService(),
);

// ---------------------------------------------------------------------------
// Onboarding state
// ---------------------------------------------------------------------------

/// Async provider that resolves to true if onboarding has been completed.
/// The router watches this to decide whether to show onboarding or home.
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final storage = ref.read(secureStorageProvider);
  return storage.isOnboardingComplete();
});

// ---------------------------------------------------------------------------
// Cached user profile
// ---------------------------------------------------------------------------

/// Loads the stored UserProfile once; null means onboarding not done yet.
/// Features that need the user's first name (e.g. welcome message) watch this.
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final storage = ref.read(secureStorageProvider);
  return storage.getUserProfile();
});
