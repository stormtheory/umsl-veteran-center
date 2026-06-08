// lib/main.dart
//
// App entry point.
// ProviderScope wraps everything so Riverpod providers are accessible globally.
// SplashScreen reads the Keychain onboarding flag and routes accordingly:
//   - Onboarding incomplete  -> OnboardingEmailScreen
//   - Onboarding complete    -> MainShell (home tab)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/onboarding/screens/splash_screen.dart';

void main() {
  runApp(
    // ProviderScope is required at the root for all Riverpod providers
    const ProviderScope(
      child: UmslVetApp(),
    ),
  );
}

class UmslVetApp extends ConsumerWidget {
  const UmslVetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the theme provider so the whole app responds to theme changes
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'UMSL Vet Center',
      debugShowCheckedModeBanner: false,
      theme:      AppTheme.lightTheme,
      darkTheme:  AppTheme.darkTheme,
      themeMode:  themeMode,
      // SplashScreen decides whether to show onboarding or MainShell
      home: const SplashScreen(),
    );
  }
}
