import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/formatters.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

// Provider for current user balance
final balanceProvider = Provider<double>((ref) {
  final user = ref.watch(currentAppUserProvider);
  return user?.balance ?? 0.0;
});

// Provider for formatted balance
final formattedBalanceProvider = Provider<String>((ref) {
  final balance = ref.watch(balanceProvider);
  return Formatters.formatCurrency(balance);
});

// Provider for balance visibility state
final balanceVisibilityProvider = StateProvider<bool>((ref) => true);

// Provider for displayed balance (considering visibility)
final displayedBalanceProvider = Provider<String>((ref) {
  final isVisible = ref.watch(balanceVisibilityProvider);
  final formattedBalance = ref.watch(formattedBalanceProvider);

  return isVisible ? formattedBalance : '••••••';
});

// Provider for card number
final cardNumberProvider = Provider<String>((ref) {
  final user = ref.watch(currentAppUserProvider);
  return user?.cardNumber ?? '1234567890123456';
});

// Provider for formatted card number
final formattedCardNumberProvider = Provider<String>((ref) {
  final cardNumber = ref.watch(cardNumberProvider);
  return Formatters.formatCardNumber(cardNumber);
});

// Balance notifier for handling balance operations
class BalanceNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final FirestoreService _firestoreService;

  BalanceNotifier(this._ref, this._firestoreService) : super(const AsyncValue.data(null));

  void toggleBalanceVisibility() {
    final currentVisibility = _ref.read(balanceVisibilityProvider);
    _ref.read(balanceVisibilityProvider.notifier).state = !currentVisibility;
  }

  Future<void> refreshBalance() async {
    try {
      state = const AsyncValue.loading();
      _ref.invalidate(currentAppUserProvider);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateBalance(double newBalance) async {
    final user = _ref.read(currentAppUserProvider);
    if (user != null) {
      try {
        state = const AsyncValue.loading();
        await _firestoreService.updateUserBalance(user.id, newBalance);
        _ref.invalidate(currentAppUserProvider);
        state = const AsyncValue.data(null);
      } catch (e) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  Future<void> addToBalance(double amount) async {
    final currentBalance = _ref.read(balanceProvider);
    await updateBalance(currentBalance + amount);
  }

  Future<void> subtractFromBalance(double amount) async {
    final currentBalance = _ref.read(balanceProvider);
    if (currentBalance >= amount) {
      await updateBalance(currentBalance - amount);
    } else {
      throw Exception('Insufficient balance');
    }
  }

  bool get isBalanceVisible => _ref.read(balanceVisibilityProvider);
}

final balanceNotifierProvider = StateNotifierProvider<BalanceNotifier, AsyncValue<void>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return BalanceNotifier(ref, firestoreService);
});
