import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileState {
  final String cardNumber;
  final double balance;

  ProfileState({
    required this.cardNumber,
    required this.balance,
  });

  ProfileState copyWith({
    String? cardNumber,
    double? balance,
  }) {
    return ProfileState(
      cardNumber: cardNumber ?? this.cardNumber,
      balance: balance ?? this.balance,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(ProfileState(cardNumber: '', balance: 5000000));

  void updateCardNumber(String newCard) {
    state = state.copyWith(cardNumber: newCard, balance: 5000000);
  }

  void deductBalance(double amount) {
    final double newBal = (state.balance - amount).clamp(0, double.infinity).toDouble();
    state = state.copyWith(balance: newBal);
  }

  void updateProfileBalance(double newBalance) {
  state = state.copyWith(balance: newBalance);
}

  void resetBalance() {
    state = state.copyWith(balance: 5000000);
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});
