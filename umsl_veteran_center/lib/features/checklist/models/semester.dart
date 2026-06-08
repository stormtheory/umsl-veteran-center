// lib/features/checklist/models/semester.dart
//
// Models for semesters and summer sub-terms.
// Loaded from assets/data/semesters.json.
//
// Semester lifecycle:
//   before opens_date  → visible in list, grayed out
//   opens_date         → student can set up enrollment
//   start_date         → active / current semester
//   end_date           → ended but still editable
//   lock_date          → read-only forever

class SubTerm {
  final String id;
  final String label;
  final DateTime startDate;
  final DateTime endDate;

  const SubTerm({
    required this.id,
    required this.label,
    required this.startDate,
    required this.endDate,
  });

  factory SubTerm.fromJson(Map<String, dynamic> j) => SubTerm(
        id:        j['id'] as String,
        label:     j['label'] as String,
        startDate: DateTime.parse(j['start_date'] as String),
        endDate:   DateTime.parse(j['end_date'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id':         id,
        'label':      label,
        'start_date': startDate.toIso8601String().substring(0, 10),
        'end_date':   endDate.toIso8601String().substring(0, 10),
      };
}

class Semester {
  final String id;
  final String label;
  final String term;   // "fall" | "spring" | "summer"
  final int year;
  final DateTime opensDate;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime lockDate;
  final List<SubTerm> subTerms; // only populated for summer

  const Semester({
    required this.id,
    required this.label,
    required this.term,
    required this.year,
    required this.opensDate,
    required this.startDate,
    required this.endDate,
    required this.lockDate,
    required this.subTerms,
  });

  factory Semester.fromJson(Map<String, dynamic> j) => Semester(
        id:         j['id'] as String,
        label:      j['label'] as String,
        term:       j['term'] as String,
        year:       j['year'] as int,
        opensDate:  DateTime.parse(j['opens_date'] as String),
        startDate:  DateTime.parse(j['start_date'] as String),
        endDate:    DateTime.parse(j['end_date'] as String),
        lockDate:   DateTime.parse(j['lock_date'] as String),
        subTerms:   (j['sub_terms'] as List<dynamic>? ?? [])
            .map((s) => SubTerm.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  bool get isSummer => term == 'summer';

  // Semester state relative to today
  SemesterState stateOn(DateTime today) {
    if (today.isBefore(opensDate))  return SemesterState.upcoming;
    if (today.isBefore(startDate))  return SemesterState.enrolling;
    if (today.isBefore(endDate))    return SemesterState.active;
    if (today.isBefore(lockDate))   return SemesterState.ended;
    return SemesterState.locked;
  }

  bool get isLocked => stateOn(DateTime.now()) == SemesterState.locked;
  bool get isOpen   => stateOn(DateTime.now()) != SemesterState.upcoming;

  // Human-readable date range
  String get dateRange {
    final s = _fmt(startDate);
    final e = _fmt(endDate);
    return '$s – $e';
  }

  static String _fmt(DateTime d) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month]} ${d.day}';
  }
}

enum SemesterState {
  upcoming,   // before opens_date — grayed out
  enrolling,  // opens_date to start_date — setup available
  active,     // start_date to end_date — current semester
  ended,      // end_date to lock_date — editable but over
  locked,     // after lock_date — read-only
}

extension SemesterStateLabel on SemesterState {
  String get label {
    switch (this) {
      case SemesterState.upcoming:   return 'Not yet open';
      case SemesterState.enrolling:  return 'Registration open';
      case SemesterState.active:     return 'Active';
      case SemesterState.ended:      return 'Ended';
      case SemesterState.locked:     return 'Locked';
    }
  }
}
