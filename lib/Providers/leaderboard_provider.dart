import 'package:bank_app/Pages/quiz_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


/// Notifier to manage and sort leaderboard
class LeaderboardNotifier extends StateNotifier<List<UserScore>> {
  LeaderboardNotifier() : super([]);

  /// Set leaderboard and auto-sort by score descending
  void setLeaderboard(List<UserScore> users) {
    state = [...users]..sort((a, b) => b.points.compareTo(a.points));
  }

  /// Add or update a user’s score
  void updateUser(UserScore user) {
    final index = state.indexWhere((u) => u.uid == user.uid);
    if (index == -1) {
      state = [...state, user]..sort((a, b) => b.points.compareTo(a.points));
    } else {
      final newState = [...state];
      newState[index] = user;
      newState.sort((a, b) => b.points.compareTo(a.points));
      state = newState;
    }
  }

  void clear() => state = [];
}

/// Provider
final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, List<UserScore>>(
  (ref) => LeaderboardNotifier(),
);

/// Controls confetti
final confettiProvider = StateProvider<bool>((ref) => false);
