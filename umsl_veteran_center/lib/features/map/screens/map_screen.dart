// lib/features/map/screens/map_screen.dart
//
// Campus map tab.
// Interactive map powered by flutter_map + OpenStreetMap (free, no API key).
// Tapping a pin or card opens a detail sheet.
// "Directions" launches Apple Maps or Google Maps — user's choice.
// All locations loaded from assets/data/campus_map.json.

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/campus_location.dart';
import '../providers/map_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../core/theme/vet_theme.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // Animate the map to center on a location
  void _flyTo(CampusLocation loc) {
    _mapController.move(
      LatLng(loc.latitude, loc.longitude),
      17.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t     = context.vetTheme;
    final state = ref.watch(mapProvider);

    if (state.loading) {
      return Scaffold(
        backgroundColor: t.pageBackground,
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Scaffold(
      backgroundColor: t.pageBackground,
      body: Column(
        children: [
          // ── Status bar safe area ──
          SafeArea(bottom: false, child: const SizedBox.shrink()),

          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Campus Map',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: t.textPrimary)),
                      Text('UMSL — 1 University Blvd., St. Louis',
                          style: TextStyle(fontSize: 12, color: t.textTertiary)),
                    ],
                  ),
                ),
                // Settings gear
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.settings_outlined, size: 22, color: t.textTertiary),
                  ),
                ),
                // Open full campus in Maps
                _OpenMapsButton(
                  label: 'Full campus',
                  query: 'University of Missouri St. Louis, 1 University Blvd., St. Louis, MO 63121',
                  lat: state.campusLat,
                  lng: state.campusLng,
                ),
              ],
            ),
          ),

          // ── Interactive map ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            height: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: t.cardBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(state.campusLat, state.campusLng),
                initialZoom:   state.defaultZoom.toDouble(),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                // OpenStreetMap tiles — free, no API key
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'edu.umsl.veteranscenter',
                ),
                // Location pins
                MarkerLayer(
                  markers: state.filteredLocations.map((loc) {
                    final isSelected = loc.id == state.selectedLocationId;
                    return Marker(
                      point: LatLng(loc.latitude, loc.longitude),
                      width:  isSelected ? 40 : 32,
                      height: isSelected ? 40 : 32,
                      child: GestureDetector(
                        onTap: () {
                          ref.read(mapProvider.notifier).selectLocation(loc.id);
                          _flyTo(loc);
                        },
                        child: _MapPin(
                          pinColor: loc.pinColor,
                          isSelected: isSelected,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Category filter chips ──
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: state.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final cat = state.categories[i];
                final isOn = state.selectedCategory == cat.id;
                return GestureDetector(
                  onTap: () =>
                      ref.read(mapProvider.notifier).selectCategory(cat.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isOn
                          ? t.selectedBackground
                          : t.unselectedBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isOn ? t.selectedBorder : t.cardBorder,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        cat.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isOn ? t.textOnDark : t.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          // ── Location list ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              itemCount: state.filteredLocations.length,
              itemBuilder: (context, i) {
                final loc       = state.filteredLocations[i];
                final isSelected = loc.id == state.selectedLocationId;
                return _LocationCard(
                  location:   loc,
                  isSelected: isSelected,
                  onTap: () {
                    ref.read(mapProvider.notifier).selectLocation(loc.id);
                    _flyTo(loc);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Map pin widget
// ---------------------------------------------------------------------------
class _MapPin extends StatelessWidget {
  final String pinColor;
  final bool isSelected;
  const _MapPin({required this.pinColor, required this.isSelected});

  Color get _color {
    switch (pinColor) {
      case 'red':    return const Color(0xFFC8102E);
      case 'gold':   return const Color(0xFFF5A800);
      case 'blue':   return const Color(0xFF378ADD);
      case 'green':  return const Color(0xFF2E7D32);
      case 'purple': return const Color(0xFF7B1FA2);
      case 'gray':   return const Color(0xFF607D8B);
      default:       return const Color(0xFFC8102E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: isSelected ? 3 : 2),
        boxShadow: [
          BoxShadow(
            color: _color.withOpacity(0.4),
            blurRadius: isSelected ? 8 : 4,
            spreadRadius: isSelected ? 2 : 0,
          ),
        ],
      ),
      child: isSelected
          ? const Icon(Icons.location_on, color: Colors.white, size: 18)
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Location card in the list
// ---------------------------------------------------------------------------
class _LocationCard extends StatelessWidget {
  final CampusLocation location;
  final bool isSelected;
  final VoidCallback onTap;

  const _LocationCard({
    required this.location,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: t.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryRed.withOpacity(0.5)
                : t.cardBorder,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + room
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(location.name,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: t.textPrimary)),
                    if (location.roomLabel.isNotEmpty)
                      Text(location.roomLabel,
                          style: TextStyle(
                              fontSize: 11, color: t.textTertiary)),
                  ],
                ),
              ),
              // Today's hours badge
              if (location.todayHours.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    location.todayHours,
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: t.accentGold),
                  ),
                ),
            ]),

            // Description
            if (isSelected && location.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(location.description,
                  style: TextStyle(
                      fontSize: 11,
                      color: t.textSecondary,
                      height: 1.5)),
            ],

            // Action buttons — shown when selected
            if (isSelected) ...[
              const SizedBox(height: 10),
              Row(children: [
                // Directions — shows map choice sheet
                Expanded(
                  child: _ActionBtn(
                    icon:  Icons.directions_rounded,
                    label: 'Directions',
                    color: AppTheme.primaryRed,
                    onTap: () => _showMapsChoice(context, location),
                  ),
                ),
                if (location.phone.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Expanded(
                    child: _ActionBtn(
                      icon:  Icons.phone_outlined,
                      label: location.phone,
                      color: AppTheme.accentGold,
                      onTap: () async {
                        final uri = Uri.parse(location.phoneTel);
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      },
                    ),
                  ),
                ],
                if (location.website.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _IconBtn(
                    icon: Icons.open_in_new,
                    color: t.textTertiary,
                    onTap: () async {
                      final uri = Uri.parse(location.website);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ],
              ]),
            ],
          ],
        ),
      ),
    );
  }

  // Show bottom sheet asking Apple Maps or Google Maps
  void _showMapsChoice(BuildContext context, CampusLocation location) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MapsChoiceSheet(location: location),
    );
  }
}

// ---------------------------------------------------------------------------
// Maps choice bottom sheet — Apple Maps or Google Maps
// ---------------------------------------------------------------------------
class _MapsChoiceSheet extends StatelessWidget {
  final CampusLocation location;
  const _MapsChoiceSheet({required this.location});

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    final encoded = Uri.encodeComponent(location.mapsQuery);
    final lat = location.latitude;
    final lng = location.longitude;

    return Container(
      decoration: BoxDecoration(
        color: t.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
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
                color: t.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Open directions to',
              style: TextStyle(fontSize: 12, color: t.textTertiary)),
          const SizedBox(height: 2),
          Text(location.name,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: t.textPrimary)),
          const SizedBox(height: 16),

          // Apple Maps
          _MapsOption(
            icon: Icons.map_outlined,
            label: 'Apple Maps',
            sublabel: 'Opens in Apple Maps',
            color: const Color(0xFF147EFB),
            onTap: () async {
              Navigator.of(context).pop();
              final uri = Uri.parse(
                  'http://maps.apple.com/?daddr=$encoded&dirflg=d');
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
          ),
          const SizedBox(height: 8),

          // Google Maps
          _MapsOption(
            icon: Icons.map_rounded,
            label: 'Google Maps',
            sublabel: 'Opens in Google Maps app or browser',
            color: const Color(0xFF4285F4),
            onTap: () async {
              Navigator.of(context).pop();
              // Tries Google Maps app first, falls back to browser
              final appUri = Uri.parse(
                  'comgooglemaps://?daddr=$lat,$lng&directionsmode=driving');
              final webUri = Uri.parse(
                  'https://www.google.com/maps/dir/?api=1&destination=$encoded');
              if (await canLaunchUrl(appUri)) {
                await launchUrl(appUri);
              } else {
                await launchUrl(webUri,
                    mode: LaunchMode.externalApplication);
              }
            },
          ),
          const SizedBox(height: 8),

          // Cancel
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: t.unselectedBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Cancel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: t.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapsOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _MapsOption({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.cardBorder),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: t.textPrimary)),
                Text(sublabel,
                    style: TextStyle(fontSize: 11, color: t.textTertiary)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: t.textTertiary, size: 18),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Open full campus in Maps button
// ---------------------------------------------------------------------------
class _OpenMapsButton extends StatelessWidget {
  final String label;
  final String query;
  final double lat;
  final double lng;
  const _OpenMapsButton({
    required this.label,
    required this.query,
    required this.lat,
    required this.lng,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showChoice(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.map_outlined,
              size: 13, color: AppTheme.primaryRed),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryRed)),
        ]),
      ),
    );
  }

  void _showChoice(BuildContext context) {
    final encoded = Uri.encodeComponent(query);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MapsChoiceSheet(
        location: CampusLocation(
          id: 'campus',
          name: 'UMSL Campus',
          shortName: 'UMSL',
          category: 'campus',
          building: '',
          room: '',
          address: query,
          latitude: lat,
          longitude: lng,
          mapsQuery: query,
          phone: '',
          phoneTel: '',
          email: '',
          website: '',
          hours: const [],
          description: '',
          pinColor: 'red',
          featured: false,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color),
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.vetTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: t.unselectedBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: t.cardBorder),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
