import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class InteractionListener extends ConsumerStatefulWidget {
  const InteractionListener({
    super.key,
    required this.child,
    this.timeout = const Duration(minutes: 5),
  });

  final Widget child;
  final Duration timeout;

  @override
  ConsumerState<InteractionListener> createState() => _InteractionListenerState();
}

class _InteractionListenerState extends ConsumerState<InteractionListener> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(widget.timeout, _onTimeout);
  }

  void _onTimeout() {
    final auth = ref.read(authProvider);
    // Only lock if a user is logged in and not already locked
    if (auth.user != null && !auth.isLocked) {
      ref.read(authProvider.notifier).lock();
    }
  }

  void _handleInteraction(PointerEvent event) {
    // Only reset timer if someone is logged in
    final auth = ref.read(authProvider);
    if (auth.user != null) {
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes to reset timer when logging in/out
    ref.listen(authProvider, (previous, next) {
      if (next.user != null) {
        _startTimer();
      } else {
        _timer?.cancel();
      }
    });

    return Listener(
      onPointerDown: _handleInteraction,
      onPointerMove: _handleInteraction,
      child: widget.child,
    );
  }
}
