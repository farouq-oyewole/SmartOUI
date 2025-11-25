// lib/providers/reverse_geocode_provider.dart
// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// This file expects coordinatesProvider to be defined in ../providers/coordinate_provider.dart
import 'coordinate_provider.dart';

/// Returns a readable location string (city, state, country)
/// Falls back to "Osun State, Nigeria" when coordinates provider indicates fallback.
final reverseGeocodeProvider = FutureProvider<String>((ref) async {
  final coords = await ref.watch(coordinatesProvider.future);

  if (coords.isFallback) {
    // If fallback was used, return a clear label
    return 'Osun State, Nigeria';
  }

  final lat = coords.latitude;
  final lon = coords.longitude;

  try {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon',
    );

    // Nominatim requires a user-agent; include a simple header
    final res = await http.get(uri, headers: {
      'User-Agent': 'MSSN PrayerTimes App - Flutter',
      'Accept': 'application/json',
    });

    if (res.statusCode != 200) {
      return 'Location unavailable';
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final display = body['display_name'] as String?;
    if (display != null && display.isNotEmpty) {
      return display;
    }

    // Try building from address parts
    final address = body['address'] as Map<String, dynamic>? ?? {};
    final parts = <String>[];
    if (address['suburb'] != null) parts.add(address['suburb']);
    if (address['city'] != null) parts.add(address['city']);
    if (address['town'] != null) parts.add(address['town']);
    if (address['state'] != null) parts.add(address['state']);
    if (address['country'] != null) parts.add(address['country']);

    if (parts.isNotEmpty) return parts.join(', ');
    return 'Location unavailable';
  } catch (_) {
    return 'Location unavailable';
  }
});
