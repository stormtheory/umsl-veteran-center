// lib/features/checklist/models/benefit.dart
//
// Models for benefit programs and their associated tasks.
// Loaded from assets/data/benefits.json and benefit_tasks.json.
// These are read-only — the Vet Center edits the JSON to update them.

// ---------------------------------------------------------------------------
// Benefit — one row per program (Ch. 33, Ch. 30, etc.)
// ---------------------------------------------------------------------------
class Benefit {
  final String id;
  final String name;
  final String shortName;
  final String chapter;
  final String color;
  final String description;
  final String eligibilityNote;
  final String appliesToDegrees; // "all" or comma-separated degree levels

  const Benefit({
    required this.id,
    required this.name,
    required this.shortName,
    required this.chapter,
    required this.color,
    required this.description,
    required this.eligibilityNote,
    required this.appliesToDegrees,
  });

  factory Benefit.fromJson(Map<String, dynamic> j) => Benefit(
        id:               j['id'] as String,
        name:             j['name'] as String,
        shortName:        j['short_name'] as String,
        chapter:          j['chapter'] as String,
        color:            j['color'] as String? ?? 'gray',
        description:      j['description'] as String? ?? '',
        eligibilityNote:  j['eligibility_note'] as String? ?? '',
        appliesToDegrees: j['applies_to_degrees'] as String? ?? 'all',
      );

  // Whether this benefit applies to the given degree level
  bool appliesTo(String degreeLevel) {
    if (appliesToDegrees == 'all') return true;
    return appliesToDegrees.split(',').map((s) => s.trim()).contains(degreeLevel);
  }
}

// ---------------------------------------------------------------------------
// TaskLink — up to two links per task
// ---------------------------------------------------------------------------
class TaskLink {
  final String label;
  final String url;
  const TaskLink({required this.label, required this.url});

  factory TaskLink.fromJson(Map<String, dynamic> j) => TaskLink(
        label: j['label'] as String,
        url:   j['url'] as String,
      );

  Map<String, dynamic> toJson() => {'label': label, 'url': url};
}

// ---------------------------------------------------------------------------
// BenefitTask — an official task from benefit_tasks.json
// ---------------------------------------------------------------------------
class BenefitTask {
  final String id;
  final String benefitId;
  final String category;
  final String title;
  final String description;
  final String appliesTo;   // "all" or comma-separated degree levels
  final bool required;
  final int? dueOffsetDays; // days relative to semester/sub-term start_date
  final String? dueLabel;   // human-readable label for the deadline
  final String? dueDate;    // fixed ISO date — overrides offset if present
  final List<TaskLink> links; // max 2

  const BenefitTask({
    required this.id,
    required this.benefitId,
    required this.category,
    required this.title,
    required this.description,
    required this.appliesTo,
    required this.required,
    this.dueOffsetDays,
    this.dueLabel,
    this.dueDate,
    required this.links,
  });

  factory BenefitTask.fromJson(Map<String, dynamic> j) => BenefitTask(
        id:            j['id'] as String,
        benefitId:     j['benefit_id'] as String,
        category:      j['category'] as String,
        title:         j['title'] as String,
        description:   j['description'] as String? ?? '',
        appliesTo:     j['applies_to'] as String? ?? 'all',
        required:      j['required'] as bool? ?? false,
        dueOffsetDays: j['due_offset_days'] as int?,
        dueLabel:      j['due_label'] as String?,
        dueDate:       j['due_date'] as String?,
        links: (j['links'] as List<dynamic>? ?? [])
            .take(2) // enforce max 2 links
            .map((l) => TaskLink.fromJson(l as Map<String, dynamic>))
            .toList(),
      );

  // Whether this task applies to the given degree level
  bool appliesToDegree(String degreeLevel) {
    if (appliesTo == 'all') return true;
    return appliesTo.split(',').map((s) => s.trim()).contains(degreeLevel);
  }

  // Compute the actual deadline DateTime given a semester start date
  // Fixed due_date takes priority over offset
  DateTime? deadlineFor(DateTime semesterStart) {
    if (dueDate != null && dueDate!.isNotEmpty) {
      return DateTime.tryParse(dueDate!);
    }
    if (dueOffsetDays != null) {
      return semesterStart.add(Duration(days: dueOffsetDays!));
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// GraduationTask — from graduation_tasks.json
// Same shape as BenefitTask but no benefitId
// ---------------------------------------------------------------------------
class GraduationTask {
  final String id;
  final String category;
  final String title;
  final String description;
  final String appliesTo;
  final int? dueOffsetDays;
  final String? dueLabel;
  final String? dueDate;
  final List<TaskLink> links;

  const GraduationTask({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.appliesTo,
    this.dueOffsetDays,
    this.dueLabel,
    this.dueDate,
    required this.links,
  });

  factory GraduationTask.fromJson(Map<String, dynamic> j) => GraduationTask(
        id:            j['id'] as String,
        category:      j['category'] as String,
        title:         j['title'] as String,
        description:   j['description'] as String? ?? '',
        appliesTo:     j['applies_to'] as String? ?? 'all',
        dueOffsetDays: j['due_offset_days'] as int?,
        dueLabel:      j['due_label'] as String?,
        dueDate:       j['due_date'] as String?,
        links: (j['links'] as List<dynamic>? ?? [])
            .take(2)
            .map((l) => TaskLink.fromJson(l as Map<String, dynamic>))
            .toList(),
      );

  bool appliesToDegree(String degreeLevel) {
    if (appliesTo == 'all') return true;
    return appliesTo.split(',').map((s) => s.trim()).contains(degreeLevel);
  }

  DateTime? deadlineFor(DateTime semesterEnd) {
    if (dueDate != null && dueDate!.isNotEmpty) {
      return DateTime.tryParse(dueDate!);
    }
    if (dueOffsetDays != null) {
      // Graduation tasks offset from semester END date
      return semesterEnd.add(Duration(days: dueOffsetDays!));
    }
    return null;
  }
}
