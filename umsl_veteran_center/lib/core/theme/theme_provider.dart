// lib/core/theme/theme_provider.dart
//
// Theme mode provider — persists to Keychain so the preference
// survives app restarts. Defaults to dark mode.
// Settings screen calls setThemeMode() to change and save.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/storage_providers.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final ref;

  ThemeModeNotifier(this.ref) : super(ThemeMode.dark) {
    _loadSaved();
  }

  // Load saved preference from Keychain on startup
  Future<void> _loadSaved() async {
    final storage = ref.read(secureStorageProvider);
    final saved   = await storage.getThemeMode();
    if (saved == 'light')  state = ThemeMode.light;
    if (saved == 'dark')   state = ThemeMode.dark;
    if (saved == 'system') state = ThemeMode.system;
  }

  // Change theme and persist to Keychain
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final storage = ref.read(secureStorageProvider);
    final modeStr = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.system
            ? 'system'
            : 'dark';
    await storage.saveThemeMode(modeStr);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(ref),
);
