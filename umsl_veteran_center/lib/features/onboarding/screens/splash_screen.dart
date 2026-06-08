// lib/features/onboarding/screens/splash_screen.dart
//
// First screen shown on every launch. Displays the UMSL Veterans Center
// logo and military seals, then navigates to either:
//   - OnboardingEmailScreen  (first launch)
//   - HomeScreen             (returning user)
//
// The router calls this screen; it reads onboardingComplete from secure
// storage and redirects after the animation completes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../shared/services/storage_providers.dart';
import 'onboarding_email_screen.dart';
import '../../../shell/main_shell.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  // ---- Animation controllers -----------------------------------------------
  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleFade;
  late final Animation<double> _sealsFade;

  @override
  void initState() {
    super.initState();

    // Main timeline: 2.4 seconds total
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Logo fades and scales in first
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
      ),
    );

    // Title fades in slightly after the logo
    _titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 0.55, curve: Curves.easeOut),
    );

    // Military seals row fades in last
    _sealsFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
    );

    // Start the animation and navigate when it completes
    _controller.forward().then((_) => _navigate());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---- Navigation ----------------------------------------------------------

  /// Check secure storage and route accordingly.
  Future<void> _navigate() async {
    if (!mounted) return;

    // Brief additional pause so the welcome screen doesn't feel rushed
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final storage = ref.read(secureStorageProvider);
    final isComplete = await storage.isOnboardingComplete();

    if (!mounted) return;
    if (isComplete) {
      // Onboarding complete — go straight to the main shell (home tab)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingEmailScreen()),
      );
    }
  }

  // ---- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Full-bleed background matching the app's dark theme
      backgroundColor: isDark ? const Color(0xFF0D0D14) : Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // ---- UMSL Veterans Center logo --------------------------------
              // Image asset: assets/images/vetcenter_Logo.png
              // The logo has a white background so we clip it to a circle and
              // apply a subtle border in dark mode.
              FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF8B0000)
                            : const Color(0xFF8B0000),
                        width: 3,
                      ),
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                color: const Color(0xFF8B0000).withOpacity(0.35),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/vetcenter_Logo.png',
                        fit: BoxFit.cover,
                        // Fallback while asset loading — shows the school colors
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF8B0000),
                          child: const Center(
                            child: Text(
                              'UMSL\nVet\nCenter',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ---- App title -----------------------------------------------
              FadeTransition(
                opacity: _titleFade,
                child: Column(
                  children: [
                    Text(
                      'UMSL',
                      style: TextStyle(
                        fontFamily: 'Oswald', // add to pubspec assets if used
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        color: isDark ? Colors.white : const Color(0xFF0D0D14),
                      ),
                    ),
                    Text(
                      'VETERANS CENTER',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 5,
                        color: isDark
                            ? const Color(0xFFC0A060)
                            : const Color(0xFF8B0000),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Red/white/blue star banner — mirrors the logo's strip
                    _StarsBanner(isDark: isDark),
                  ],
                ),
              ),

              const Spacer(),

              // ---- Official military branch seals row -------------------
              // Real PNG seals loaded from assets/seals/.
              // See README for the Wikimedia Commons download URLs.
              // All 6 seals — Army, Navy, Marines, Air Force, Coast Guard,
              // and Space Force — clipped to circles on a dark background.
              FadeTransition(
                opacity: _sealsFade,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      _SplashSeal('assets/seals/seal_army.png'),
                      _SplashSeal('assets/seals/seal_navy.png'),
                      _SplashSeal('assets/seals/seal_marines.png'),
                      _SplashSeal('assets/seals/seal_airforce.png'),
                      _SplashSeal('assets/seals/seal_coastguard.png'),
                      _SplashSeal('assets/seals/seal_spaceforce.png'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ---- Loading dots --------------------------------------------
              FadeTransition(
                opacity: _sealsFade,
                child: _LoadingDots(color: colors.primary),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Supporting widgets
// ---------------------------------------------------------------------------

/// Red/blue star strip matching the UMSL Veteran Center logo
class _StarsBanner extends StatelessWidget {
  final bool isDark;
  const _StarsBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 20,
      decoration: BoxDecoration(
        color: const Color(0xFFB22222),
        borderRadius: BorderRadius.circular(2),
      ),
      child: const Center(
        child: Text(
          '★  ★  ★  ★  ★  ★  ★  ★',
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

/// Fallback text row shown when the seals image asset is missing
class _BranchLabelRow extends StatelessWidget {
  const _BranchLabelRow();

  static const _branches = ['Army', 'Navy', 'Marines', 'Air Force', 'CG'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _branches
          .map(
            (b) => Text(
              b,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white54,
                letterSpacing: 0.5,
              ),
            ),
          )
          .toList(),
    );
  }
}

/// Three-dot pulsing loader
class _LoadingDots extends StatefulWidget {
  final Color color;
  const _LoadingDots({required this.color});

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            // Each dot peaks at a different phase of the loop
            final phase = (_c.value - i * 0.2).clamp(0.0, 1.0);
            final opacity = (0.2 + 0.8 * (1 - (phase - 0.5).abs() * 2))
                .clamp(0.2, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(opacity),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Small clipped circle for one official branch seal on the splash screen.
/// White background so seals with transparent backgrounds render correctly.
class _SplashSeal extends StatelessWidget {
  final String assetPath;
  const _SplashSeal(this.assetPath, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black, // black bg matches dark theme; seals are transparent PNGs
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        // Shows nothing if PNG not yet placed — does not crash
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}
