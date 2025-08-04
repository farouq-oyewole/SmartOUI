import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ✅ This replaces the missing `selectedIndexProvider`
final selectedIndexProvider = StateNotifierProvider<SelectedIndexNotifier, int>((ref) {
  return SelectedIndexNotifier();
});

class SelectedIndexNotifier extends StateNotifier<int> {
  SelectedIndexNotifier() : super(0);

  void setIndex(int index) => state = index;
}

/// 📦 Enum used if you want to label routes/pages
enum NavigationItem {
  home(0, 'Home', 'home'),
  wallet(1, 'Wallet', 'wallet'),
  report(2, 'Report', 'report'),
  account(3, 'Account', 'account'),
  transactions(4, 'Transactions', 'transactions'),
  payments(5, 'Payments', 'payments'),
  profile(6, 'Profile', 'profile');

  const NavigationItem(this.indexq, this.label, this.route);

  final int indexq;
  final String label;
  final String route;
}

/// Optional: Current navigation item provider
final currentNavigationItemProvider = Provider<NavigationItem>((ref) {
  final index = ref.watch(selectedIndexProvider);
  return NavigationItem.values.firstWhere(
    (item) => item.index == index,
    orElse: () => NavigationItem.home,
  );
});
