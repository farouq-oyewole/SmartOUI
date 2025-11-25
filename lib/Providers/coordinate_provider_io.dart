// lib/providers/coordinates_provider_io.dart
// ignore_for_file: file_names, deprecated_member_use
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class IOPosition {
  final double latitude;
  final double longitude;
  IOPosition(this.latitude, this.longitude);
}

/// On mobile/desktop use geolocator (permission checks)
final coordinatesProviderImpl = FutureProvider<IOPosition>((ref) async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception('Location services disabled on device.');
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied.');
    }
  }
  if (permission == LocationPermission.deniedForever) {
    throw Exception('Location permission permanently denied. Enable from settings.');
  }

  final pos = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
    timeLimit: const Duration(seconds: 15),
  );

  return IOPosition(pos.latitude, pos.longitude);
});
