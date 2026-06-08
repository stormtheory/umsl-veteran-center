// lib/shell/main_shell.dart
//
// Root scaffold that hosts the 5-tab navigation shell.
// Uses a custom floating pill nav bar (Style B from design review).
//
// Tab order:
//   0  Home        — news feed + calendar
//   1  Checklist   — semester checklist (stub)
//   2  Resources   — Vet Center + VA links (stub)
//   3  BAH         — housing allowance calculator (stub)
//   4  Settings    — theme, text size, notifications (stub)

import 'package:flutter/material.dart';
import '../features/home/screens/home_screen.dart';
import '../features/checklist/screens/checklist_screen.dart';
import '../features/resources/screens/resources_screen.dart';
import '../features/map/screens/map_screen.dart';
import '../features/bah/screens/bah_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/vet_theme.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _activeIndex = 0;

  // Screens are kept in an IndexedStack so state is preserved across tab switches
  static const _screens = [
    HomeScreen(),
    ChecklistScreen(),
    ResourcesScreen(),
    BahScreen(),
    MapScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: IndexedStack(
        index: _activeIndex,
        children: _screens,
      ),
      // Floating pill nav bar rendered as a persistent bottom widget
      bottomNavigationBar: _PillNavBar(
        activeIndex: _activeIndex,
        onTap: (i) => setState(() => _activeIndex = i),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Floating pill navigation bar (Style B)
// ---------------------------------------------------------------------------
class _PillNavBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTap;

  const _PillNavBar({required this.activeIndex, required this.onTap});

  static const _tabs = [
    (icon: Icons.home_rounded,      label: 'Home'),
    (icon: Icons.checklist_rounded, label: 'Checklist'),
    (icon: Icons.menu_book_rounded, label: 'Resources'),
    (icon: Icons.calculate_rounded, label: 'BAH'),
    (icon: Icons.map_outlined,      label: 'Map'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      // Transparent — scaffold background shows through cleanly
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPadding + 8),
      child: Container(
        // Pill container
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: t.unselectedBackground,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
        ),
        child: Row(
          children: List.generate(_tabs.length, (i) {
            final tab      = _tabs[i];
            final isActive = i == activeIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: isActive
                        ? t.selectedBackground
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.icon,
                        size: 22,
                        color: isActive
                            ? t.accentGold
                            : t.textTertiary,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: isActive
                              ? t.accentGold
                              : t.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stub screen — placeholder for tabs not yet built
// ---------------------------------------------------------------------------
class _StubScreen extends StatelessWidget {
  final String label;
  final IconData icon;
  const _StubScreen({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.white12),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white24,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Coming soon',
              style: TextStyle(fontSize: 12, color: Colors.white24),
            ),
          ],
        ),
      ),
    );
  }
}
