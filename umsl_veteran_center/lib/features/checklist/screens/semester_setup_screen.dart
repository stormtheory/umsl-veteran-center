// lib/features/checklist/screens/semester_setup_screen.dart
//
// Setup screen for a semester enrollment.
// Used both for first-time setup AND editing existing enrollment
// (as long as the semester is not locked).
//
// Collects:
//   1. Benefits (multi-select — one or more)
//   2. Degree level
//   3. Enrollment type
//   4. Sub-terms (summer only — multi-select)
//   5. Graduating this semester?

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/semester.dart';
import '../models/semester_enrollment.dart';
import '../models/benefit.dart';
import '../providers/checklist_provider.dart';
import 'checklist_detail_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vet_theme.dart';

class SemesterSetupScreen extends ConsumerStatefulWidget {
  final Semester semester;

  const SemesterSetupScreen({super.key, required this.semester});

  @override
  ConsumerState<SemesterSetupScreen> createState() =>
      _SemesterSetupScreenState();
}

class _SemesterSetupScreenState extends ConsumerState<SemesterSetupScreen> {
  late Set<String> _selectedBenefits;
  late Set<String> _selectedSubTerms;
  late DegreeLevel _degreeLevel;
  late EnrollmentType _enrollmentType;
  late bool _isGraduating;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill from existing enrollment if editing
    final state      = ref.read(checklistProvider);
    final existing   = state.enrollmentFor(widget.semester.id);

    _selectedBenefits = Set.from(existing?.benefitIds ?? []);
    _selectedSubTerms = Set.from(existing?.subTermIds ?? []);
    _degreeLevel      = existing?.degreeLevel ?? DegreeLevel.undergrad;
    _enrollmentType   = existing?.enrollmentType ?? EnrollmentType.fullTime;
    _isGraduating     = existing?.isGraduating ?? false;
  }

  bool get _canSave => _selectedBenefits.isNotEmpty;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);

    final state    = ref.read(checklistProvider);
    final existing = state.enrollmentFor(widget.semester.id);

    // Preserve existing completions and custom tasks when editing
    final enrollment = SemesterEnrollment(
      semesterId:     widget.semester.id,
      benefitIds:     _selectedBenefits.toList(),
      subTermIds:     _selectedSubTerms.toList(),
      degreeLevel:    _degreeLevel,
      enrollmentType: _enrollmentType,
      isGraduating:   _isGraduating,
      completions:    existing?.completions ?? [],
      customTasks:    existing?.customTasks ?? [],
    );

    await ref.read(checklistProvider.notifier).saveEnrollment(enrollment);

    if (mounted) {
      // Replace this screen with the detail screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChecklistDetailScreen(semester: widget.semester),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    final state    = ref.watch(checklistProvider);
    final benefits = state.benefits;
    final isEditing = state.enrollmentFor(widget.semester.id) != null;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        foregroundColor: t.textOnDark,
        elevation: 0,
        title: Text(
          isEditing ? 'Edit ${widget.semester.label}' : widget.semester.label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          const SizedBox(height: 4),
          _SectionHeader(
            title: 'Which benefit(s) are you using this semester?',
            subtitle: 'Select all that apply',
          ),
          const SizedBox(height: 10),
          ...benefits.map((b) => _BenefitToggle(
                benefit: b,
                selected: _selectedBenefits.contains(b.id),
                degreeLevel: _degreeLevel.id,
                onTap: () => setState(() {
                  if (_selectedBenefits.contains(b.id)) {
                    _selectedBenefits.remove(b.id);
                  } else {
                    _selectedBenefits.add(b.id);
                  }
                }),
              )),

          const SizedBox(height: 20),
          _SectionHeader(title: 'Degree level'),
          const SizedBox(height: 10),
          _SegmentRow<DegreeLevel>(
            options: DegreeLevel.values,
            selected: _degreeLevel,
            label: (d) => d.label,
            onTap: (d) => setState(() => _degreeLevel = d),
          ),

          const SizedBox(height: 20),
          _SectionHeader(title: 'Enrollment type'),
          const SizedBox(height: 10),
          _SegmentRow<EnrollmentType>(
            options: EnrollmentType.values,
            selected: _enrollmentType,
            label: (e) => e.label,
            onTap: (e) => setState(() => _enrollmentType = e),
          ),

          // Sub-terms — summer only
          if (widget.semester.isSummer) ...[
            const SizedBox(height: 20),
            _SectionHeader(
              title: 'Which summer term(s) are you enrolled in?',
              subtitle: 'Select all that apply',
            ),
            const SizedBox(height: 10),
            ...widget.semester.subTerms.map((s) => _SubTermToggle(
                  subTerm: s,
                  selected: _selectedSubTerms.contains(s.id),
                  onTap: () => setState(() {
                    if (_selectedSubTerms.contains(s.id)) {
                      _selectedSubTerms.remove(s.id);
                    } else {
                      _selectedSubTerms.add(s.id);
                    }
                  }),
                )),
          ],

          SizedBox(height: 20),
          _SectionHeader(title: 'Are you graduating this semester?'),
          SizedBox(height: 10),
          _GraduatingToggle(
            value: _isGraduating,
            onChanged: (v) => setState(() => _isGraduating = v),
          ),

          SizedBox(height: 8),
          // Disclaimer reminder
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t.cardBackground.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: t.cardBorder),
            ),
            child: Text(
              'Dates and deadlines are estimates. Verify all requirements '
              'directly with the Vet Center and the VA.',
              style: TextStyle(
                fontSize: 11,
                color: t.textTertiary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: t.pageBackground,
        padding: EdgeInsets.fromLTRB(
          16, 10, 16,
          MediaQuery.of(context).padding.bottom + 10,
        ),
        child: ElevatedButton(
          onPressed: (_canSave && !_saving) ? _save : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryRed,
            foregroundColor: Colors.white,
            disabledBackgroundColor: t.cardBorder,
            disabledForegroundColor: t.textTertiary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _saving
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: t.textPrimary,
                  ),
                )
              : Text(
                  isEditing ? 'Save changes' : 'Set up my checklist',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: t.textPrimary,
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle!,
              style: TextStyle(fontSize: 12, color: t.textTertiary),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Benefit toggle row
// ---------------------------------------------------------------------------
class _BenefitToggle extends StatelessWidget {
  final Benefit benefit;
  final bool selected;
  final String degreeLevel;
  final VoidCallback onTap;

  const _BenefitToggle({
    required this.benefit,
    required this.selected,
    required this.degreeLevel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    final applies = benefit.appliesTo(degreeLevel);

    return GestureDetector(
      onTap: applies ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: applies ? 1.0 : 0.35,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.accentGold.withOpacity(0.08)
                : const Color(0xFF13131F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppTheme.accentGold.withOpacity(0.4)
                  : t.cardBorder,
            ),
          ),
          child: Row(
            children: [
              // Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: selected ? AppTheme.accentGold : Colors.transparent,
                  border: Border.all(
                    color: selected ? AppTheme.accentGold : Colors.white38,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check, size: 12, color: Colors.black)
                    : null,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                          '${benefit.shortName}  ·  ${benefit.name}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: t.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    if (!applies)
                      Text(
                        'Not available for your degree level',
                        style: TextStyle(fontSize: 11, color: t.textTertiary),
                      )
                    else
                      Text(
                        benefit.chapter,
                        style: TextStyle(
                          fontSize: 11,
                          color: t.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Generic segment row for degree level and enrollment type
// ---------------------------------------------------------------------------
class _SegmentRow<T> extends StatelessWidget {
  final List<T> options;
  final T selected;
  final String Function(T) label;
  final void Function(T) onTap;

  const _SegmentRow({
    required this.options,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isSelected = o == selected;
        return GestureDetector(
          onTap: () => onTap(o),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? t.selectedBackground
                  : const Color(0xFF13131F),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? t.selectedBorder
                    : t.cardBorder,
              ),
            ),
            child: Text(
              label(o),
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? t.textOnDark : t.textSecondary,
                fontWeight: isSelected
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-term toggle for summer
// ---------------------------------------------------------------------------
class _SubTermToggle extends StatelessWidget {
  final SubTerm subTerm;
  final bool selected;
  final VoidCallback onTap;

  const _SubTermToggle({
    required this.subTerm,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF378ADD).withOpacity(0.08)
              : const Color(0xFF13131F),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? const Color(0xFF378ADD).withOpacity(0.4)
                : t.cardBorder,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: selected
                    ? const Color(0xFF378ADD)
                    : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF378ADD)
                      : Colors.white38,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? Icon(Icons.check, size: 11, color: t.textPrimary)
                  : null,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                subTerm.label,
                style: TextStyle(
                  fontSize: 13,
                  color: selected ? t.textOnDark : t.textSecondary,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            Text(
              '${_fmt(subTerm.startDate)} – ${_fmt(subTerm.endDate)}',
              style: TextStyle(fontSize: 11, color: t.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime d) {
    const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${m[d.month]} ${d.day}';
  }
}

// ---------------------------------------------------------------------------
// Graduating toggle
// ---------------------------------------------------------------------------
class _GraduatingToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _GraduatingToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: value
              ? AppTheme.accentGold.withOpacity(0.08)
              : const Color(0xFF13131F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? AppTheme.accentGold.withOpacity(0.4)
                : t.cardBorder,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: value ? AppTheme.accentGold : Colors.transparent,
                border: Border.all(
                  color: value ? AppTheme.accentGold : Colors.white38,
                  width: 1.5,
                ),
              ),
              child: value
                  ? Icon(Icons.check, size: 12, color: Colors.black)
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yes, I am graduating this semester',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: t.textPrimary,
                    ),
                  ),
                  Text(
                    'Adds graduation checklist tasks to your semester',
                    style: TextStyle(fontSize: 11, color: t.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
