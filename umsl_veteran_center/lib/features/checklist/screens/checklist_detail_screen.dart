// lib/features/checklist/screens/checklist_detail_screen.dart
//
// The actual checklist for a semester — tasks grouped by category,
// with a progress bar, custom task support, and an edit button
// to return to setup (if not locked).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/semester.dart';
import '../models/semester_enrollment.dart';
import '../providers/checklist_provider.dart';
import '../models/benefit.dart';
import '../widgets/task_tile.dart';
import 'semester_setup_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vet_theme.dart';

class ChecklistDetailScreen extends ConsumerStatefulWidget {
  final Semester semester;

  const ChecklistDetailScreen({super.key, required this.semester});

  @override
  ConsumerState<ChecklistDetailScreen> createState() =>
      _ChecklistDetailScreenState();
}

class _ChecklistDetailScreenState
    extends ConsumerState<ChecklistDetailScreen> {
  // Custom task input controllers
  final _titleController = TextEditingController();
  final _noteController  = TextEditingController();
  bool _showAddTask = false;

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    final state      = ref.watch(checklistProvider);
    final enrollment = state.enrollmentFor(widget.semester.id);
    final isLocked   = widget.semester.isLocked;

    if (enrollment == null) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        appBar: _appBar(context, null, isLocked),
        body: Center(
          child: Text(
            'No enrollment found.',
            style: TextStyle(color: t.textTertiary),
          ),
        ),
      );
    }

    // Build full task list grouped by category
    final taskGroups =
        state.buildTaskList(enrollment, widget.semester);

    // Count total official tasks for progress
    final totalTasks = taskGroups.values.fold<int>(
        0, (sum, tasks) => sum + tasks.length);
    final completedTasks = taskGroups.values
        .expand((tasks) => tasks)
        .where((t) => enrollment.isTaskCompleted(t.taskId))
        .length;

    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: _appBar(context, enrollment, isLocked),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
        children: [
          // Progress card
          _ProgressCard(
            semester:      widget.semester,
            enrollment:    enrollment,
            benefits:      state.benefits,
            completed:     completedTasks,
            total:         totalTasks,
            progress:      progress,
            isLocked:      isLocked,
          ),
          const SizedBox(height: 12),

          // Task groups
          ...taskGroups.entries.map((entry) => _TaskGroup(
                category:  entry.key,
                tasks:     entry.value,
                enrollment: enrollment,
                semester:  widget.semester,
                benefits:  state.benefits,
                isLocked:  isLocked,
                onToggle:  (taskId, taskSource) {
                  ref.read(checklistProvider.notifier).toggleTask(
                    semesterId: widget.semester.id,
                    taskId:     taskId,
                    taskSource: taskSource,
                  );
                },
              )),

          // Custom tasks section
          if (enrollment.customTasks.isNotEmpty || !isLocked) ...[
            const SizedBox(height: 4),
            _CustomTasksSection(
              enrollment: enrollment,
              semesterId: widget.semester.id,
              isLocked:   isLocked,
              showAdd:    _showAddTask,
              titleController: _titleController,
              noteController:  _noteController,
              onShowAdd:  () => setState(() {
                _showAddTask = !_showAddTask;
                if (!_showAddTask) {
                  _titleController.clear();
                  _noteController.clear();
                }
              }),
              onAdd: () async {
                if (_titleController.text.trim().isEmpty) return;
                await ref.read(checklistProvider.notifier).addCustomTask(
                  semesterId: widget.semester.id,
                  title:      _titleController.text.trim(),
                  note:       _noteController.text.trim(),
                );
                _titleController.clear();
                _noteController.clear();
                setState(() => _showAddTask = false);
              },
              onToggle: (taskId) {
                ref.read(checklistProvider.notifier).toggleCustomTask(
                  semesterId: widget.semester.id,
                  taskId:     taskId,
                );
              },
              onDelete: (taskId) {
                ref.read(checklistProvider.notifier).deleteCustomTask(
                  semesterId: widget.semester.id,
                  taskId:     taskId,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  AppBar _appBar(BuildContext context, SemesterEnrollment? enrollment, bool isLocked) {
    final t = context.vetTheme;
    return AppBar(
      backgroundColor: AppTheme.darkBackground,
      foregroundColor: t.textOnDark,
      elevation: 0,
      title: Text(
        widget.semester.label,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      centerTitle: false,
      actions: [
        // Edit enrollment settings — only if not locked
        if (enrollment != null && !isLocked)
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 20),
            color: t.textSecondary,
            tooltip: 'Edit enrollment settings',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SemesterSetupScreen(semester: widget.semester),
              ));
            },
          ),
        if (isLocked)
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 14, color: t.textTertiary),
                SizedBox(width: 4),
                Text(
                  'Locked',
                  style: TextStyle(fontSize: 12, color: t.textTertiary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Progress card at top of detail screen
// ---------------------------------------------------------------------------
class _ProgressCard extends StatelessWidget {
  final Semester semester;
  final SemesterEnrollment enrollment;
  final List benefits;
  final int completed;
  final int total;
  final double progress;
  final bool isLocked;

  const _ProgressCard({
    required this.semester,
    required this.enrollment,
    required this.benefits,
    required this.completed,
    required this.total,
    required this.progress,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    final benefitNames = enrollment.benefitIds.map((id) {
      final b = benefits.where((b) => b.id == id).toList();
      return b.isNotEmpty ? b.first.shortName as String : id;
    }).join('  +  ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      benefitNames,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.accentGold,
                      ),
                    ),
                    Text(
                      '${enrollment.degreeLevel.label}  •  '
                      '${enrollment.enrollmentType.label}'
                      '${enrollment.isGraduating ? '  •  Graduating' : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color: t.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$completed / $total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: t.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: t.cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0
                    ? const Color(0xFF4CAF50)
                    : AppTheme.accentGold,
              ),
              minHeight: 4,
            ),
          ),
          if (progress >= 1.0)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 12, color: Color(0xFF4CAF50)),
                  SizedBox(width: 4),
                  Text(
                    'All official tasks complete',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Task group — one category header + its tasks
// ---------------------------------------------------------------------------
class _TaskGroup extends StatelessWidget {
  final String category;
  final List tasks;
  final SemesterEnrollment enrollment;
  final Semester semester;
  final List benefits;
  final bool isLocked;
  final Function(String taskId, String taskSource) onToggle;

  const _TaskGroup({
    required this.category,
    required this.tasks,
    required this.enrollment,
    required this.semester,
    required this.benefits,
    required this.isLocked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
          child: Text(
            category.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
              color: t.textTertiary,
            ),
          ),
        ),
        ...tasks.map((task) {
          // Resolve benefit short name for the badge
          String? benefitShortName;
          if (task.benefitId != null && enrollment.benefitIds.length > 1) {
            final b = benefits.where((b) => b.id == task.benefitId).toList();
            if (b.isNotEmpty) benefitShortName = b.first.shortName as String;
          }

          // Look up full benefit name for report emails
          String benefitName = '';
          if (task.benefitId != null) {
            final b = benefits.where((b) => b.id == task.benefitId).toList();
            if (b.isNotEmpty) benefitName = b.first.name as String;
          }

          return TaskTile(
            taskId:           task.taskId,
            title:            task.title,
            description:      task.description,
            isCompleted:      enrollment.isTaskCompleted(task.taskId),
            isRequired:       task.required as bool,
            isUserCreated:    false,
            isLocked:         isLocked,
            deadline:         task.deadline as DateTime?,
            dueLabel:         task.dueLabel as String?,
            links:            task.links as List<TaskLink>,
            benefitShortName: benefitShortName,
            semesterLabel:    semester.label,
            benefitName:      benefitName,
            onToggle: () => onToggle(task.taskId as String, task.source as String),
          );
        }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Custom tasks section
// ---------------------------------------------------------------------------
class _CustomTasksSection extends StatelessWidget {
  final SemesterEnrollment enrollment;
  final String semesterId;
  final bool isLocked;
  final bool showAdd;
  final TextEditingController titleController;
  final TextEditingController noteController;
  final VoidCallback onShowAdd;
  final VoidCallback onAdd;
  final Function(String) onToggle;
  final Function(String) onDelete;

  const _CustomTasksSection({
    required this.enrollment,
    required this.semesterId,
    required this.isLocked,
    required this.showAdd,
    required this.titleController,
    required this.noteController,
    required this.onShowAdd,
    required this.onAdd,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 4, 2, 8),
          child: Row(
            children: [
              Text(
                'PERSONAL TASKS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                  color: t.textTertiary,
                ),
              ),
              const Spacer(),
              if (!isLocked)
                GestureDetector(
                  onTap: onShowAdd,
                  child: Row(
                    children: [
                      Icon(
                        showAdd ? Icons.close : Icons.add,
                        size: 14,
                        color: AppTheme.accentGold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        showAdd ? 'Cancel' : 'Add task',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.accentGold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Add task input
        if (showAdd && !isLocked)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.accentGold.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  style: TextStyle(color: t.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Task title',
                    hintStyle: TextStyle(color: t.textTertiary, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Divider(color: t.divider, height: 16),
                TextField(
                  controller: noteController,
                  style: TextStyle(color: t.textSecondary, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Note (optional)',
                    hintStyle: TextStyle(color: t.textTertiary, fontSize: 12),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: onAdd,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.accentGold.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'Add',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.accentGold,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Custom task tiles
        ...enrollment.customTasks.map(
          (task) => TaskTile(
            taskId:        task.id,
            title:         task.title,
            description:   task.note,
            isCompleted:   task.completed,
            isRequired:    false,
            isUserCreated: true,
            isLocked:      isLocked,
            semesterLabel: '',
            benefitName:   '',
            onToggle: () => onToggle(task.id),
            onDelete: () => onDelete(task.id),
          ),
        ),

        if (enrollment.customTasks.isEmpty && !showAdd)
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'No personal tasks. Tap "Add task" to create one.',
              style: TextStyle(fontSize: 12, color: t.textTertiary),
            ),
          ),
      ],
    );
  }
}
