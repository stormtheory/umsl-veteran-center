// lib/features/home/widgets/home_calendar.dart
//
// Interactive calendar widget used on the home screen.
// Renders a month grid with color-coded dots on event days.
// Tapping a day opens an event detail panel below the grid.
//
// Color coding (matches calendar.json "type" field):
//   purple     = Semester start and end dates
//   light_blue = Holidays and campus closures
//   red        = Deadlines
//   gold       = Campus events
//   green      = Veteran / Vet Center events

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/calendar_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vet_theme.dart';

// Brand colors for event types
const _kPurple    = Color(0xFF7B1FA2); // Semester start/end
const _kLightBlue = Color(0xFF29B6F6); // Holidays and closures
const _kRed       = Color(0xFFE53935); // Deadlines
const _kGold      = Color(0xFFC0A060); // Campus events — UMSL gold
const _kGreen     = Color(0xFF4CAF50); // Veteran / Vet Center events

Color _typeColor(String type) {
  switch (type) {
    case 'purple':     return _kPurple;
    case 'light_blue': return _kLightBlue;
    case 'red':        return _kRed;
    case 'gold':       return _kGold;
    case 'green':      return _kGreen;
    // Legacy type names — keep backward compatible with old calendar.json entries
    case 'blue':       return _kLightBlue;
    default:           return Colors.grey;
  }
}

class HomeCalendar extends ConsumerStatefulWidget {
  // ScrollController from the parent ListView — used to scroll the
  // event panel into view when a date is tapped
  final ScrollController scrollController;

  const HomeCalendar({super.key, required this.scrollController});

  @override
  ConsumerState<HomeCalendar> createState() => _HomeCalendarState();
}

class _HomeCalendarState extends ConsumerState<HomeCalendar> {
  late int _viewYear;
  late int _viewMonth;
  DateTime? _selectedDay;

  // Key on the event panel so we can scroll it into view after setState
  final _eventPanelKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewYear  = now.year;
    _viewMonth = now.month;
    // Auto-select today so the panel is not empty on first load
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  void _prevMonth() {
    setState(() {
      _viewMonth--;
      if (_viewMonth < 1) { _viewMonth = 12; _viewYear--; }
    });
  }

  void _nextMonth() {
    setState(() {
      _viewMonth++;
      if (_viewMonth > 12) { _viewMonth = 1; _viewYear++; }
    });
  }

  // Select a day and scroll so the event panel is visible
  void _selectDay(DateTime day) {
    setState(() => _selectedDay = day);
    // One frame delay — let the panel render first so its RenderBox exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _eventPanelKey.currentContext;
      if (ctx == null) return;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) return;
      // Convert the panel's top-left to the scroll view's coordinate space
      final offset = box.localToGlobal(
        Offset.zero,
        ancestor: ctx.findAncestorRenderObjectOfType<RenderBox>(),
      );
      final sc = widget.scrollController;
      // Target scroll position: current position + panel's y offset, minus
      // a small margin so a sliver of the calendar stays visible above
      final target = (sc.offset + offset.dy - 80).clamp(
        sc.position.minScrollExtent,
        sc.position.maxScrollExtent,
      );
      sc.animateTo(
        target,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    final calState = ref.watch(calendarProvider);
    final notifier  = ref.read(calendarProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: t.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(
        children: [
          // Month navigation header
          _CalHeader(
            year: _viewYear,
            month: _viewMonth,
            onPrev: _prevMonth,
            onNext: _nextMonth,
          ),
          // Day-of-week labels
          const _DowRow(),
          // Day grid
          calState.when(
            loading: () => Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Could not load calendar.',
                style: TextStyle(color: t.textTertiary, fontSize: 12),
              ),
            ),
            data: (_) => _DayGrid(
              year: _viewYear,
              month: _viewMonth,
              selectedDay: _selectedDay,
              getTypes: notifier.typesForDay,
              onTap: _selectDay,
            ),
          ),
          // Color legend
          const _Legend(),
          // Event detail panel for selected day
          if (_selectedDay != null)
            _EventPanel(
              key: _eventPanelKey,
              day: _selectedDay!,
              events: notifier.eventsForDay(_selectedDay!),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Month header with prev/next arrows
// ---------------------------------------------------------------------------
class _CalHeader extends StatelessWidget {
  final int year;
  final int month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _CalHeader({
    required this.year,
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    final label = _monthName(month);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            icon: Icon(Icons.chevron_left),
            iconSize: 20,
            color: t.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Expanded(
            child: Text(
              '$label $year',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: t.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: Icon(Icons.chevron_right),
            iconSize: 20,
            color: t.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  static String _monthName(int m) => const [
        '', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ][m];
}

// ---------------------------------------------------------------------------
// Day-of-week header row (Sun Mon Tue ...)
// ---------------------------------------------------------------------------
class _DowRow extends StatelessWidget {
  const _DowRow();

  static const _days = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: _days
            .map((d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: 10,
                        color: t.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 7-column day grid with event dots
// ---------------------------------------------------------------------------
class _DayGrid extends StatelessWidget {
  final int year;
  final int month;
  final DateTime? selectedDay;
  final Set<String> Function(DateTime) getTypes;
  final ValueChanged<DateTime> onTap;

  const _DayGrid({
    required this.year,
    required this.month,
    required this.selectedDay,
    required this.getTypes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    // First weekday of the month (Sunday=0)
    final firstWeekday = DateTime(year, month, 1).weekday % 7;
    final daysInMonth  = DateTime(year, month + 1, 0).day;
    final daysInPrev   = DateTime(year, month, 0).day;
    final today        = DateTime.now();

    // Build flat list of day cells
    final cells = <Widget>[];

    // Trailing days from previous month (greyed out)
    for (int i = 0; i < firstWeekday; i++) {
      final d = daysInPrev - firstWeekday + i + 1;
      cells.add(_DayCell(
        dayNum: d,
        isCurrentMonth: false,
        isToday: false,
        isSelected: false,
        dotColors: const [],
        onTap: () {},
      ));
    }

    // Current month days
    for (int d = 1; d <= daysInMonth; d++) {
      final date   = DateTime(year, month, d);
      final types  = getTypes(date);
      final isToday = today.year == year && today.month == month && today.day == d;
      final isSel  = selectedDay?.year == year &&
                     selectedDay?.month == month &&
                     selectedDay?.day == d;
      cells.add(_DayCell(
        dayNum: d,
        isCurrentMonth: true,
        isToday: isToday,
        isSelected: isSel,
        dotColors: types.map(_typeColor).toList(),
        onTap: () => onTap(date),
      ));
    }

    // Leading days of next month (greyed out)
    final total    = firstWeekday + daysInMonth;
    final trailing = total % 7 == 0 ? 0 : 7 - (total % 7);
    for (int i = 1; i <= trailing; i++) {
      cells.add(_DayCell(
        dayNum: i,
        isCurrentMonth: false,
        isToday: false,
        isSelected: false,
        dotColors: const [],
        onTap: () {},
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.0,
        children: cells,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single day cell
// ---------------------------------------------------------------------------
class _DayCell extends StatelessWidget {
  final int dayNum;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final List<Color> dotColors;
  final VoidCallback onTap;

  const _DayCell({
    required this.dayNum,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.dotColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? AppTheme.accentGold.withOpacity(0.15)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Day number — circle for today
            isToday
                ? Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryRed,
                    ),
                    child: Center(
                      child: Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : Text(
                    '$dayNum',
                    style: TextStyle(
                      fontSize: 12,
                      color: isCurrentMonth
                          ? (isSelected ? t.accentGold : t.textPrimary)
                          : t.textTertiary,
                    ),
                  ),
            const SizedBox(height: 2),
            // Event dots — up to 3, one per unique type
            if (dotColors.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: dotColors
                    .take(3)
                    .map((c) => Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c,
                          ),
                        ))
                    .toList(),
              )
            else
              // Empty spacer so all cells have consistent height
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Color legend — two rows to fit all 5 types comfortably
// ---------------------------------------------------------------------------
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1
          Row(
            children: [
              _LegendItem(color: _kGreen,     label: 'Veteran Events'),
              const SizedBox(width: 12),
              _LegendItem(color: _kGold,      label: 'Campus Events'),
              const SizedBox(width: 12),
              _LegendItem(color: _kRed,       label: 'Deadlines'),
            ],
          ),
          const SizedBox(height: 5),
          // Row 2
          Row(
            children: [
              _LegendItem(color: _kPurple,    label: 'Start / End'),
              const SizedBox(width: 12),
              _LegendItem(color: _kLightBlue, label: 'Holiday / Closed'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: t.textTertiary),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Event detail panel — shown below grid when a day is selected
// ---------------------------------------------------------------------------
class _EventPanel extends StatelessWidget {
  final DateTime day;
  final List<CalendarEvent> events;

  const _EventPanel({super.key, required this.day, required this.events});

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    final formatted = _formatDay(day);
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel header showing the selected date
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Text(
              formatted,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: t.textSecondary,
              ),
            ),
          ),
          // Events or empty state
          if (events.isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(
                'No events on this day.',
                style: TextStyle(fontSize: 12, color: t.textTertiary),
              ),
            )
          else
            ...events.map((e) => _EventRow(event: e)),
        ],
      ),
    );
  }

  static String _formatDay(DateTime d) {
    const weekdays = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months   = ['', 'January', 'February', 'March', 'April', 'May', 'June',
                      'July', 'August', 'September', 'October', 'November', 'December'];
    return '${weekdays[d.weekday]}, ${months[d.month]} ${d.day}';
  }
}

// ---------------------------------------------------------------------------
// Single event row inside the event panel
// ---------------------------------------------------------------------------
class _EventRow extends StatelessWidget {
  final CalendarEvent event;
  const _EventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    final color = _typeColor(event.type);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color bar on the left
          Container(
            width: 3,
            height: 48,
            margin: const EdgeInsets.only(top: 2, right: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event name
                Text(
                  event.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                // Time + location row
                if (event.time.isNotEmpty || event.location.isNotEmpty)
                  Wrap(
                    spacing: 10,
                    children: [
                      if (event.time.isNotEmpty)
                        _MetaChip(
                          icon: Icons.access_time,
                          label: event.time,
                        ),
                      if (event.location.isNotEmpty)
                        _MetaChip(
                          icon: Icons.location_on_outlined,
                          label: event.location,
                        ),
                    ],
                  ),
                SizedBox(height: 3),
                // Description
                if (event.desc.isNotEmpty)
                  Text(
                    event.desc,
                    style: TextStyle(
                      fontSize: 11,
                      color: t.textSecondary.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                // External links
                if (event.links.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 10,
                    children: event.links
                        .map((l) => _LinkChip(link: l))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: t.textTertiary),
        SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: t.textTertiary)),
      ],
    );
  }
}

class _LinkChip extends StatelessWidget {
  final EventLink link;
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
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.accentGold,
            ),
          ),
        ],
      ),
    );
  }
}
