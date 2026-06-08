// lib/features/onboarding/screens/onboarding_identity_screen.dart
//
// Step 2 of onboarding: first name, last name, and student ID.
//
// Validation is intentionally silent:
//   - First/last name cannot be empty
//   - Student ID must be exactly 8 digits, stored as String (not int)
//   - Error message never explains the digit count rule

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'onboarding_welcome_screen.dart';
import 'onboarding_widgets.dart';

class OnboardingIdentityScreen extends ConsumerStatefulWidget {
  const OnboardingIdentityScreen({super.key});

  @override
  ConsumerState<OnboardingIdentityScreen> createState() =>
      _OnboardingIdentityScreenState();
}

class _OnboardingIdentityScreenState
    extends ConsumerState<OnboardingIdentityScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _studentIdController = TextEditingController();

  final _lastNameFocus = FocusNode();
  final _studentIdFocus = FocusNode();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _studentIdController.dispose();
    _lastNameFocus.dispose();
    _studentIdFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final notifier = ref.read(onboardingProvider.notifier);
    // Pass all values directly — eliminates any state update timing concern
    final saved = await notifier.submitIdentity(
      firstName: _firstNameController.text,
      lastName:  _lastNameController.text,
      studentId: _studentIdController.text,
    );
    if (saved && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const OnboardingWelcomeScreen(),
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
                // Shared header widget — now public, lives in onboarding_widgets.dart
                const OnboardingHeader(step: 1),
                const SizedBox(height: 32),
                // Shared step dots widget
                const OnboardingStepDots(currentStep: 1),
                const SizedBox(height: 24),
                Text(
                  'Tell us about you.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0D0D14),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This helps us personalize your experience. '
                  'Stored securely on-device only.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                ),
                const SizedBox(height: 28),
                // First + last name row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const OnboardingFieldLabel('First Name'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _firstNameController,
                            autofocus: true,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => FocusScope.of(context)
                                .requestFocus(_lastNameFocus),
                            onChanged: (v) => ref
                                .read(onboardingProvider.notifier)
                                .updateFirstName(v),
                            decoration:
                                const InputDecoration(hintText: 'First'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const OnboardingFieldLabel('Last Name'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _lastNameController,
                            focusNode: _lastNameFocus,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => FocusScope.of(context)
                                .requestFocus(_studentIdFocus),
                            onChanged: (v) => ref
                                .read(onboardingProvider.notifier)
                                .updateLastName(v),
                            decoration:
                                const InputDecoration(hintText: 'Last'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Student ID field
                const OnboardingFieldLabel('Student ID'),
                const SizedBox(height: 6),
                TextField(
                  controller: _studentIdController,
                  focusNode: _studentIdFocus,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  onChanged: (v) => ref
                      .read(onboardingProvider.notifier)
                      .updateStudentId(v),
                  // Silently limit length — never reveal the 8-digit rule
                  // Digits only — no length cap shown to user
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    hintText: 'Enter your Student ID',
                    // Generic error — never mentions digit count
                    errorText: state.identityError,
                  ),
                ),
                const SizedBox(height: 12),
                // Generic note — does not reveal the 8-digit constraint
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A1A0F)
                        : const Color(0xFFFFFDE7),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF3A3A1A)
                          : const Color(0xFFF9A825),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'All fields are required. '
                    'Student ID must be numeric.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: isDark
                          ? const Color(0xFF8A8A50)
                          : const Color(0xFF795548),
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB22222),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          const Color(0xFFB22222).withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: state.isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
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
