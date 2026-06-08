// lib/features/checklist/screens/checklist_screen.dart
//
// Checklist tab — shows list of all semesters.
// Each semester card shows its state (upcoming, active, locked etc.),
// which benefits are set up, and progress if enrollment exists.
// Tapping an open semester goes to checklist_detail_screen.
// Tapping an upcoming semester shows a "not yet open" message.
// Disclaimer sheet is shown once before the list is accessible.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/checklist_provider.dart';
import '../models/semester.dart';
import '../widgets/disclaimer_sheet.dart';
import 'semester_setup_screen.dart';
import 'checklist_detail_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../core/theme/vet_theme.dart';

class ChecklistScreen extends ConsumerWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.vetTheme;
    final state = ref.watch(checklistProvider);

    if (state.loading) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (state.error != null) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Center(
          child: Text(state.error!, style: TextStyle(color: t.textSecondary)),
        ),
      );
    }

    // Show disclaimer bottom sheet once — blocks access until accepted
    if (!state.disclaimerAccepted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          isDismissible: false,
          enableDrag: false,
          backgroundColor: Colors.transparent,
          builder: (_) => const DisclaimerSheet(),
        );
      });
    }

    return Scaffold(
      backgroundColor: t.pageBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Checklist',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: t.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Select a semester to view or set up your checklist',
                            style: TextStyle(fontSize: 12, color: t.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    // Report general issue
                    IconButton(
                      icon: Icon(Icons.flag_outlined, size: 20),
                      color: t.textTertiary,
                      onPressed: () {
                        // Import and call ReportService.reportGeneral()
                        // Done in the widget to avoid provider complexity
                      },
                      tooltip: 'Report an issue',
                    ),
                  ],
                ),
              ),
            ),

            // Semester cards
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final semester = state.semesters[i];
                  final enrollment = state.enrollmentFor(semester.id);
                  final semState = semester.stateOn(DateTime.now());

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      12, 0, 12,
                      i == state.semesters.length - 1 ? 0 : 8,
                    ),
                    child: _SemesterCard(
                      semester:   semester,
                      semState:   semState,
                      enrollment: enrollment,
                      benefits:   state.benefits,
                      onTap: () => _handleTap(context, semester, semState, enrollment, ref),
                    ),
                  );
                },
                childCount: state.semesters.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }

  void _handleTap(
    BuildContext context,
    Semester semester,
    SemesterState semState,
    enrollment,
    WidgetRef ref,
  ) {
    if (!ref.read(checklistProvider).disclaimerAccepted) return;

    if (semState == SemesterState.upcoming) {
      // Show when it opens
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${semester.label} opens for setup on '
            '${_fmtDate(semester.opensDate)}',
          ),
          backgroundColor: const Color(0xFF1E1E2E),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (enrollment == null) {
      // First time — go to setup
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SemesterSetupScreen(semester: semester),
      ));
    } else {
      // Already set up — go to checklist detail
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChecklistDetailScreen(semester: semester),
      ));
    }
  }

  static String _fmtDate(DateTime d) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }
}

// ---------------------------------------------------------------------------
// Semester card
// ---------------------------------------------------------------------------
class _SemesterCard extends StatelessWidget {
  final Semester semester;
  final SemesterState semState;
  final enrollment;
  final List benefits;
  final VoidCallback onTap;

  const _SemesterCard({
    required this.semester,
    required this.semState,
    required this.enrollment,
    required this.benefits,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    final isUpcoming = semState == SemesterState.upcoming;
    final isLocked   = semState == SemesterState.locked;
    final isActive   = semState == SemesterState.active;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isUpcoming ? 0.45 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? AppTheme.primaryRed.withOpacity(0.4)
                  : t.cardBorder,
              width: isActive ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Term icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _termColor(semester.term).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _termIcon(semester.term),
                      size: 18,
                      color: _termColor(semester.term),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          semester.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: t.textPrimary,
                          ),
                        ),
                        Text(
                          semester.dateRange,
                          style: TextStyle(
                            fontSize: 11,
                            color: t.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // State badge
                  _StateBadge(semState: semState),
                ],
              ),

              // Enrollment summary if set up
              if (enrollment != null) ...[
                SizedBox(height: 10),
                Divider(color: t.divider, height: 1),
                SizedBox(height: 10),
                _EnrollmentSummary(
                  enrollment: enrollment,
                  benefits:   benefits,
                ),
              ] else if (!isUpcoming) ...[
                SizedBox(height: 8),
                Text(
                  'Tap to set up your checklist for this semester',
                  style: TextStyle(fontSize: 11, color: t.textTertiary),
                ),
              ],

              // Lock notice
              if (isLocked)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline, size: 12, color: t.textTertiary),
                      SizedBox(width: 4),
                      Text(
                        'Read-only — semester record locked',
                        style: TextStyle(fontSize: 11, color: t.textTertiary),
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

  Color _termColor(String term) {
    switch (term) {
      case 'fall':   return const Color(0xFFEF9F27); // amber
      case 'spring': return const Color(0xFF4CAF50); // green
      case 'summer': return const Color(0xFF378ADD); // blue
      default:       return Colors.white38;
    }
  }

  IconData _termIcon(String term) {
    switch (term) {
      case 'fall':   return Icons.forest_rounded;
      case 'spring': return Icons.local_florist_rounded;
      case 'summer': return Icons.wb_sunny_rounded;
      default:       return Icons.school_rounded;
    }
  }
}

// ---------------------------------------------------------------------------
// State badge pill
// ---------------------------------------------------------------------------
class _StateBadge extends StatelessWidget {
  final SemesterState semState;
  const _StateBadge({required this.semState});

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    Color bg;
    Color fg;
    switch (semState) {
      case SemesterState.active:
        bg = t.selectedBackground;
        fg = const Color(0xFFFF6B6B);
      case SemesterState.enrolling:
        bg = AppTheme.accentGold.withOpacity(0.15);
        fg = AppTheme.accentGold;
      case SemesterState.ended:
        bg = t.cardBorder;
        fg = Colors.white38;
      case SemesterState.locked:
        bg = t.cardBackground.withOpacity(0.5);
        fg = Colors.white24;
      case SemesterState.upcoming:
        bg = t.cardBackground.withOpacity(0.5);
        fg = Colors.white24;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        semState.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Enrollment summary shown on the semester card
// ---------------------------------------------------------------------------
class _EnrollmentSummary extends StatelessWidget {
  final enrollment;
  final List benefits;
  const _EnrollmentSummary({required this.enrollment, required this.benefits});

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    final benefitNames = (enrollment.benefitIds as List<String>)
        .map((id) {
          final b = benefits.where((b) => b.id == id).toList();
          return b.isNotEmpty ? b.first.shortName as String : id;
        })
        .join(', ');

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                benefitNames,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.accentGold,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${enrollment.degreeLevel.label}  •  '
                '${enrollment.enrollmentType.label}'
                '${enrollment.isGraduating ? '  •  Graduating' : ''}',
                style: TextStyle(fontSize: 11, color: t.textTertiary),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right,
          color: t.textTertiary,
          size: 18,
        ),
      ],
    );
  }
}
