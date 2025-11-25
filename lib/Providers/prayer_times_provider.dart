// lib/providers/prayer_times_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'coordinate_provider.dart';

/// Model representing prayer times
class PrayerTimes {
  final Map<String, dynamic> timings;

  PrayerTimes({required this.timings});

  factory PrayerTimes.fromJson(Map<String, dynamic> json) {
    return PrayerTimes(timings: json['data']['timings'] ?? {});
  }
}

/// Provider that fetches prayer times using Adhan API
final prayerTimesProvider = FutureProvider<PrayerTimes>((ref) async {
  final coordsAsync = await ref.watch(coordinatesProvider.future);
  final latitude = coordsAsync.latitude;
  final longitude = coordsAsync.longitude;
  // ignore: unused_local_variable
  final isFallback = coordsAsync.isFallback;

  // Use fallback to Osun State if location unavailable
  final double lat = latitude; // Osun State lat
  final double lon = longitude; // Osun State lon

  // Build the Adhan API endpoint
  final url =
      'https://api.aladhan.com/v1/timings?latitude=$lat&longitude=$lon&method=2';

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return PrayerTimes.fromJson(data);
    } else {
      throw Exception('Failed to load prayer times: ${response.statusCode}');
    }
  } catch (e) {
    // If something goes wrong, fall back to default Osun times
    final fallbackUrl =
        'https://api.aladhan.com/v1/timings?latitude=7.5629&longitude=4.5200&method=2';
    final res = await http.get(Uri.parse(fallbackUrl));
    final data = json.decode(res.body);
    return PrayerTimes.fromJson(data);
  }
});
