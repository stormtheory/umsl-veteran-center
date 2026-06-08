// lib/features/bah/providers/bah_provider.dart
//
// Loads bah_rates.json and manages all calculator state.
// The calculation itself lives in BahBenefit.calculate() in the model —
// this provider just holds the inputs and triggers recalculation.

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bah_rate.dart';

// ---------------------------------------------------------------------------
// Which semester type the user has selected
// ---------------------------------------------------------------------------
enum SemesterType { regular, summer }

// ---------------------------------------------------------------------------
// Calculator input state — everything the user has set
// ---------------------------------------------------------------------------
class BahInputState {
  final bool loading;
  final String? error;
  final List<BahBenefit> benefits;
  final List<SummerSession> summerSessions;
  final String selectedBenefitId;
  final SemesterType semesterType;
  final String selectedSummerSessionId;
  final bool isGraduate;
  final int creditHours;
  final bool onlineOnly;

  const BahInputState({
    this.loading = true,
    this.error,
    this.benefits = const [],
    this.summerSessions = const [],
    this.selectedBenefitId = 'ch33',
    this.semesterType = SemesterType.regular,
    this.selectedSummerSessionId = '4wk',
    this.isGraduate = false,
    this.creditHours = 12,
    this.onlineOnly = false,
  });

  BahInputState copyWith({
    bool? loading,
    String? error,
    List<BahBenefit>? benefits,
    List<SummerSession>? summerSessions,
    String? selectedBenefitId,
    SemesterType? semesterType,
    String? selectedSummerSessionId,
    bool? isGraduate,
    int? creditHours,
    bool? onlineOnly,
  }) =>
      BahInputState(
        loading:                  loading ?? this.loading,
        error:                    error ?? this.error,
        benefits:                 benefits ?? this.benefits,
        summerSessions:           summerSessions ?? this.summerSessions,
        selectedBenefitId:        selectedBenefitId ?? this.selectedBenefitId,
        semesterType:             semesterType ?? this.semesterType,
        selectedSummerSessionId:  selectedSummerSessionId ?? this.selectedSummerSessionId,
        isGraduate:               isGraduate ?? this.isGraduate,
        creditHours:              creditHours ?? this.creditHours,
        onlineOnly:               onlineOnly ?? this.onlineOnly,
      );

  // Resolved selected benefit — null during loading
  BahBenefit? get selectedBenefit =>
      benefits.where((b) => b.id == selectedBenefitId).isNotEmpty
          ? benefits.firstWhere((b) => b.id == selectedBenefitId)
          : null;

  // Resolved selected summer session
  SummerSession? get selectedSummerSession =>
      summerSessions.where((s) => s.id == selectedSummerSessionId).isNotEmpty
          ? summerSessions.firstWhere((s) => s.id == selectedSummerSessionId)
          : null;

  // Full-time credit hour threshold for the current selection
  int get ftHours {
    if (semesterType == SemesterType.regular) {
      return selectedBenefit?.regularFtHours ?? 12;
    }
    return selectedSummerSession?.ftHours(isGraduate) ??
        selectedBenefit?.regularFtHours ??
        12;
  }

  // Max credit hours for the slider — higher in regular semesters
  int get maxCreditHours {
    if (semesterType == SemesterType.summer) {
      return selectedSummerSession?.maxHours ?? 12;
    }
    return 18;
  }

  // Run the calculation with current inputs
  BahResult? get result => selectedBenefit?.calculate(
        creditHours: creditHours.clamp(1, maxCreditHours),
        ftHours:     ftHours,
        onlineOnly:  onlineOnly,
      );
}

// ---------------------------------------------------------------------------
// BahNotifier
// ---------------------------------------------------------------------------
class BahNotifier extends StateNotifier<BahInputState> {
  BahNotifier() : super(const BahInputState()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final raw  = await rootBundle.loadString('assets/data/bah_rates.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;

      // Parse benefits — keys are the benefit IDs
      final benefitIds = ['ch33', 'ch30', 'ch35', 'ch1606', 'ch31', 'mo_heroes'];
      final benefits = benefitIds
          .where((id) => json.containsKey(id))
          .map((id) => BahBenefit.fromJson(id, json[id] as Map<String, dynamic>))
          .toList();

      final summerSessions = (json['summer_sessions'] as List<dynamic>)
          .map((s) => SummerSession.fromJson(s as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        loading:        false,
        benefits:       benefits,
        summerSessions: summerSessions,
        // Default to first benefit (ch33) and 12 credit hours
        selectedBenefitId: 'ch33',
        creditHours:    12,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void selectBenefit(String id) {
    // Reset credit hours when switching benefits to avoid stale slider position
    final newState = state.copyWith(selectedBenefitId: id);
    final ftHrs    = newState.ftHours;
    state = newState.copyWith(
      creditHours: state.creditHours.clamp(1, newState.maxCreditHours),
    );
  }

  void selectSemesterType(SemesterType type) {
    state = state.copyWith(semesterType: type);
    // Clamp credit hours to new max
    state = state.copyWith(
      creditHours: state.creditHours.clamp(1, state.maxCreditHours),
    );
  }

  void selectSummerSession(String id) {
    state = state.copyWith(selectedSummerSessionId: id);
    // Clamp credit hours to new session's max
    state = state.copyWith(
      creditHours: state.creditHours.clamp(1, state.maxCreditHours),
    );
  }

  void setCreditHours(int hours) {
    state = state.copyWith(
      creditHours: hours.clamp(1, state.maxCreditHours),
    );
  }

  void setOnlineOnly(bool value) =>
      state = state.copyWith(onlineOnly: value);

  void setIsGraduate(bool value) {
    state = state.copyWith(isGraduate: value);
    // Clamp in case graduate FT threshold is lower
    state = state.copyWith(
      creditHours: state.creditHours.clamp(1, state.maxCreditHours),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------
final bahProvider = StateNotifierProvider<BahNotifier, BahInputState>(
  (ref) => BahNotifier(),
);
