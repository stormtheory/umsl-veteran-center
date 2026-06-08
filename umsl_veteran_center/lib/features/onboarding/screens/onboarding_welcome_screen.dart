// lib/features/onboarding/screens/onboarding_welcome_screen.dart
//
// Step 3 (final) of onboarding: personalized welcome screen.
// Shows UMSL logo, NDSM ribbon, official branch seals, and branch tags.
// Tapping "Enter the Center" clears the back stack and goes to HomeScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shell/main_shell.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/onboarding_provider.dart';
import '../../../core/theme/app_theme.dart';

// Seal asset manifest — one place to update if filenames change
const _sealAssets = [
  (path: 'assets/seals/seal_army.png',      label: 'Army'),
  (path: 'assets/seals/seal_navy.png',       label: 'Navy'),
  (path: 'assets/seals/seal_marines.png',    label: 'Marines'),
  (path: 'assets/seals/seal_airforce.png',   label: 'Air Force'),
  (path: 'assets/seals/seal_coastguard.png', label: 'Coast Guard'),
  (path: 'assets/seals/seal_spaceforce.png', label: 'Space Force'),
];

class OnboardingWelcomeScreen extends ConsumerWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstName =
        state.firstName.isNotEmpty ? state.firstName : 'Veteran';

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 36),

              // Official UMSL Veterans Center logo
              _UmslLogoCircle(isDark: isDark),

              const SizedBox(height: 16),

              // NDSM ribbon bar — SVG ribbon only, no hand-drawn medal art
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SvgPicture.asset(
                  'assets/svg/ndsm_ribbon.svg',
                  width: 120,
                  height: 28,
                  fit: BoxFit.fill,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "You're all set, $firstName.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color:
                          isDark ? Colors.white : const Color(0xFF0D0D14),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome to the UMSL Veterans Center.\nWe serve those who served.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white60 : Colors.black54,
                      height: 1.6,
                    ),
              ),

              const SizedBox(height: 28),

              // Official military branch seals — real PNGs from assets/seals/
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _sealAssets
                          .take(3)
                          .map((s) => _SealCircle(
                                assetPath: s.path,
                                label: s.label,
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _sealAssets
                          .skip(3)
                          .map((s) => _SealCircle(
                                assetPath: s.path,
                                label: s.label,
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Who this app serves
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _Tag('Veterans'),
                  _Tag('Active Duty'),
                  _Tag('Dependents'),
                  _Tag('Family Members'),
                  _Tag('Guard and Reserve'),
                ],
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: replace with context.go('/home') once go_router is wired
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const MainShell(),
                      ),
                      (_) => false, // clear entire back stack
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB22222),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'ENTER THE CENTER',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
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
// UMSL logo clipped to circle
// ---------------------------------------------------------------------------
class _UmslLogoCircle extends StatelessWidget {
  final bool isDark;
  const _UmslLogoCircle({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF8B0000), width: 3),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: const Color(0xFF8B0000).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/vetcenter_Logo.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF8B0000),
            child: const Center(
              child: Text(
                'UMSL\nVet Center',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// One seal clipped to a circle
// ---------------------------------------------------------------------------
class _SealCircle extends StatelessWidget {
  final String assetPath;
  final String label;
  const _SealCircle({required this.assetPath, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          // Black background — seals have transparent backgrounds after processing
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF1a1a2e),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.white54,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Status/group tag pill
// ---------------------------------------------------------------------------
class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1A2E)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2A2A3A)
              : const Color(0xFFDDDDDD),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }
}
