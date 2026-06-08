// lib/features/map/models/campus_location.dart
//
// Model for a campus location loaded from assets/data/campus_map.json.
// To add or edit locations: edit the JSON only. No Dart changes needed.

class MapHours {
  final String days;
  final String hours;
  const MapHours({required this.days, required this.hours});

  factory MapHours.fromJson(Map<String, dynamic> j) => MapHours(
        days:  j['days'] as String,
        hours: j['hours'] as String,
      );
}

class CampusLocation {
  final String id;
  final String name;
  final String shortName;
  final String category;
  final String building;
  final String room;
  final String address;
  final double latitude;
  final double longitude;
  final String mapsQuery;   // passed to Apple Maps or Google Maps
  final String phone;
  final String phoneTel;
  final String email;
  final String website;
  final List<MapHours> hours;
  final String description;
  final String pinColor;
  final bool featured;

  const CampusLocation({
    required this.id,
    required this.name,
    required this.shortName,
    required this.category,
    required this.building,
    required this.room,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.mapsQuery,
    required this.phone,
    required this.phoneTel,
    required this.email,
    required this.website,
    required this.hours,
    required this.description,
    required this.pinColor,
    required this.featured,
  });

  factory CampusLocation.fromJson(Map<String, dynamic> j) => CampusLocation(
        id:          j['id'] as String,
        name:        j['name'] as String,
        shortName:   j['short_name'] as String,
        category:    j['category'] as String,
        building:    j['building'] as String? ?? '',
        room:        j['room'] as String? ?? '',
        address:     j['address'] as String? ?? '',
        latitude:    (j['latitude'] as num).toDouble(),
        longitude:   (j['longitude'] as num).toDouble(),
        mapsQuery:   j['maps_query'] as String? ?? '',
        phone:       j['phone'] as String? ?? '',
        phoneTel:    j['phone_tel'] as String? ?? '',
        email:       j['email'] as String? ?? '',
        website:     j['website'] as String? ?? '',
        hours: (j['hours'] as List<dynamic>? ?? [])
            .map((h) => MapHours.fromJson(h as Map<String, dynamic>))
            .toList(),
        description: j['description'] as String? ?? '',
        pinColor:    j['pin_color'] as String? ?? 'red',
        featured:    j['featured'] as bool? ?? false,
      );

  // Human-readable room string e.g. "211 Clark Hall"
  String get roomLabel =>
      room.isNotEmpty ? '$room $building' : building;

  // Today's hours — returns first matching entry or "Hours unavailable"
  String get todayHours {
    if (hours.isEmpty) return '';
    final day = DateTime.now().weekday; // 1=Mon, 7=Sun
    if (day >= 1 && day <= 4) {
      return hours.firstWhere(
        (h) => h.days.toLowerCase().contains('monday') ||
               h.days.toLowerCase().contains('daily'),
        orElse: () => hours.first,
      ).hours;
    } else if (day == 5) {
      return hours.firstWhere(
        (h) => h.days.toLowerCase().contains('friday') ||
               h.days.toLowerCase().contains('daily'),
        orElse: () => hours.first,
      ).hours;
    } else if (day == 6) {
      return hours.firstWhere(
        (h) => h.days.toLowerCase().contains('saturday') ||
               h.days.toLowerCase().contains('daily'),
        orElse: () => hours.first,
      ).hours;
    } else {
      return hours.firstWhere(
        (h) => h.days.toLowerCase().contains('sunday') ||
               h.days.toLowerCase().contains('daily'),
        orElse: () => hours.first,
      ).hours;
    }
  }
}

class MapCategory {
  final String id;
  final String label;
  final String icon;
  const MapCategory({required this.id, required this.label, required this.icon});

  factory MapCategory.fromJson(Map<String, dynamic> j) => MapCategory(
        id:    j['id'] as String,
        label: j['label'] as String,
        icon:  j['icon'] as String? ?? 'location',
      );
}
