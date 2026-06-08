// lib/features/home/providers/calendar_provider.dart
//
// Loads calendar.json from the assets/data/ bundle.
// Each event carries a type: "green", "gold", or "red" which maps
// directly to the color coding shown on the calendar grid.
//
// Adding or editing events: edit assets/data/calendar.json only.
// No Dart changes needed unless the schema itself changes.

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------
class CalendarEvent {
  final String date;       // ISO 8601 — "2026-06-05"
  final String type;       // "green" | "gold" | "red"
  final String name;
  final String time;       // empty string if all-day
  final String location;   // empty string if none
  final String desc;
  final List<EventLink> links;

  const CalendarEvent({
    required this.date,
    required this.type,
    required this.name,
    required this.time,
    required this.location,
    required this.desc,
    required this.links,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> j) => CalendarEvent(
        date: j['date'] as String,
        type: j['type'] as String,
        name: j['name'] as String,
        time: j['time'] as String? ?? '',
        location: j['location'] as String? ?? '',
        desc: j['desc'] as String? ?? '',
        links: (j['links'] as List<dynamic>? ?? [])
            .map((l) => EventLink.fromJson(l as Map<String, dynamic>))
            .toList(),
      );

  // Returns the DateTime for this event (midnight UTC)
  DateTime get dateTime => DateTime.parse(date);
}

class EventLink {
  final String label;
  final String url;
  const EventLink({required this.label, required this.url});

  factory EventLink.fromJson(Map<String, dynamic> j) => EventLink(
        label: j['label'] as String,
        url: j['url'] as String,
      );
}

// ---------------------------------------------------------------------------
// State notifier
// ---------------------------------------------------------------------------
class CalendarNotifier extends StateNotifier<AsyncValue<List<CalendarEvent>>> {
  CalendarNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      // Load the bundled JSON asset
      final raw = await rootBundle.loadString('assets/data/calendar.json');
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
          .toList();
      // Sort ascending by date so iteration is predictable
      list.sort((a, b) => a.date.compareTo(b.date));
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Returns all events for a given day
  List<CalendarEvent> eventsForDay(DateTime day) {
    if (state is! AsyncData) return [];
    final key =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return (state as AsyncData<List<CalendarEvent>>).value
        .where((e) => e.date == key)
        .toList();
  }

  // Returns the distinct event types present on a given day (for dot rendering)
  Set<String> typesForDay(DateTime day) =>
      eventsForDay(day).map((e) => e.type).toSet();
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------
final calendarProvider =
    StateNotifierProvider<CalendarNotifier, AsyncValue<List<CalendarEvent>>>(
  (ref) => CalendarNotifier(),
);
