// lib/features/checklist/widgets/task_tile.dart
//
// Single task row used in the checklist detail screen.
// Handles:
//   - Official tasks (required + optional)
//   - Custom (user-created) tasks — shown with a "Personal" badge
//   - Deadline badges: upcoming (gold), due today (gold), overdue (red)
//   - Up to 2 external links
//   - Report button (flag icon) for reporting incorrect info
//   - Read-only mode when semester is locked

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/benefit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vet_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class TaskTile extends StatelessWidget {
  final String taskId;
  final String title;
  final String description;
  final bool isCompleted;
  final bool isRequired;
  final bool isUserCreated;    // drives the "Personal" badge
  final bool isLocked;         // semester is past lock_date
  final DateTime? deadline;
  final String? dueLabel;
  final List<TaskLink> links;
  final String? benefitShortName; // shown as a small pill on the tile
  final String semesterLabel;
  final String benefitName;
  final VoidCallback onToggle;
  final VoidCallback? onDelete; // only for custom tasks

  const TaskTile({
    super.key,
    required this.taskId,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.isRequired,
    required this.isUserCreated,
    required this.isLocked,
    required this.onToggle,
    required this.semesterLabel,
    required this.benefitName,
    this.deadline,
    this.dueLabel,
    this.links = const [],
    this.benefitShortName,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    final deadlineStatus = _deadlineStatus();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: t.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? t.cardBackground.withOpacity(0.5)
              : t.cardBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            GestureDetector(
              onTap: isLocked ? null : onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: isCompleted
                      ? AppTheme.accentGold
                      : Colors.transparent,
                  border: Border.all(
                    color: isCompleted
                        ? AppTheme.accentGold
                        : isLocked
                            ? Colors.white12
                            : Colors.white38,
                    width: 1.5,
                  ),
                ),
                child: isCompleted
                    ? Icon(Icons.check, size: 13, color: Colors.black)
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // Task body
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with badges
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isCompleted
                                ? Colors.white38
                                : isLocked
                                    ? Colors.white54
                                    : t.textPrimary,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: Colors.white38,
                          ),
                        ),
                      ),
                      // Report button — flag incorrect info
                      if (!isUserCreated)
                        GestureDetector(
                          onTap: () async {
                            // Pre-fill report email — contact info lives in contacts.json
                            final subject = Uri.encodeComponent(
                              'Task Information Report — UMSL Vet Center App',
                            );
                            final body = Uri.encodeComponent(
                              'Task: $title\nBenefit: $benefitName\nSemester: $semesterLabel\n\nPlease describe the issue:\n\n[Your message here]',
                            );
                            final uri = Uri.parse(
                              'mailto:VeteransOffice@umsl.edu?subject=$subject&body=$body',
                            );
                            if (await canLaunchUrl(uri)) await launchUrl(uri);
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.flag_outlined,
                              size: 14,
                              color: t.textTertiary,
                            ),
                          ),
                        ),
                      // Delete button for custom tasks
                      if (isUserCreated && !isLocked && onDelete != null)
                        GestureDetector(
                          onTap: onDelete,
                          child: Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: t.textTertiary,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Pill badges row
                  if (isUserCreated || benefitShortName != null || !isRequired)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 6,
                        children: [
                          if (isUserCreated)
                            _Badge(
                              label: 'Personal',
                              color: t.textTertiary,
                              textColor: Colors.white54,
                            ),
                          if (benefitShortName != null)
                            _Badge(
                              label: benefitShortName!,
                              color: AppTheme.accentGold.withOpacity(0.15),
                              textColor: AppTheme.accentGold,
                            ),
                          if (!isRequired && !isUserCreated)
                            _Badge(
                              label: 'Optional',
                              color: t.cardBorder,
                              textColor: Colors.white38,
                            ),
                        ],
                      ),
                    ),

                  // Description
                  if (description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        description,
                        style: TextStyle(
                          fontSize: 11,
                          color: t.textSecondary.withOpacity(0.7),
                          height: 1.5,
                        ),
                      ),
                    ),

                  // Deadline badge
                  if (deadlineStatus != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 11,
                            color: deadlineStatus.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            deadlineStatus.label,
                            style: TextStyle(
                              fontSize: 11,
                              color: deadlineStatus.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // External links — max 2
                  if (links.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 12,
                        children: links
                            .take(2)
                            .map((l) => _LinkChip(link: l))
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Compute deadline display status
  _DeadlineStatus? _deadlineStatus() {
    if (isCompleted) return null;
    if (deadline == null && dueLabel == null) return null;

    // If no computed deadline but has a label (e.g. "Monthly")
    if (deadline == null && dueLabel != null) {
      return _DeadlineStatus(
        label: dueLabel!,
        color: Colors.white38,
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due   = DateTime(deadline!.year, deadline!.month, deadline!.day);
    final diff  = due.difference(today).inDays;

    if (diff < 0) {
      return _DeadlineStatus(
        label: 'Overdue — ${dueLabel ?? _fmtDate(deadline!)}',
        color: const Color(0xFFE53935),
      );
    } else if (diff == 0) {
      return _DeadlineStatus(
        label: 'Due today',
        color: AppTheme.accentGold,
      );
    } else if (diff <= 7) {
      return _DeadlineStatus(
        label: 'Due in $diff day${diff == 1 ? '' : 's'}',
        color: AppTheme.accentGold,
      );
    } else {
      return _DeadlineStatus(
        label: dueLabel ?? 'Due ${_fmtDate(deadline!)}',
        color: Colors.white38,
      );
    }
  }

  static String _fmtDate(DateTime d) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month]} ${d.day}';
  }
}

class _DeadlineStatus {
  final String label;
  final Color color;
  const _DeadlineStatus({required this.label, required this.color});
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _Badge({required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  final TaskLink link;
  const _LinkChip({required this.link});

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(link.url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.open_in_new, size: 11, color: AppTheme.accentGold),
          const SizedBox(width: 3),
          Text(
            link.label,
            style: TextStyle(fontSize: 11, color: AppTheme.accentGold),
          ),
        ],
      ),
    );
  }
}
