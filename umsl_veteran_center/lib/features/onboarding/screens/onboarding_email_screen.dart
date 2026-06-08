// lib/features/onboarding/screens/onboarding_email_screen.dart
//
// Step 1 of onboarding: university email entry.
//
// Validation is intentionally silent — the error message is generic.
// The user is never told the specific constraints (local part length
// or which domains are accepted).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'onboarding_identity_screen.dart';
import 'onboarding_widgets.dart';

class OnboardingEmailScreen extends ConsumerStatefulWidget {
  const OnboardingEmailScreen({super.key});

  @override
  ConsumerState<OnboardingEmailScreen> createState() =>
      _OnboardingEmailScreenState();
}

class _OnboardingEmailScreenState
    extends ConsumerState<OnboardingEmailScreen> {
  final _emailController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    // Sync text field value into the provider before validating
    ref
        .read(onboardingProvider.notifier)
        .updateEmail(_emailController.text);

    final advanced = ref.read(onboardingProvider.notifier).submitEmail();
    if (advanced && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const OnboardingIdentityScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                const OnboardingHeader(step: 0),
                const SizedBox(height: 32),
                const OnboardingStepDots(currentStep: 0),
                const SizedBox(height: 24),
                Text(
                  'Welcome, Veteran.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0D0D14),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your university email to get started.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                ),
                const SizedBox(height: 28),
                // University Email field label
                const OnboardingFieldLabel('University Email'),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailController,
                  focusNode: _focusNode,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  onChanged: (v) =>
                      ref.read(onboardingProvider.notifier).updateEmail(v),
                  decoration: InputDecoration(
                    hintText: 'yourname@umsl.edu',
                    prefixIcon: const Icon(Icons.email_outlined),
                    // Generic error — never reveals the exact validation rules
                    errorText: state.emailError,
                  ),
                ),
                const SizedBox(height: 20),
                const OnboardingPrivacyDisclaimer(),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB22222),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'CONTINUE',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
