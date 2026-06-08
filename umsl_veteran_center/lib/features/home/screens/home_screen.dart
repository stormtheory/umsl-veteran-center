// lib/features/home/screens/home_screen.dart
//
// Main home screen — one of the 5 tabs in the main shell.
// Sections:
//   1. Top bar — personalized greeting from Keychain first name
//   2. Calendar — interactive month grid with event detail panel
//   3. Announcements — news.json feed cards

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/news_provider.dart';
import '../widgets/home_calendar.dart';
import '../../../core/theme/app_theme.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../core/theme/vet_theme.dart';
import '../../../shared/services/storage_providers.dart';
import '../../../shared/services/secure_storage_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Scroll controller passed to HomeCalendar so it can scroll the page
  // when the user taps a date and the event panel expands below the fold
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          children: [
            // Top bar with greeting and avatar
            profileAsync.when(
              loading: () => const _TopBar(firstName: ''),
              error:   (_, __) => const _TopBar(firstName: ''),
              data:    (p) => _TopBar(firstName: p?.firstName ?? ''),
            ),

            // Calendar section
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _SectionLabel('Calendar'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: HomeCalendar(scrollController: _scrollController),
            ),

            // Announcements section
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: _SectionLabel('Announcements'),
            ),
            const _NewsSection(),

            // Bottom padding so last card clears the nav bar
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar — greeting + avatar initials
// ---------------------------------------------------------------------------
class _TopBar extends StatelessWidget {
  final String firstName;
  const _TopBar({required this.firstName});

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    final hour    = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final display  = firstName.isNotEmpty ? firstName : 'Veteran';
    final initials = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'V';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(fontSize: 13, color: Colors.white54),
                ),
                Text(
                  display,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: t.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Avatar — taps to open Settings
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.deepRed,
                border: Border.all(color: AppTheme.accentGold, width: 1.5),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.accentGold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label — small uppercase divider text
// ---------------------------------------------------------------------------
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
        color: t.textTertiary,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Announcements feed — loads from news.json via newsProvider
// ---------------------------------------------------------------------------
class _NewsSection extends ConsumerWidget {
  const _NewsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.vetTheme;
    final newsState = ref.watch(newsProvider);

    return newsState.when(
      loading: () => Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          'Could not load announcements.',
          style: TextStyle(color: t.textTertiary, fontSize: 13),
        ),
      ),
      data: (items) => Column(
        children: [
          for (int i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, i == items.length - 1 ? 0 : 8),
              child: _NewsCard(item: items[i]),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single announcement card
// ---------------------------------------------------------------------------
class _NewsCard extends StatelessWidget {
  final NewsItem item;
  const _NewsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
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
          // Tag pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              item.tag,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.8,
                color: AppTheme.accentGold,
              ),
            ),
          ),
          SizedBox(height: 6),
          // Title
          Text(
            item.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: t.textPrimary,
              height: 1.4,
            ),
          ),
          SizedBox(height: 4),
          // Body
          Text(
            item.body,
            style: TextStyle(
              fontSize: 12,
              color: t.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 6),
          // Date + optional link
          Row(
            children: [
              Text(
                item.formattedDate,
                style: TextStyle(fontSize: 11, color: Colors.white24),
              ),
              if (item.link != null) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.tryParse(item.link!.url);
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
                        item.link!.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.accentGold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
