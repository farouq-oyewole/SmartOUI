// lib/providers/coordinates_provider.dart
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Model to hold coordinates and fallback flag
class Coordinates {
  final double latitude;
  final double longitude;
  final bool isFallback;

  Coordinates({
    required this.latitude,
    required this.longitude,
    this.isFallback = false,
  });
}

final coordinatesProvider = FutureProvider<Coordinates>((ref) async {
  final completer = Completer<Coordinates>();

  if (kIsWeb) {
    try {
      html.window.navigator.geolocation.getCurrentPosition().then((pos) {
        final coords = pos.coords;
        if (coords != null &&
            coords.latitude != null &&
            coords.longitude != null) {
          completer.complete(
            Coordinates(
              latitude: coords.latitude!.toDouble(),
              longitude: coords.longitude!.toDouble(),
              isFallback: false,
            ),
          );
        } else {
          completer.complete(
            Coordinates(latitude: 7.5629, longitude: 4.5200, isFallback: true),
          );
        }
      }).catchError((err) {
        completer.complete(
          Coordinates(latitude: 7.5629, longitude: 4.5200, isFallback: true),
        );
      });

      return completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => Coordinates(
          latitude: 7.5629,
          longitude: 4.5200,
          isFallback: true,
        ),
      );
    } catch (e) {
      return Coordinates(
        latitude: 7.5629,
        longitude: 4.5200,
        isFallback: true,
      );
    }
  } else {
    // Non-web fallback (e.g., mobile)
    return Coordinates(
      latitude: 7.5629,
      longitude: 4.5200,
      isFallback: true,
    );
  }
});
