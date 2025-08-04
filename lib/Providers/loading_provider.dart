import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A generic loading state manager using string keys.
class LoadingNotifier extends StateNotifier<Map<String, bool>> {
  LoadingNotifier() : super({});

  /// Start loading for a specific key (e.g., 'profile', 'auth')
  void startLoading(String key) {
    state = {...state, key: true};
  }

  /// Stop loading for a specific key
  void stopLoading(String key) {
    final newState = Map<String, bool>.from(state);
    newState.remove(key);
    state = newState;
  }

  /// Stop all loading
  void stopAllLoading() {
    state = {};
  }

  /// Check if a specific key is loading
  bool isLoading(String key) => state[key] ?? false;

  /// Check if any loading is active (for global spinners)
  bool get hasAnyLoading => state.values.any((loading) => loading);
}

/// Main state notifier provider (returns the loading map)
final loadingNotifierProvider =
    StateNotifierProvider<LoadingNotifier, Map<String, bool>>((ref) {
  return LoadingNotifier();
});

/// Direct access to the LoadingNotifier itself (for calling start/stop methods)
final loadingProvider =
    StateNotifierProvider<LoadingNotifier, Map<String, bool>>(
  (ref) => LoadingNotifier(),
);

/// Whether *any* loading is active (used for global spinners)
final hasAnyLoadingProvider = Provider<bool>((ref) {
  return ref.watch(loadingNotifierProvider).values.any((loading) => loading);
});

/// Specific loading providers based on keys
final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(loadingNotifierProvider)['auth'] ?? false;
});

final profileLoadingProvider = Provider<bool>((ref) {
  return ref.watch(loadingNotifierProvider)['profile'] ?? false;
});

final paymentLoadingProvider = Provider<bool>((ref) {
  return ref.watch(loadingNotifierProvider)['payment'] ?? false;
});
