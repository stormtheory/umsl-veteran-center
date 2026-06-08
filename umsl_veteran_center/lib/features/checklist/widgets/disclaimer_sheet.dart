// lib/features/checklist/widgets/disclaimer_sheet.dart
//
// One-time disclaimer shown before the student accesses the checklist.
// Saved to Keychain on acceptance — never shown again unless app is reset.
// Reflects that this is a helpful tool, not official guidance.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/checklist_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vet_theme.dart';

class DisclaimerSheet extends ConsumerStatefulWidget {
  const DisclaimerSheet({super.key});

  @override
  ConsumerState<DisclaimerSheet> createState() => _DisclaimerSheetState();
}

class _DisclaimerSheetState extends ConsumerState<DisclaimerSheet> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return Container(
      decoration: BoxDecoration(
        color: t.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 16, 24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: t.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Icon + title
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: AppTheme.accentGold,
                  size: 22,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'A note before you start',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: t.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Disclaimer text
          Text(
            'Dates and tasks in this app are provided as a helpful reference '
            'and may not reflect the most current VA or university requirements. '
            'Requirements can change, and individual circumstances vary.',
            style: TextStyle(
              fontSize: 14,
              color: t.textSecondary,
              height: 1.6,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'You are responsible for verifying all deadlines and requirements '
            'directly with the UMSL Veterans Center and the VA. '
            'This app is a tool — not a substitute for official guidance.',
            style: TextStyle(
              fontSize: 14,
              color: t.textSecondary,
              height: 1.6,
            ),
          ),
          SizedBox(height: 10),

          // Contact info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t.textOnDark.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: t.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UMSL Veterans Center',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: t.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '211 Clark Hall  |  (314) 516-5705\nVeteransOffice@umsl.edu',
                  style: TextStyle(
                    fontSize: 12,
                    color: t.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Acknowledgment checkbox
          GestureDetector(
            onTap: () => setState(() => _checked = !_checked),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: _checked
                        ? AppTheme.accentGold
                        : Colors.transparent,
                    border: Border.all(
                      color: _checked
                          ? AppTheme.accentGold
                          : Colors.white38,
                      width: 1.5,
                    ),
                  ),
                  child: _checked
                      ? Icon(Icons.check, size: 14, color: Colors.black)
                      : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'I understand this app is a helpful tool and I am responsible '
                    'for verifying my own requirements.',
                    style: TextStyle(fontSize: 13, color: t.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Accept button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _checked
                  ? () async {
                      await ref
                          .read(checklistProvider.notifier)
                          .acceptDisclaimer();
                      if (context.mounted) Navigator.of(context).pop();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: t.textOnDark,
                disabledBackgroundColor: Colors.white12,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Got it — show my checklist',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
