// lib/features/bah/screens/bah_screen.dart
//
// BAH / MHA Calculator screen.
// Estimates monthly housing allowance for Ch. 33, Ch. 30, Ch. 35,
// Ch. 1606, Ch. 31, and Missouri Returning Heroes.
//
// All rates come from assets/data/bah_rates.json — update that file
// each academic year, no Dart changes needed.
//
// IMPORTANT: This screen shows ESTIMATES ONLY.
// Students must call the VA Education line (1-888-442-4551) for exact amounts.
// The Vet Center does not determine individual MHA rates.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/bah_provider.dart';
import '../models/bah_rate.dart';
import '../../../core/theme/app_theme.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../core/theme/vet_theme.dart';

class BahScreen extends ConsumerWidget {
  const BahScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.vetTheme;
    final state = ref.watch(bahProvider);

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
          child: Text(
            'Could not load rates.',
            style: TextStyle(color: t.textTertiary),
          ),
        ),
      );
    }

    final result = state.result;

    return Scaffold(
      backgroundColor: t.pageBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BAH / MHA Calculator',
                            style: TextStyle(fontSize: 20,
                                fontWeight: FontWeight.w500, color: t.textPrimary)),
                        const SizedBox(height: 2),
                        Text('Monthly housing allowance estimate',
                            style: TextStyle(fontSize: 12, color: t.textTertiary)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    child: Icon(Icons.settings_outlined, size: 22, color: t.textTertiary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Benefit selector
            _Section(
              label: 'Benefit',
              child: _BenefitSelector(
                benefits:   state.benefits,
                selectedId: state.selectedBenefitId,
                onSelect:   (id) => ref.read(bahProvider.notifier).selectBenefit(id),
              ),
            ),

            // Semester selector
            _Section(
              label: 'Semester',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SegmentRow(
                    options: const ['Fall / Spring', 'Summer'],
                    selected: state.semesterType == SemesterType.regular ? 0 : 1,
                    onSelect: (i) => ref.read(bahProvider.notifier)
                        .selectSemesterType(i == 0 ? SemesterType.regular : SemesterType.summer),
                  ),
                  // Summer session picker
                  if (state.semesterType == SemesterType.summer) ...[
                    const SizedBox(height: 12),
                    _SummerSessionPicker(
                      sessions:   state.summerSessions,
                      selectedId: state.selectedSummerSessionId,
                      isGraduate: state.isGraduate,
                      onSelect:   (id) => ref.read(bahProvider.notifier).selectSummerSession(id),
                    ),
                    const SizedBox(height: 10),
                    // Graduate toggle for summer (different FT thresholds)
                    _InlineToggle(
                      label: 'Graduate student',
                      sublabel: 'Changes full-time credit hour threshold',
                      value: state.isGraduate,
                      onChanged: (v) => ref.read(bahProvider.notifier).setIsGraduate(v),
                    ),
                  ],
                ],
              ),
            ),

            // Credit hour slider — hidden for Ch. 31 and MO Heroes
            if (state.selectedBenefit?.counselorDriven != true &&
                state.selectedBenefit?.tuitionOnly != true)
              _Section(
                label: 'Credit hours enrolled',
                child: _CreditHourSlider(
                  creditHours: state.creditHours,
                  maxHours:    state.maxCreditHours,
                  ftHours:     state.ftHours,
                  trainingTime: result?.trainingTime ?? TrainingTime.full,
                  onChanged:   (v) => ref.read(bahProvider.notifier).setCreditHours(v),
                ),
              ),

            // Online-only toggle — Ch. 33 only
            if (state.selectedBenefitId == 'ch33')
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: _InlineToggle(
                  label: 'All classes online only',
                  sublabel: 'Reduces MHA to 50% regardless of credit hours',
                  value: state.onlineOnly,
                  onChanged: (v) => ref.read(bahProvider.notifier).setOnlineOnly(v),
                ),
              ),

            // Zero MHA warning
            if (result?.isZeroMha == true)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFE53935).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Color(0xFFE53935),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Less than half-time enrollment. MHA is \$0 — '
                        'the VA pays tuition and fees only, not a housing allowance.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFE53935),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Result card
            if (result != null)
              _ResultCard(result: result, benefit: state.selectedBenefit!),

            // Disclaimer — VA hotline only, never the Vet Center
            _Disclaimer(),

          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section wrapper — label + card
// ---------------------------------------------------------------------------
class _Section extends StatelessWidget {
  final String label;
  final Widget child;
  const _Section({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
              color: t.textTertiary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Benefit selector pills
// ---------------------------------------------------------------------------
class _BenefitSelector extends StatelessWidget {
  final List<BahBenefit> benefits;
  final String selectedId;
  final ValueChanged<String> onSelect;

  const _BenefitSelector({
    required this.benefits,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: benefits.map((b) {
        final isSelected = b.id == selectedId;
        return GestureDetector(
          onTap: () => onSelect(b.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? t.selectedBackground
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? t.selectedBorder
                    : t.cardBorder,
              ),
            ),
            child: Text(
              b.shortName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                color: isSelected ? t.textOnDark : t.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Generic segment row
// ---------------------------------------------------------------------------
class _SegmentRow extends StatelessWidget {
  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelect;

  const _SegmentRow({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return Row(
      children: options.asMap().entries.map((e) {
        final isSelected = e.key == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 8),
              margin: EdgeInsets.only(right: e.key < options.length - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: isSelected
                    ? t.selectedBackground
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? t.selectedBorder
                      : t.cardBorder,
                ),
              ),
              child: Text(
                e.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  color: isSelected ? t.textOnDark : t.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Summer session picker
// ---------------------------------------------------------------------------
class _SummerSessionPicker extends StatelessWidget {
  final List<SummerSession> sessions;
  final String selectedId;
  final bool isGraduate;
  final ValueChanged<String> onSelect;

  const _SummerSessionPicker({
    required this.sessions,
    required this.selectedId,
    required this.isGraduate,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return Column(
      children: sessions.map((s) {
        final isSelected = s.id == selectedId;
        final ftHrs = s.ftHours(isGraduate);
        return GestureDetector(
          onTap: () => onSelect(s.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF378ADD).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF378ADD).withOpacity(0.4)
                    : t.cardBorder,
              ),
            ),
            child: Row(
              children: [
                // Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isSelected
                        ? const Color(0xFF378ADD)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF378ADD)
                          : Colors.white38,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? Icon(Icons.check, size: 11, color: t.textPrimary)
                      : null,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${s.label}  ·  ${s.sessions}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.normal,
                          color: isSelected ? t.textOnDark : t.textSecondary,
                        ),
                      ),
                      Text(
                        'Full-time = $ftHrs hrs  ·  ${s.weeks} weeks',
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
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Credit hour slider with training time label
// ---------------------------------------------------------------------------
class _CreditHourSlider extends StatelessWidget {
  final int creditHours;
  final int maxHours;
  final int ftHours;
  final TrainingTime trainingTime;
  final ValueChanged<int> onChanged;

  const _CreditHourSlider({
    required this.creditHours,
    required this.maxHours,
    required this.ftHours,
    required this.trainingTime,
    required this.onChanged,
  });

  Color get _ttColor {
    switch (trainingTime) {
      case TrainingTime.full:         return AppTheme.accentGold;
      case TrainingTime.threeQuarter: return AppTheme.accentGold;
      case TrainingTime.half:         return const Color(0xFFEF9F27);
      case TrainingTime.less:         return const Color(0xFFE53935);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$creditHours credit hour${creditHours != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: _ttColor,
                  ),
                ),
                Text(
                  'Full-time = $ftHours hrs',
                  style: TextStyle(fontSize: 11, color: t.textTertiary),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _ttColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                trainingTime.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _ttColor,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor:   AppTheme.accentGold,
            inactiveTrackColor: t.cardBorder,
            thumbColor:         AppTheme.accentGold,
            overlayColor:       AppTheme.accentGold.withOpacity(0.15),
            trackHeight:        3,
          ),
          child: Slider(
            value: creditHours.toDouble(),
            min:   1,
            max:   maxHours.toDouble(),
            divisions: maxHours - 1,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('1 hr', style: TextStyle(fontSize: 10, color: t.textTertiary)),
            Text('$maxHours hrs', style: TextStyle(fontSize: 10, color: t.textTertiary)),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Inline toggle row
// ---------------------------------------------------------------------------
class _InlineToggle extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _InlineToggle({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: t.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(fontSize: 11, color: t.textTertiary),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.accentGold,
              activeTrackColor: AppTheme.accentGold.withOpacity(0.3),
              inactiveThumbColor: Colors.white38,
              inactiveTrackColor: t.cardBorder,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Result card — big number + tier breakdown
// ---------------------------------------------------------------------------
class _ResultCard extends StatelessWidget {
  final BahResult result;
  final BahBenefit benefit;

  const _ResultCard({required this.result, required this.benefit});

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(
        children: [
          // Big monthly amount
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Text(
                  result.isCounselorDriven || result.isTuitionOnly
                      ? 'N/A'
                      : '\$${result.monthlyAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w500,
                    color: result.isZeroMha
                        ? const Color(0xFFE53935)
                        : AppTheme.accentGold,
                  ),
                ),
                Text(
                  result.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: t.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (result.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      result.note,
                      style: TextStyle(
                        fontSize: 11,
                        color: t.textTertiary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),

          // Tier breakdown table
          if (result.tiers.isNotEmpty) ...[
            Divider(color: t.divider, height: 16),
            ...result.tiers.map((tier) => Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: tier.isActive
                        ? AppTheme.accentGold.withOpacity(0.1)
                        : t.cardBackground.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: tier.isActive
                          ? AppTheme.accentGold.withOpacity(0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tier.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: tier.isActive
                              ? AppTheme.accentGold
                              : Colors.white38,
                        ),
                      ),
                      Text(
                        tier.isZero
                            ? '\$0 MHA'
                            : '\$${tier.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: tier.isActive
                              ? AppTheme.accentGold
                              : Colors.white38,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Disclaimer — VA hotline only. The Vet Center does NOT set individual rates.
// ---------------------------------------------------------------------------
class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.cardBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 13, color: t.textTertiary),
              SizedBox(width: 6),
              Text(
                'Estimates only',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: t.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'Your actual monthly amount depends on your individual benefit level, '
            'dependent status, and enrollment details. Rates change annually. '
            'This calculator is a planning tool only.',
            style: TextStyle(
              fontSize: 11,
              color: t.textTertiary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          // VA Education hotline — the correct contact for exact amounts
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse('tel:+18884424551');
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.accentGold.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 14,
                    color: AppTheme.accentGold,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Call VA Education — 1-888-442-4551',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.accentGold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Mon – Fri  8:00 AM – 7:00 PM ET',
            style: TextStyle(fontSize: 10, color: t.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
