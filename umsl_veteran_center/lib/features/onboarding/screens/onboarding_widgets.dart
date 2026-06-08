// lib/features/onboarding/screens/onboarding_widgets.dart
//
// Shared widgets used across all three onboarding screens.
// Extracted here so they can be imported by any screen without
// relying on cross-file access to private (_) symbols.

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Small logo + center name header shown at the top of each onboarding step
// ---------------------------------------------------------------------------
class OnboardingHeader extends StatelessWidget {
  // step is kept as a parameter for future use (e.g. analytics)
  // but is not visually rendered in the header itself
  final int step;
  const OnboardingHeader({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF8B0000),
            border: Border.all(
              color: const Color(0xFFC0A060),
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/vetcenter_Logo.png',
              fit: BoxFit.cover,
              // Fallback if asset not yet in place
              errorBuilder: (_, __, ___) => const Center(
                child: Text(
                  'V',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'UMSL VET CENTER',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: isDark
                ? const Color(0xFFC0A060)
                : const Color(0xFF8B0000),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Three-step progress dots — active dot is wider and gold
// ---------------------------------------------------------------------------
class OnboardingStepDots extends StatelessWidget {
  final int currentStep; // 0, 1, or 2
  const OnboardingStepDots({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final isActive = i == currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(right: 5),
          width: isActive ? 28 : 16,
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: isActive
                ? const Color(0xFFC0A060) // gold when active
                : const Color(0xFF2A2A3A), // muted when inactive
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Privacy disclosure box shown on the email step
// ---------------------------------------------------------------------------
class OnboardingPrivacyDisclaimer extends StatelessWidget {
  const OnboardingPrivacyDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F1A0F)
            : const Color(0xFFF0FFF0),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1A3A1A)
              : const Color(0xFFA8D5A8),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline,
            size: 16,
            color: isDark
                ? const Color(0xFF5A8A5A)
                : const Color(0xFF2E7D32),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'All data is stored locally on this device only. '
              'Nothing is transmitted externally. '
              'Your information is protected under FERPA and applicable privacy law.',
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: isDark
                    ? const Color(0xFF5A8A5A)
                    : const Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gold/red uppercase field label used on the identity screen
// ---------------------------------------------------------------------------
class OnboardingFieldLabel extends StatelessWidget {
  final String text;
  const OnboardingFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: isDark
            ? const Color(0xFFC0A060)
            : const Color(0xFF8B0000),
      ),
    );
  }
}
