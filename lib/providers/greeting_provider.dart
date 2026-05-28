import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/greeting_helper.dart';

/// Provider that exposes the current time-of-day greeting.
///
/// Automatically audits local device time and updates on boundaries.
final greetingProvider = StateNotifierProvider<GreetingNotifier, String>((ref) {
  return GreetingNotifier();
});

class GreetingNotifier extends StateNotifier<String> {
  GreetingNotifier() : super(GreetingHelper.getGreetingMessage()) {
    // Audit the device time every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      final newGreeting = GreetingHelper.getGreetingMessage();
      if (state != newGreeting) {
        state = newGreeting;
      }
    });
  }

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
