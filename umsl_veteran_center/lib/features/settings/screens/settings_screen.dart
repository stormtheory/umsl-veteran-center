// lib/features/settings/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vet_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/services/contacts_service.dart';
import '../../../shared/services/report_service.dart';
import '../../../shared/services/secure_storage_service.dart';
import '../../../shared/services/storage_providers.dart';
import '../../onboarding/screens/splash_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t            = context.vetTheme;
    final themeMode    = ref.watch(themeModeProvider);
    final contactsAsync = ref.watch(contactsProvider);
    final profileAsync  = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: t.pageBackground,
      appBar: AppBar(
        backgroundColor: t.pageBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: t.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Settings', style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w500, color: t.textPrimary,
        )),
        centerTitle: false,
      ),
      body: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            _SectionHeader('Profile'),
            profileAsync.when(
              loading: () => const SizedBox.shrink(),
              error:   (_, __) => const SizedBox.shrink(),
              data: (profile) => _ProfileCard(profile: profile),
            ),
            const SizedBox(height: 4),
            _SectionHeader('Appearance'),
            _ThemeSelector(current: themeMode),
            const SizedBox(height: 4),
            _SectionHeader('About'),
            const _InfoTile(label: 'Version',   value: '1.0.0'),
            const _InfoTile(label: 'Built for', value: 'UMSL Veterans Center'),
            const _InfoTile(label: 'Platform',  value: 'iOS · macOS'),
            const SizedBox(height: 4),
            _SectionHeader('Feedback'),
            contactsAsync.when(
              loading: () => const SizedBox.shrink(),
              error:   (_, __) => const SizedBox.shrink(),
              data: (contacts) => _ActionTile(
                icon:  Icons.flag_outlined,
                label: 'Report an issue or incorrect info',
                onTap: () => ReportService.reportGeneral(contacts: contacts),
              ),
            ),
            const SizedBox(height: 4),
            _SectionHeader('Privacy and data'),
            const _InfoTile(
              label: 'Data storage',
              value: 'On-device only',
              note:  'Your name, email, student ID, and checklist data are stored '
                     'in the iOS Keychain on this device only. Nothing is transmitted.',
            ),
            _ActionTile(
              icon:     Icons.person_outline_rounded,
              label:    'Reset personal data',
              sublabel: 'Clears your name, email, student ID, and checklist data',
              color:    Colors.white54,
              onTap:    () => _confirmResetPersonal(context, ref),
            ),
            _ActionTile(
              icon:     Icons.delete_forever_outlined,
              label:    'Full app reset',
              sublabel: 'Clears all data and returns to onboarding',
              color:    const Color(0xFFE53935),
              onTap:    () => _confirmFullReset(context, ref),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.cardBackground.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: t.cardBorder),
                ),
                child: Text(
                  'BAH/MHA calculations are estimates only. '
                  'Dates and tasks in the checklist may not reflect '
                  'the most current requirements. Always verify with '
                  'the VA and UMSL Veterans Center.',
                  style: TextStyle(fontSize: 11, color: t.textTertiary, height: 1.6),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
      ),
    );
  }

  void _confirmResetPersonal(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _ConfirmDialog(
        title:        'Reset personal data?',
        message:      'This will delete your saved name, email, student ID, '
                      'and all checklist progress. Theme preference is kept. '
                      'You will be asked to re-enter your profile.',
        confirmLabel: 'Reset data',
        confirmColor: Colors.white54,
        onConfirm: () async {
          final storage = ref.read(secureStorageProvider);
          await storage.delete('user_profile');
          await storage.delete('checklist_enrollments');
          await storage.delete('checklist_disclaimer_accepted');
          await storage.write('onboarding_complete', 'false');
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const SplashScreen()),
              (_) => false,
            );
          }
        },
      ),
    );
  }

  void _confirmFullReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _ConfirmDialog(
        title:        'Full app reset?',
        message:      'This permanently deletes everything — your profile, '
                      'all checklist data, theme preference, and all app settings. '
                      'This cannot be undone.',
        confirmLabel: 'Reset everything',
        confirmColor: const Color(0xFFE53935),
        onConfirm: () async {
          final storage = ref.read(secureStorageProvider);
          await storage.clearAll();
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const SplashScreen()),
              (_) => false,
            );
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _ProfileCard extends ConsumerWidget {
  final UserProfile? profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.vetTheme;
    if (profile == null) {
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.cardBorder),
        ),
        child: Text('No profile data saved.',
            style: TextStyle(fontSize: 13, color: t.textTertiary)),
      );
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(
        children: [
          _ProfileField(label: 'First name', value: profile!.firstName,
            onEdit: () => _editField(context, ref, label: 'First name',
              current: profile!.firstName,
              onSave: (val) async {
                final u = UserProfile(email: profile!.email,
                  firstName: val.trim(), lastName: profile!.lastName);
                await ref.read(secureStorageProvider).saveUserProfile(u);
                ref.invalidate(userProfileProvider);
              })),
          Divider(color: t.divider, height: 1),
          _ProfileField(label: 'Last name', value: profile!.lastName,
            onEdit: () => _editField(context, ref, label: 'Last name',
              current: profile!.lastName,
              onSave: (val) async {
                final u = UserProfile(email: profile!.email,
                  firstName: profile!.firstName, lastName: val.trim());
                await ref.read(secureStorageProvider).saveUserProfile(u);
                ref.invalidate(userProfileProvider);
              })),
          Divider(color: t.divider, height: 1),
          _ProfileField(label: 'University email', value: profile!.email,
            onEdit: () => _editField(context, ref, label: 'University email',
              current: profile!.email,
              keyboardType: TextInputType.emailAddress,
              onSave: (val) async {
                final u = UserProfile(email: val.trim(),
                  firstName: profile!.firstName, lastName: profile!.lastName);
                await ref.read(secureStorageProvider).saveUserProfile(u);
                ref.invalidate(userProfileProvider);
              })),

        ],
      ),
    );
  }

  void _editField(BuildContext context, WidgetRef ref, {
    required String label, required String current,
    required Future<void> Function(String) onSave,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter> inputFormatters = const [],
  }) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF13131F),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2A2A3A)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2A2A3A)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.accentGold, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) await onSave(controller.text);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Save', style: TextStyle(color: AppTheme.accentGold)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _ProfileField extends StatelessWidget {
  final String label;
  final String value;
  final bool masked;
  final VoidCallback onEdit;
  const _ProfileField({required this.label, required this.value,
      required this.onEdit, this.masked = false});

  String get _display {
    if (!masked || value.length <= 4) return value;
    return '••••${value.substring(value.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: t.textTertiary)),
          const SizedBox(height: 2),
          Text(_display, style: TextStyle(fontSize: 14, color: t.textPrimary)),
        ])),
        GestureDetector(
          onTap: onEdit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.accentGold.withOpacity(0.3)),
            ),
            child: const Text('Edit', style: TextStyle(
              fontSize: 12, color: AppTheme.accentGold, fontWeight: FontWeight.w500)),
          ),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
class _ThemeSelector extends ConsumerWidget {
  final ThemeMode current;
  const _ThemeSelector({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.vetTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Theme', style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w500, color: t.textPrimary)),
        const SizedBox(height: 12),
        Row(children: [
          _ThemeOption(icon: Icons.brightness_auto_rounded, label: 'System',
              mode: ThemeMode.system, current: current),
          const SizedBox(width: 8),
          _ThemeOption(icon: Icons.wb_sunny_rounded, label: 'Light',
              mode: ThemeMode.light,  current: current),
          const SizedBox(width: 8),
          _ThemeOption(icon: Icons.nights_stay_rounded, label: 'Dark',
              mode: ThemeMode.dark,   current: current),
        ]),
      ]),
    );
  }
}

class _ThemeOption extends ConsumerWidget {
  final IconData icon;
  final String label;
  final ThemeMode mode;
  final ThemeMode current;
  const _ThemeOption({required this.icon, required this.label,
      required this.mode, required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.vetTheme;
    final isSelected = current == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? t.selectedBackground
                : t.unselectedBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? t.selectedBorder
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Column(children: [
            Icon(icon, size: 22,
                color: isSelected ? AppTheme.accentGold : Colors.white38),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.white38,
            )),
          ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(title.toUpperCase(), style: TextStyle(
        fontSize: 10, fontWeight: FontWeight.w500,
        letterSpacing: 1.2, color: t.textTertiary,
      )),
    );
  }
}

// ---------------------------------------------------------------------------
class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final String? note;
  const _InfoTile({required this.label, required this.value, this.note});

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: t.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(fontSize: 13, color: t.textSecondary)),
          Text(value, style: TextStyle(fontSize: 13,
              fontWeight: FontWeight.w500, color: t.textPrimary)),
        ]),
        if (note != null) ...[
          const SizedBox(height: 6),
          Text(note!, style: TextStyle(fontSize: 11, color: t.textTertiary, height: 1.5)),
        ],
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sublabel;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label,
      required this.onTap, this.sublabel,
      this.color = AppTheme.accentGold});

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: t.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.cardBorder),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 13, color: color)),
              if (sublabel != null)
                Text(sublabel!, style: TextStyle(fontSize: 11, color: t.textTertiary)),
            ])),
          Icon(Icons.chevron_right, size: 16, color: color.withOpacity(0.4)),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;
  const _ConfirmDialog({required this.title, required this.message,
      required this.confirmLabel, required this.confirmColor,
      required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E2E),
      title: Text(title,
          style: const TextStyle(color: Colors.white, fontSize: 16)),
      content: Text(message,
          style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.5)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel',
              style: TextStyle(color: Colors.white38)),
        ),
        TextButton(
          onPressed: () { Navigator.of(context).pop(); onConfirm(); },
          child: Text(confirmLabel, style: TextStyle(color: confirmColor)),
        ),
      ],
    );
  }
}
