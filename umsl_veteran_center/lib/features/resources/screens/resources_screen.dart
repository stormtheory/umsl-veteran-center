// lib/features/resources/screens/resources_screen.dart
//
// Resources tab — UMSL Veterans Center info, quick links, VA resources,
// and all external contacts driven from contacts.json.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../core/theme/vet_theme.dart';
import '../../../shared/services/contacts_service.dart';
import '../../../shared/services/report_service.dart';

class ResourcesScreen extends ConsumerWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.vetTheme;
    final contactsAsync = ref.watch(contactsProvider);

    return Scaffold(
      backgroundColor: t.pageBackground,
      body: SafeArea(
        child: contactsAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, __) => Center(
            child: Text(
              'Could not load resources.',
              style: TextStyle(color: t.textTertiary),
            ),
          ),
          data: (contacts) => ListView(
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
                          Text('Resources',
                              style: TextStyle(fontSize: 20,
                                  fontWeight: FontWeight.w500, color: t.textPrimary)),
                          const SizedBox(height: 2),
                          Text('UMSL Veterans Center and VA resources',
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

              // Vet Center photo + lounge description
              _VetCenterHero(office: contacts.vetCenter),

              const SizedBox(height: 10),

              // Quick links — certification forms, student resources
              _SectionHeader('Quick links'),
              _LinkTile(
                icon: Icons.assignment_outlined,
                label: 'Request Certification 2025-26',
                color: const Color(0xFF4CAF50),
                url: 'https://forms.office.com/r/1CsXHVMVj5',
              ),
              _LinkTile(
                icon: Icons.assignment_outlined,
                label: 'Request Certification 2026-27',
                color: const Color(0xFF4CAF50),
                url: 'https://forms.office.com/pages/responsepage.aspx?id=vv3-4-n3G0ClGjVeAbBaibve995G-OtLrlBT6H3BDrhUMjZXVENENTRPUUlUNDIwSlREM1FZMk1LVi4u&route=shorturl',
              ),
              _LinkTile(
                icon: Icons.school_outlined,
                label: 'Apply for VA Education Benefits',
                color: AppTheme.accentGold,
                url: 'https://www.va.gov/education/how-to-apply/',
              ),
              _LinkTile(
                icon: Icons.account_balance_outlined,
                label: 'In-State Tuition Information',
                color: AppTheme.accentGold,
                url: 'https://www.umsl.edu/veterans/admissions-checklist/in-state-tuition-rates.html',
              ),
              _LinkTile(
                icon: Icons.laptop_outlined,
                label: 'UMSL Student Technology Resources',
                color: const Color(0xFF378ADD),
                url: 'https://www.umsl.edu/technology/resources/students.html',
              ),
              _LinkTile(
                icon: Icons.web_outlined,
                label: 'MyGateway Student Portal',
                color: const Color(0xFF378ADD),
                url: 'https://mygateway.umsl.edu',
              ),
              _LinkTile(
                icon: Icons.menu_book_outlined,
                label: 'About GI Bill Benefits',
                color: AppTheme.primaryRed,
                url: 'https://www.va.gov/education/about-gi-bill-benefits/',
              ),

              const SizedBox(height: 4),

              // Vet Center contact card
              if (contacts.vetCenter != null) ...[
                _SectionHeader('Vet Center'),
                _ContactCard(office: contacts.vetCenter!),
              ],

              // Campus offices
              _SectionHeader('Campus offices'),
              ...contacts.offices
                  .where((o) => o.id != 'vet_center')
                  .map((o) => _OfficeRow(office: o)),

              // VA resources
              _SectionHeader('VA resources'),
              ...contacts.externalResources
                  .where((e) => e.id != 'crisis_line')
                  .map((e) => _ExternalRow(contact: e)),

              // Crisis line — always last, always prominent
              _CrisisLineCard(contact: contacts.crisisLine!),

              SizedBox(height: 8),

              // Report general issue
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: GestureDetector(
                  onTap: () => ReportService.reportGeneral(contacts: contacts),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: t.cardBackground.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: t.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flag_outlined, size: 14, color: t.textTertiary),
                        SizedBox(width: 6),
                        Text(
                          'Report incorrect information',
                          style: TextStyle(fontSize: 12, color: t.textTertiary),
                        ),
                      ],
                    ),
                  ),
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
// Vet Center hero — photo + lounge description
// ---------------------------------------------------------------------------
class _VetCenterHero extends StatelessWidget {
  final office;
  const _VetCenterHero({required this.office});

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.cardBorder),
        color: Theme.of(context).colorScheme.surface,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo
          Image.asset(
            'assets/images/vet_center_lounge.jpg',
            width: double.infinity,
            height: 160,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 160,
              color: const Color(0xFF1A1A2E),
              child: Center(
                child: Icon(Icons.image_outlined, color: t.textTertiary, size: 32),
              ),
            ),
          ),
          // Description
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UMSL Student Veterans — First Stop',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: t.textPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'The UMSL Veterans Center aims to be the first stop for services '
                  'including admissions support, GI Bill advising and certification, '
                  'academic support, and networking with local military-friendly employers.',
                  style: TextStyle(
                    fontSize: 12,
                    color: t.textSecondary,
                    height: 1.6,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'The 1,100 sq. ft. student lounge has a never-empty coffee pot, '
                  'comfortable chairs, TVs and computers. Drop in to study, relax, '
                  'or just grab a free cup of coffee.',
                  style: TextStyle(
                    fontSize: 12,
                    color: t.textSecondary,
                    height: 1.6,
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
// Section header
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.2,
          color: t.textTertiary,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Link tile — color-coded by category
// ---------------------------------------------------------------------------
class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String url;

  const _LinkTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: t.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.open_in_new,
              size: 14,
              color: t.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full Vet Center contact card
// ---------------------------------------------------------------------------
class _ContactCard extends StatelessWidget {
  final OfficeContact office;
  const _ContactCard({required this.office});

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryRed.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            office.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: t.textPrimary,
            ),
          ),
          SizedBox(height: 2),
          Text(
            office.address.full,
            style: TextStyle(fontSize: 12, color: t.textSecondary),
          ),
          SizedBox(height: 10),
          Divider(color: t.divider, height: 1),
          SizedBox(height: 10),
          // Hours
          ...office.hours.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 160,
                      child: Text(
                        h.days,
                        style: TextStyle(
                          fontSize: 12,
                          color: t.textTertiary,
                        ),
                      ),
                    ),
                    Text(
                      h.hours,
                      style: TextStyle(
                        fontSize: 12,
                        color: t.textSecondary,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 10),
          // Phone + email buttons
          Row(
            children: [
              Expanded(
                child: _ContactButton(
                  icon: Icons.phone_outlined,
                  label: office.phone,
                  url: office.phoneTel,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _ContactButton(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  url: 'mailto:${office.email}',
                ),
              ),
            ],
          ),
          if (office.notes != null) ...[
            SizedBox(height: 8),
            Text(
              office.notes!,
              style: TextStyle(
                fontSize: 11,
                color: t.textTertiary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact office row for non-Vet-Center offices
// ---------------------------------------------------------------------------
class _OfficeRow extends StatelessWidget {
  final OfficeContact office;
  const _OfficeRow({required this.office});

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  office.shortName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: t.textPrimary,
                  ),
                ),
                Text(
                  office.phone,
                  style: TextStyle(fontSize: 11, color: t.textTertiary),
                ),
              ],
            ),
          ),
          _IconButton(
            icon: Icons.phone_outlined,
            url: office.phoneTel,
          ),
          const SizedBox(width: 8),
          _IconButton(
            icon: Icons.language_outlined,
            url: office.website,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// External resource row
// ---------------------------------------------------------------------------
class _ExternalRow extends StatelessWidget {
  final ExternalContact contact;
  const _ExternalRow({required this.contact});

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  contact.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: t.textPrimary,
                  ),
                ),
              ),
              _IconButton(icon: Icons.phone_outlined, url: contact.phoneTel),
              SizedBox(width: 8),
              _IconButton(icon: Icons.language_outlined, url: contact.website),
            ],
          ),
          SizedBox(height: 2),
          Text(
            contact.phone,
            style: TextStyle(fontSize: 11, color: t.textTertiary),
          ),
          if (contact.notes != null) ...[
            SizedBox(height: 4),
            Text(
              contact.notes!,
              style: TextStyle(
                fontSize: 11,
                color: t.textTertiary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Crisis line — always prominent, always last
// ---------------------------------------------------------------------------
class _CrisisLineCard extends StatelessWidget {
  final ExternalContact contact;
  const _CrisisLineCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A0A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryRed.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.health_and_safety_outlined,
                size: 16,
                color: Color(0xFFE53935),
              ),
              SizedBox(width: 6),
              Text(
                'Veterans Crisis Line',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: t.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'Free, confidential support for veterans in crisis — 24/7.',
            style: TextStyle(fontSize: 12, color: t.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ContactButton(
                  icon: Icons.phone_outlined,
                  label: '988 (press 1)',
                  url: 'tel:988',
                  color: const Color(0xFFE53935),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ContactButton(
                  icon: Icons.chat_outlined,
                  label: 'Text 838255',
                  url: 'sms:838255',
                  color: const Color(0xFFE53935),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------
class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  final Color color;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.url,
    this.color = AppTheme.accentGold,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final String url;

  const _IconButton({required this.icon, required this.url});

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: t.cardBorder,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: t.textSecondary),
      ),
    );
  }
}
