import 'package:bank_app/Providers/events_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final recentEventProvider =
    StateNotifierProvider<RecentEventNotifier, Event?>((ref) {
  return RecentEventNotifier();
});

class RecentEventNotifier extends StateNotifier<Event?> {
  RecentEventNotifier() : super(null);

  void setRecentEvent(Event event) {
    state = event;
  }
}
