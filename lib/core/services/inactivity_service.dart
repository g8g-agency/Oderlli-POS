import 'dart:async';
import 'package:flutter/foundation.dart';

/// Fires [onTimeout] after [timeout] of no user activity.
/// Call [resetTimer] on every pointer event.
/// Call [dispose] when the app is closed.
class InactivityService {
  InactivityService({
    this.timeout = const Duration(minutes: 5),
    this.onTimeout,
  });

  Duration timeout;
  VoidCallback? onTimeout;

  void updateTimeout(Duration newTimeout) {
    if (timeout == newTimeout) return;
    timeout = newTimeout;
    if (_timer != null) {
      _resetTimer();
    }
  }

  Timer? _timer;

  void start() => _resetTimer();

  void resetTimer() => _resetTimer();

  void _resetTimer() {
    _timer?.cancel();
    if (onTimeout != null) {
      _timer = Timer(timeout, onTimeout!);
    }
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
