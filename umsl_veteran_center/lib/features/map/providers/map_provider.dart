// lib/features/map/providers/map_provider.dart
//
// Loads campus_map.json and manages map state:
//   - All campus locations
//   - Active category filter
//   - Currently selected location

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/campus_location.dart';

class MapState {
  final bool loading;
  final List<CampusLocation> locations;
  final List<MapCategory> categories;
  final String selectedCategory; // "all" or a category id
  final String? selectedLocationId;
  final double campusLat;
  final double campusLng;
  final int defaultZoom;

  const MapState({
    this.loading = true,
    this.locations = const [],
    this.categories = const [],
    this.selectedCategory = 'all',
    this.selectedLocationId,
    this.campusLat = 38.7106,
    this.campusLng = -90.3112,
    this.defaultZoom = 16,
  });

  MapState copyWith({
    bool? loading,
    List<CampusLocation>? locations,
    List<MapCategory>? categories,
    String? selectedCategory,
    String? selectedLocationId,
    double? campusLat,
    double? campusLng,
    int? defaultZoom,
  }) => MapState(
    loading:            loading            ?? this.loading,
    locations:          locations          ?? this.locations,
    categories:         categories         ?? this.categories,
    selectedCategory:   selectedCategory   ?? this.selectedCategory,
    selectedLocationId: selectedLocationId ?? this.selectedLocationId,
    campusLat:          campusLat          ?? this.campusLat,
    campusLng:          campusLng          ?? this.campusLng,
    defaultZoom:        defaultZoom        ?? this.defaultZoom,
  );

  // Filtered locations based on selected category
  List<CampusLocation> get filteredLocations {
    if (selectedCategory == 'all') return locations;
    return locations.where((l) => l.category == selectedCategory).toList();
  }

  // Currently selected location object
  CampusLocation? get selectedLocation =>
      selectedLocationId != null
          ? locations.where((l) => l.id == selectedLocationId).firstOrNull
          : null;
}

class MapNotifier extends StateNotifier<MapState> {
  MapNotifier() : super(const MapState()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final raw  = await rootBundle.loadString('assets/data/campus_map.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;

      final campus    = json['campus'] as Map<String, dynamic>;
      final locations = (json['locations'] as List<dynamic>)
          .map((l) => CampusLocation.fromJson(l as Map<String, dynamic>))
          .toList();
      final categories = (json['categories'] as List<dynamic>)
          .map((c) => MapCategory.fromJson(c as Map<String, dynamic>))
          .toList();

      // Auto-select the Vet Center on load
      final featured = locations.where((l) => l.featured).toList();

      state = state.copyWith(
        loading:            false,
        locations:          locations,
        categories:         categories,
        campusLat:          (campus['latitude'] as num).toDouble(),
        campusLng:          (campus['longitude'] as num).toDouble(),
        defaultZoom:        campus['default_zoom'] as int? ?? 16,
        selectedLocationId: featured.isNotEmpty ? featured.first.id : null,
      );
    } catch (e) {
      state = state.copyWith(loading: false);
    }
  }

  void selectCategory(String category) {
    state = state.copyWith(
      selectedCategory:   category,
      selectedLocationId: null, // clear selection when changing category
    );
  }

  void selectLocation(String id) {
    state = state.copyWith(selectedLocationId: id);
  }

  void clearSelection() {
    state = state.copyWith(selectedLocationId: null);
  }
}

final mapProvider = StateNotifierProvider<MapNotifier, MapState>(
  (ref) => MapNotifier(),
);
