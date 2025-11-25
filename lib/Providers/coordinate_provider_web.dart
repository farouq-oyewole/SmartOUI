// lib/providers/coordinates_provider.dart
// ignore_for_file: file_names
import 'dart:async';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents the user's location or a fallback if unavailable.
class WebPosition {
  final double latitude;
  final double longitude;
  final bool isFallback;

  WebPosition(this.latitude, this.longitude, {this.isFallback = false});
}

/// Provides user's coordinates for web.
/// Falls back to Osun State, Nigeria if access is denied or unavailable.
final coordinatesProvider = FutureProvider<WebPosition>((ref) async {
  final completer = Completer<WebPosition>();

  // If browser doesn’t support geolocation
  // ignore: unnecessary_null_comparison
  if (html.window.navigator.geolocation == null) {
    return WebPosition(7.5629, 4.5200, isFallback: true);
  }

  try {
    html.window.navigator.geolocation.getCurrentPosition().then((pos) {
      final coords = pos.coords;
      if (coords == null) {
        completer.complete(WebPosition(7.5629, 4.5200, isFallback: true));
      } else {
        completer.complete(WebPosition(
          coords.latitude!.toDouble(),
          coords.longitude!.toDouble(),
          isFallback: false,
        ));
      }
    }).catchError((_) {
      completer.complete(WebPosition(7.5629, 4.5200, isFallback: true));
    });

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => WebPosition(7.5629, 4.5200, isFallback: true),
    );
  } catch (_) {
    return WebPosition(7.5629, 4.5200, isFallback: true);
  }
});
