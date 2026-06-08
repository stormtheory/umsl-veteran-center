// lib/shared/services/secure_storage_service.dart
//
// Wraps flutter_secure_storage so the rest of the app never touches
// raw key strings or the plugin directly.
//
// On iOS this writes to the Keychain (kSecClassGenericPassword).
// On macOS it also uses the Keychain via the same plugin.
// On Android it uses EncryptedSharedPreferences (future support).
//
// All user identity data (name, email) is FERPA/PII-sensitive
// and must only be read/written through this service.
// Student ID is validated during onboarding only and never stored.

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ---------------------------------------------------------------------------
// Storage key constants — centralised so a rename is one-line change
// ---------------------------------------------------------------------------
class _Keys {
  // Onboarding completion flag
  static const onboardingComplete = 'onboarding_complete';

  // User identity (FERPA-protected PII)
  static const userProfile = 'user_profile';

  // Theme and UI preferences (non-sensitive but kept here for consistency)
  static const themeMode = 'theme_mode';
  static const textSize = 'text_size';
  static const notifPrefs = 'notif_prefs';
}

// ---------------------------------------------------------------------------
// User profile model — name and email only.
// Student ID is validated during onboarding then immediately discarded.
// It is never written to storage.
// ---------------------------------------------------------------------------
class UserProfile {
  final String email;
  final String firstName;
  final String lastName;

  const UserProfile({
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  // Serialize to JSON for Keychain storage
  Map<String, dynamic> toJson() => {
        'email':     email,
        'firstName': firstName,
        'lastName':  lastName,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        email:     json['email']     as String,
        firstName: json['firstName'] as String,
        lastName:  json['lastName']  as String,
      );
}

// ---------------------------------------------------------------------------
// Secure storage service
// ---------------------------------------------------------------------------
class SecureStorageService {
  // iOS/macOS Keychain options:
  //   accessibility: Keychain item available after first unlock, even when
  //   device is locked. Survives app reinstall via iCloud Keychain sync.
  //   Set synchronizable: false so data never leaves the device.
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: false, // data must NOT leave the device
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: false,
    ),
  );

  // -------------------------------------------------------------------------
  // Onboarding flag
  // -------------------------------------------------------------------------

  /// Returns true once the user has completed the onboarding flow.
  /// Used by the router to skip onboarding on subsequent launches.
  Future<bool> isOnboardingComplete() async {
    final value = await _storage.read(key: _Keys.onboardingComplete);
    return value == 'true';
  }

  /// Call this after the user successfully completes the final onboarding step.
  Future<void> markOnboardingComplete() async {
    await _storage.write(key: _Keys.onboardingComplete, value: 'true');
  }

  // -------------------------------------------------------------------------
  // User profile (PII / FERPA-sensitive)
  // -------------------------------------------------------------------------

  /// Persist the user's identity after onboarding step 2.
  /// Stored as JSON in the iOS/macOS Keychain.
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
    final encoded = jsonEncode(profile.toJson());
    await _storage.write(key: _Keys.userProfile, value: encoded);
    //print('DEBUG saveUserProfile: encoded="$encoded"');
    } catch (e) {
      print('DEBUG saveUserProfile: Error occurred while saving user profile.' + e.toString());
    //print('DEBUG saveUserProfile: decoded="${profile.toJson()}"');
    }
    
  }

  /// Read back the stored profile, or null if not yet set.
  Future<UserProfile?> getUserProfile() async {
    final raw = await _storage.read(key: _Keys.userProfile);
    if (raw == null) return null;
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  // -------------------------------------------------------------------------
  // UI preferences (theme, text size, notifications)
  // These are low-sensitivity but stored here for a single storage layer.
  // -------------------------------------------------------------------------

  Future<void> saveThemeMode(String mode) async {
    await _storage.write(key: _Keys.themeMode, value: mode);
  }

  Future<String?> getThemeMode() async {
    return _storage.read(key: _Keys.themeMode);
  }

  Future<void> saveTextSize(String size) async {
    await _storage.write(key: _Keys.textSize, value: size);
  }

  Future<String?> getTextSize() async {
    return _storage.read(key: _Keys.textSize);
  }

  Future<void> saveNotifPrefs(Map<String, bool> prefs) async {
    await _storage.write(
      key: _Keys.notifPrefs,
      value: jsonEncode(prefs),
    );
  }

  Future<Map<String, bool>?> getNotifPrefs() async {
    final raw = await _storage.read(key: _Keys.notifPrefs);
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v as bool));
  }

  // -------------------------------------------------------------------------
  // Generic key-value read/write — used by checklist provider and future
  // features that need to store arbitrary JSON blobs in the Keychain
  // -------------------------------------------------------------------------

  /// Read any value by key — returns null if not set
  Future<String?> read(String key) async {
    return _storage.read(key: key);
  }

  /// Write any value by key
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Delete a key
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

    // -------------------------------------------------------------------------
  // Nuclear option — clear everything (debug/reset use only)
  // -------------------------------------------------------------------------

  /// Wipes all secure storage. For development reset flows only.
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
