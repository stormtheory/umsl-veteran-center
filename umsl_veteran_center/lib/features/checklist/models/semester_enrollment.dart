// lib/features/checklist/models/semester_enrollment.dart
//
// Models for student-owned data stored in device Keychain.
// This is everything the student controls — their enrollment
// setup, task completions, and custom tasks.
//
// Storage key: 'checklist_enrollments' — a JSON array of SemesterEnrollment

import 'benefit.dart';

// ---------------------------------------------------------------------------
// Degree levels
// ---------------------------------------------------------------------------
enum DegreeLevel {
  certificate,
  undergrad,
  graduate,
  doctorate;

  String get label {
    switch (this) {
      case DegreeLevel.certificate: return 'Certificate';
      case DegreeLevel.undergrad:   return 'Undergraduate';
      case DegreeLevel.graduate:    return 'Graduate';
      case DegreeLevel.doctorate:   return 'Doctorate';
    }
  }

  String get id {
    switch (this) {
      case DegreeLevel.certificate: return 'certificate';
      case DegreeLevel.undergrad:   return 'undergrad';
      case DegreeLevel.graduate:    return 'graduate';
      case DegreeLevel.doctorate:   return 'doctorate';
    }
  }

  static DegreeLevel fromId(String id) =>
      DegreeLevel.values.firstWhere((d) => d.id == id,
          orElse: () => DegreeLevel.undergrad);
}

// ---------------------------------------------------------------------------
// Enrollment types
// ---------------------------------------------------------------------------
enum EnrollmentType {
  fullTime,
  halfTime,
  lessThanHalfTime;

  String get label {
    switch (this) {
      case EnrollmentType.fullTime:        return 'Full-time';
      case EnrollmentType.halfTime:        return 'Half-time';
      case EnrollmentType.lessThanHalfTime: return 'Less than half-time';
    }
  }

  String get id {
    switch (this) {
      case EnrollmentType.fullTime:        return 'full_time';
      case EnrollmentType.halfTime:        return 'half_time';
      case EnrollmentType.lessThanHalfTime: return 'less_than_half_time';
    }
  }

  static EnrollmentType fromId(String id) =>
      EnrollmentType.values.firstWhere((e) => e.id == id,
          orElse: () => EnrollmentType.fullTime);
}

// ---------------------------------------------------------------------------
// ChecklistCompletion — one row per task checked off
// ---------------------------------------------------------------------------
class ChecklistCompletion {
  final String taskId;
  final String taskSource; // "benefit", "graduation", "custom"
  bool completed;
  String? completedDate; // ISO date string

  ChecklistCompletion({
    required this.taskId,
    required this.taskSource,
    required this.completed,
    this.completedDate,
  });

  factory ChecklistCompletion.fromJson(Map<String, dynamic> j) =>
      ChecklistCompletion(
        taskId:        j['task_id'] as String,
        taskSource:    j['task_source'] as String,
        completed:     j['completed'] as bool? ?? false,
        completedDate: j['completed_date'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'task_id':        taskId,
        'task_source':    taskSource,
        'completed':      completed,
        'completed_date': completedDate,
      };
}

// ---------------------------------------------------------------------------
// CustomTask — student-created task, flagged as user-generated
// ---------------------------------------------------------------------------
class CustomTask {
  final String id;
  final String title;
  final String note;
  bool completed;
  String? completedDate;
  final String createdDate;
  // is_user_created is always true — this flag drives the "personal task" badge
  final bool isUserCreated = true;

  CustomTask({
    required this.id,
    required this.title,
    required this.note,
    required this.completed,
    this.completedDate,
    required this.createdDate,
  });

  factory CustomTask.fromJson(Map<String, dynamic> j) => CustomTask(
        id:            j['id'] as String,
        title:         j['title'] as String,
        note:          j['note'] as String? ?? '',
        completed:     j['completed'] as bool? ?? false,
        completedDate: j['completed_date'] as String?,
        createdDate:   j['created_date'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id':             id,
        'title':          title,
        'note':           note,
        'completed':      completed,
        'completed_date': completedDate,
        'is_user_created': true,
        'created_date':   createdDate,
      };
}

// ---------------------------------------------------------------------------
// SemesterEnrollment — the student's full setup for one semester
// This is the root object stored in Keychain per semester
// ---------------------------------------------------------------------------
class SemesterEnrollment {
  final String semesterId;
  List<String> benefitIds;       // one or more — Ch.33 + Ch.31 simultaneously
  List<String> subTermIds;       // summer only — which sub-terms they're in
  DegreeLevel degreeLevel;
  EnrollmentType enrollmentType;
  bool isGraduating;
  List<ChecklistCompletion> completions;
  List<CustomTask> customTasks;

  SemesterEnrollment({
    required this.semesterId,
    required this.benefitIds,
    required this.subTermIds,
    required this.degreeLevel,
    required this.enrollmentType,
    required this.isGraduating,
    required this.completions,
    required this.customTasks,
  });

  factory SemesterEnrollment.fromJson(Map<String, dynamic> j) =>
      SemesterEnrollment(
        semesterId:     j['semester_id'] as String,
        benefitIds:     List<String>.from(j['benefit_ids'] as List? ?? []),
        subTermIds:     List<String>.from(j['sub_term_ids'] as List? ?? []),
        degreeLevel:    DegreeLevel.fromId(j['degree_level'] as String? ?? 'undergrad'),
        enrollmentType: EnrollmentType.fromId(j['enrollment_type'] as String? ?? 'full_time'),
        isGraduating:   j['is_graduating'] as bool? ?? false,
        completions: (j['completions'] as List<dynamic>? ?? [])
            .map((c) => ChecklistCompletion.fromJson(c as Map<String, dynamic>))
            .toList(),
        customTasks: (j['custom_tasks'] as List<dynamic>? ?? [])
            .map((t) => CustomTask.fromJson(t as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'semester_id':    semesterId,
        'benefit_ids':    benefitIds,
        'sub_term_ids':   subTermIds,
        'degree_level':   degreeLevel.id,
        'enrollment_type': enrollmentType.id,
        'is_graduating':  isGraduating,
        'completions':    completions.map((c) => c.toJson()).toList(),
        'custom_tasks':   customTasks.map((t) => t.toJson()).toList(),
      };

  // Whether a specific task is completed in this enrollment
  bool isTaskCompleted(String taskId) =>
      completions.any((c) => c.taskId == taskId && c.completed);

  // Toggle completion for a task — creates the record if it doesn't exist
  void toggleTask(String taskId, String taskSource) {
    final existing = completions.where((c) => c.taskId == taskId).toList();
    if (existing.isEmpty) {
      completions.add(ChecklistCompletion(
        taskId:        taskId,
        taskSource:    taskSource,
        completed:     true,
        completedDate: DateTime.now().toIso8601String().substring(0, 10),
      ));
    } else {
      final c = existing.first;
      c.completed = !c.completed;
      c.completedDate = c.completed
          ? DateTime.now().toIso8601String().substring(0, 10)
          : null;
    }
  }

  // Progress as a fraction 0.0 to 1.0 (completed / total official tasks)
  double progress(int totalTasks) {
    if (totalTasks == 0) return 0.0;
    final done = completions.where((c) => c.completed && c.taskSource != 'custom').length;
    return done / totalTasks;
  }
}
