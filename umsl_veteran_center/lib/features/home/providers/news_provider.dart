// lib/features/home/providers/news_provider.dart
//
// Loads news.json from the assets/data/ bundle.
// To add or edit announcements: edit assets/data/news.json only.

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------
class NewsItem {
  final String tag;    // Short category label e.g. "Vet Center", "GI Bill"
  final String title;
  final String body;
  final String date;   // ISO 8601 display date — "2026-05-28"
  final NewsLink? link; // Optional external link — null if no link

  const NewsItem({
    required this.tag,
    required this.title,
    required this.body,
    required this.date,
    this.link,
  });

  factory NewsItem.fromJson(Map<String, dynamic> j) => NewsItem(
        tag: j['tag'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        date: j['date'] as String,
        link: j['link'] != null
            ? NewsLink.fromJson(j['link'] as Map<String, dynamic>)
            : null,
      );

  // Human-readable date e.g. "May 28, 2026"
  String get formattedDate {
    final dt = DateTime.tryParse(date);
    if (dt == null) return date;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }
}

class NewsLink {
  final String label;
  final String url;
  const NewsLink({required this.label, required this.url});

  factory NewsLink.fromJson(Map<String, dynamic> j) => NewsLink(
        label: j['label'] as String,
        url: j['url'] as String,
      );
}

// ---------------------------------------------------------------------------
// State notifier
// ---------------------------------------------------------------------------
class NewsNotifier extends StateNotifier<AsyncValue<List<NewsItem>>> {
  NewsNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/data/news.json');
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => NewsItem.fromJson(e as Map<String, dynamic>))
          .toList();
      // Most recent first — news.json should already be in this order,
      // but sort defensively so edits to the JSON don't break ordering
      list.sort((a, b) => b.date.compareTo(a.date));
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------
final newsProvider =
    StateNotifierProvider<NewsNotifier, AsyncValue<List<NewsItem>>>(
  (ref) => NewsNotifier(),
);
