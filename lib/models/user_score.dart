/// Simple leaderboard user model
class UserScore {
  final String uid;
  final String name;
  final int points;

  UserScore({
    required this.uid,
    required this.name,
    required this.points, String? photoUrl,
  });
}