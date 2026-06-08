// lib/features/checklist/providers/checklist_provider.dart
//
// Central provider for the checklist feature.
// Loads benefits, tasks, semesters, and graduation tasks from JSON assets.
// Manages student enrollment data in device Keychain via SecureStorageService.
//
// Key design decisions:
//   - JSON assets are read-only templates (official tasks from Vet Center)
//   - Student data (enrollments, completions, custom tasks) lives in Keychain
//   - Task list for a semester is built dynamically from enrollment settings
//   - Disclaimer accepted flag stored separately in Keychain

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/benefit.dart';
import '../models/semester.dart';
import '../models/semester_enrollment.dart';
import '../../../shared/services/secure_storage_service.dart';
import '../../../shared/services/storage_providers.dart';

// ---------------------------------------------------------------------------
// Storage keys
// ---------------------------------------------------------------------------
const _kEnrollments        = 'checklist_enrollments';
const _kDisclaimerAccepted = 'checklist_disclaimer_accepted';

// ---------------------------------------------------------------------------
// ChecklistState — everything the UI needs in one place
// ---------------------------------------------------------------------------
class ChecklistState {
  final bool loading;
  final bool disclaimerAccepted;
  final List<Benefit> benefits;
  final List<BenefitTask> benefitTasks;
  final List<GraduationTask> graduationTasks;
  final List<Semester> semesters;
  final List<SemesterEnrollment> enrollments;
  final String? error;

  const ChecklistState({
    this.loading = true,
    this.disclaimerAccepted = false,
    this.benefits = const [],
    this.benefitTasks = const [],
    this.graduationTasks = const [],
    this.semesters = const [],
    this.enrollments = const [],
    this.error,
  });

  ChecklistState copyWith({
    bool? loading,
    bool? disclaimerAccepted,
    List<Benefit>? benefits,
    List<BenefitTask>? benefitTasks,
    List<GraduationTask>? graduationTasks,
    List<Semester>? semesters,
    List<SemesterEnrollment>? enrollments,
    String? error,
  }) =>
      ChecklistState(
        loading:            loading ?? this.loading,
        disclaimerAccepted: disclaimerAccepted ?? this.disclaimerAccepted,
        benefits:           benefits ?? this.benefits,
        benefitTasks:       benefitTasks ?? this.benefitTasks,
        graduationTasks:    graduationTasks ?? this.graduationTasks,
        semesters:          semesters ?? this.semesters,
        enrollments:        enrollments ?? this.enrollments,
        error:              error ?? this.error,
      );

  // Enrollment for a specific semester — null if not set up yet
  SemesterEnrollment? enrollmentFor(String semesterId) =>
      enrollments.where((e) => e.semesterId == semesterId).isNotEmpty
          ? enrollments.firstWhere((e) => e.semesterId == semesterId)
          : null;

  // Build the full filtered task list for a semester enrollment
  // Returns tasks grouped by category
  Map<String, List<_TaskEntry>> buildTaskList(SemesterEnrollment enrollment, Semester semester) {
    final tasks = <_TaskEntry>[];

    // Benefit tasks — one per benefit the student is using
    for (final benefitId in enrollment.benefitIds) {
      final relevantTasks = benefitTasks
          .where((t) =>
              t.benefitId == benefitId &&
              t.appliesToDegree(enrollment.degreeLevel.id))
          .toList();

      for (final task in relevantTasks) {
        // For summer: calculate deadline per selected sub-term if applicable
        DateTime? deadline;
        if (semester.isSummer && enrollment.subTermIds.isNotEmpty) {
          // Use earliest sub-term start for the deadline calculation
          final selectedSubTerms = semester.subTerms
              .where((s) => enrollment.subTermIds.contains(s.id))
              .toList()
            ..sort((a, b) => a.startDate.compareTo(b.startDate));
          if (selectedSubTerms.isNotEmpty) {
            deadline = task.deadlineFor(selectedSubTerms.first.startDate);
          }
        } else {
          deadline = task.deadlineFor(semester.startDate);
        }

        tasks.add(_TaskEntry(
          taskId:   task.id,
          source:   'benefit',
          category: task.category,
          title:    task.title,
          description: task.description,
          required: task.required,
          deadline: deadline,
          dueLabel: task.dueLabel,
          links:    task.links,
          benefitId: benefitId,
        ));
      }
    }

    // Graduation tasks — only if is_graduating
    if (enrollment.isGraduating) {
      for (final task in graduationTasks
          .where((t) => t.appliesToDegree(enrollment.degreeLevel.id))) {
        tasks.add(_TaskEntry(
          taskId:      task.id,
          source:      'graduation',
          category:    'Graduation — ${task.category}',
          title:       task.title,
          description: task.description,
          required:    true,
          deadline:    task.deadlineFor(semester.endDate),
          dueLabel:    task.dueLabel,
          links:       task.links,
        ));
      }
    }

    // Group by category
    final grouped = <String, List<_TaskEntry>>{};
    for (final t in tasks) {
      grouped.putIfAbsent(t.category, () => []).add(t);
    }

    return grouped;
  }
}

// ---------------------------------------------------------------------------
// _TaskEntry — a resolved task with computed deadline
// ---------------------------------------------------------------------------
class _TaskEntry {
  final String taskId;
  final String source;
  final String category;
  final String title;
  final String description;
  final bool required;
  final DateTime? deadline;
  final String? dueLabel;
  final List<TaskLink> links;
  final String? benefitId;

  const _TaskEntry({
    required this.taskId,
    required this.source,
    required this.category,
    required this.title,
    required this.description,
    required this.required,
    this.deadline,
    this.dueLabel,
    required this.links,
    this.benefitId,
  });
}

// Export _TaskEntry as TaskEntry for widgets to use
typedef TaskEntry = _TaskEntry;

// ---------------------------------------------------------------------------
// ChecklistNotifier
// ---------------------------------------------------------------------------
class ChecklistNotifier extends StateNotifier<ChecklistState> {
  final SecureStorageService _storage;

  ChecklistNotifier(this._storage) : super(const ChecklistState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      // Load all JSON assets in parallel
      final results = await Future.wait([
        rootBundle.loadString('assets/data/benefits.json'),
        rootBundle.loadString('assets/data/benefit_tasks.json'),
        rootBundle.loadString('assets/data/graduation_tasks.json'),
        rootBundle.loadString('assets/data/semesters.json'),
      ]);

      final benefits = (jsonDecode(results[0]) as List)
          .map((j) => Benefit.fromJson(j as Map<String, dynamic>))
          .toList();

      final benefitTasks = (jsonDecode(results[1]) as List)
          .map((j) => BenefitTask.fromJson(j as Map<String, dynamic>))
          .toList();

      final graduationTasks = (jsonDecode(results[2]) as List)
          .map((j) => GraduationTask.fromJson(j as Map<String, dynamic>))
          .toList();

      final semesters = (jsonDecode(results[3]) as List)
          .map((j) => Semester.fromJson(j as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));

      // Load student data from Keychain
      final enrollmentsJson = await _storage.read(_kEnrollments);
      final enrollments = enrollmentsJson != null
          ? (jsonDecode(enrollmentsJson) as List)
              .map((j) => SemesterEnrollment.fromJson(j as Map<String, dynamic>))
              .toList()
          : <SemesterEnrollment>[];

      // Check disclaimer flag
      final disclaimerRaw = await _storage.read(_kDisclaimerAccepted);
      final disclaimerAccepted = disclaimerRaw == 'true';

      state = state.copyWith(
        loading:            false,
        disclaimerAccepted: disclaimerAccepted,
        benefits:           benefits,
        benefitTasks:       benefitTasks,
        graduationTasks:    graduationTasks,
        semesters:          semesters,
        enrollments:        enrollments,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Disclaimer
  // ---------------------------------------------------------------------------
  Future<void> acceptDisclaimer() async {
    await _storage.write(_kDisclaimerAccepted, 'true');
    state = state.copyWith(disclaimerAccepted: true);
  }

  // ---------------------------------------------------------------------------
  // Enrollment management
  // ---------------------------------------------------------------------------

  // Create or fully replace enrollment settings for a semester
  // Called from semester_setup_screen.dart on both first setup and edits
  Future<void> saveEnrollment(SemesterEnrollment enrollment) async {
    final updated = state.enrollments
        .where((e) => e.semesterId != enrollment.semesterId)
        .toList()
      ..add(enrollment);
    await _persistEnrollments(updated);
    state = state.copyWith(enrollments: updated);
  }

  // Toggle a task completion — works on any unlocked semester
  Future<void> toggleTask({
    required String semesterId,
    required String taskId,
    required String taskSource,
  }) async {
    final enrollment = state.enrollmentFor(semesterId);
    if (enrollment == null) return;

    enrollment.toggleTask(taskId, taskSource);
    await _persistEnrollments(state.enrollments);
    // Trigger rebuild by replacing the list reference
    state = state.copyWith(enrollments: List.from(state.enrollments));
  }

  // Add a custom task to a semester
  Future<void> addCustomTask({
    required String semesterId,
    required String title,
    required String note,
  }) async {
    final enrollment = state.enrollmentFor(semesterId);
    if (enrollment == null) return;

    final task = CustomTask(
      id:          'custom_${DateTime.now().millisecondsSinceEpoch}',
      title:       title,
      note:        note,
      completed:   false,
      createdDate: DateTime.now().toIso8601String().substring(0, 10),
    );

    enrollment.customTasks.add(task);
    await _persistEnrollments(state.enrollments);
    state = state.copyWith(enrollments: List.from(state.enrollments));
  }

  // Toggle a custom task completion
  Future<void> toggleCustomTask({
    required String semesterId,
    required String taskId,
  }) async {
    final enrollment = state.enrollmentFor(semesterId);
    if (enrollment == null) return;

    final task = enrollment.customTasks.where((t) => t.id == taskId).toList();
    if (task.isEmpty) return;

    task.first.completed = !task.first.completed;
    task.first.completedDate = task.first.completed
        ? DateTime.now().toIso8601String().substring(0, 10)
        : null;

    await _persistEnrollments(state.enrollments);
    state = state.copyWith(enrollments: List.from(state.enrollments));
  }

  // Delete a custom task
  Future<void> deleteCustomTask({
    required String semesterId,
    required String taskId,
  }) async {
    final enrollment = state.enrollmentFor(semesterId);
    if (enrollment == null) return;

    enrollment.customTasks.removeWhere((t) => t.id == taskId);
    await _persistEnrollments(state.enrollments);
    state = state.copyWith(enrollments: List.from(state.enrollments));
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------
  Future<void> _persistEnrollments(List<SemesterEnrollment> enrollments) async {
    final json = jsonEncode(enrollments.map((e) => e.toJson()).toList());
    await _storage.write(_kEnrollments, json);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------
final checklistProvider =
    StateNotifierProvider<ChecklistNotifier, ChecklistState>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ChecklistNotifier(storage);
});
