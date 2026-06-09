import 'dart:async';
import 'package:flutter/foundation.dart';

/// Fires [onTimeout] after [timeout] of no user activity.
/// Call [resetTimer] on every pointer event.
/// Call [dispose] when the app is closed.
class InactivityService {
  InactivityService({
    this.timeout = const Duration(minutes: 5),
    required this.onTimeout,
  });

  final Duration timeout;
  final VoidCallback onTimeout;

  Timer? _timer;

  void start() => _resetTimer();

  void resetTimer() => _resetTimer();

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(timeout, onTimeout);
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
