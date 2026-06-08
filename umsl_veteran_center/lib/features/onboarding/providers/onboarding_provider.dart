// lib/features/onboarding/providers/onboarding_provider.dart
//
// Controls the three-step onboarding flow:
//   Step 0: Email entry
//   Step 1: Name + Student ID entry
//   Step 2: Welcome screen
//
// Validation rules are intentionally silent — errors are generic.
// Student ID is used only as a validation tool and is never stored.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/secure_storage_service.dart';
import '../../../shared/services/storage_providers.dart';

// ---------------------------------------------------------------------------
// Onboarding step enum
// ---------------------------------------------------------------------------
enum OnboardingStep { email, identity, welcome }

// ---------------------------------------------------------------------------
// State — studentId held temporarily in memory for validation only
// ---------------------------------------------------------------------------
class OnboardingState {
  final OnboardingStep step;
  final String email;
  final String firstName;
  final String lastName;
  final String studentId;   // temporary — never written to storage
  final String? emailError;
  final String? identityError;
  final bool isSaving;

  const OnboardingState({
    this.step        = OnboardingStep.email,
    this.email       = '',
    this.firstName   = '',
    this.lastName    = '',
    this.studentId   = '',
    this.emailError,
    this.identityError,
    this.isSaving    = false,
  });

  OnboardingState copyWith({
    OnboardingStep? step,
    String? email,
    String? firstName,
    String? lastName,
    String? studentId,
    String? emailError,
    String? identityError,
    bool? isSaving,
    bool clearEmailError    = false,
    bool clearIdentityError = false,
  }) {
    return OnboardingState(
      step:          step          ?? this.step,
      email:         email         ?? this.email,
      firstName:     firstName     ?? this.firstName,
      lastName:      lastName      ?? this.lastName,
      //studentId:     studentId     ?? this.studentId,
      emailError:    clearEmailError    ? null : emailError    ?? this.emailError,
      identityError: clearIdentityError ? null : identityError ?? this.identityError,
      isSaving:      isSaving      ?? this.isSaving,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final SecureStorageService _storage;

  OnboardingNotifier(this._storage) : super(const OnboardingState());

  // ---- Step 0: Email -------------------------------------------------------

  void updateEmail(String value) {
    state = state.copyWith(email: value, clearEmailError: true);
  }

  bool submitEmail() {
    final email  = state.email.trim().toLowerCase();
    final parts  = email.split('@');

    if (parts.length != 2) {
      state = state.copyWith(emailError: 'Please enter a valid university email address.');
      return false;
    }

    final local  = parts[0];
    final domain = parts[1];

    if (local.isEmpty || local.length > 7) {
      state = state.copyWith(emailError: 'Please enter a valid university email address.');
      return false;
    }

    if (domain != 'umsl.edu' && domain != 'umsystem.edu') {
      state = state.copyWith(emailError: 'Please enter a valid university email address.');
      return false;
    }

    state = state.copyWith(
      email: email,
      step:  OnboardingStep.identity,
      clearEmailError: true,
    );
    return true;
  }

  // ---- Step 1: Identity ----------------------------------------------------

  void updateFirstName(String value) {
    state = state.copyWith(firstName: value, clearIdentityError: true);
  }

  void updateLastName(String value) {
    state = state.copyWith(lastName: value, clearIdentityError: true);
  }

  void updateStudentId(String value) {
    // Held in memory only — never stored anywhere
    state = state.copyWith(studentId: value, clearIdentityError: true);
  }

  /// Validates all fields. Student ID is checked then immediately discarded.
  /// Only firstName, lastName, and email are written to the Keychain.
  /// Values are passed directly to avoid any state-update timing dependency.
  Future<bool> submitIdentity({
    required String firstName,
    required String lastName,
    required String studentId,
  }) async {
    final first = firstName.trim();
    final last  = lastName.trim();
    final sid   = studentId.trim(); // local variable — dropped after validation

    if (first.isEmpty || last.isEmpty) {
      state = state.copyWith(identityError: 'Please complete all fields.');
      return false;
    }

    // Validate: exactly 8 characters, all digits
    // Using length check + character scan — avoids any regex escape ambiguity
    final isValidId = sid.length == 8 &&
        sid.split('').every((c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57);

    // ignore: avoid_print
    print('DEBUG isValidId=$isValidId');

    if (!isValidId) {
      state = state.copyWith(identityError: 'Please check your Student ID.');
      return false;
    }

    // Validation passed. sid is no longer referenced after this point.
    // Save only name and email — student ID is intentionally omitted.
    state = state.copyWith(isSaving: true);
    try {
      await _storage.saveUserProfile(
        UserProfile(
          email:     state.email,
          firstName: first,
          lastName:  last,
        ),
      );
      await _storage.markOnboardingComplete();
    } catch (_) {
      state = state.copyWith(
        isSaving:      false,
        identityError: 'Something went wrong. Please try again.',
      );
      return false;
    }

    // Advance — clear studentId from state immediately
    state = state.copyWith(
      firstName: first,
      lastName:  last,
      studentId: '',  // cleared — not retained
      step:      OnboardingStep.welcome,
      isSaving:  false,
    );
    return true;
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------
final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final storage = ref.read(secureStorageProvider);
  return OnboardingNotifier(storage);
});
