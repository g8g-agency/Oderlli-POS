import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/inactivity_service.dart';

/// Raw service — wired with callback in InactivityScope.
/// Exposed so widgets can call
///   ref.read(inactivityServiceProvider).resetTimer()
/// if needed for programmatic resets.
final inactivityServiceProvider = Provider<InactivityService>((ref) {
  final service = InactivityService(
    timeout: const Duration(minutes: 5),
    onTimeout: () {}, // overwritten by InactivityScope
  );
  ref.onDispose(service.dispose);
  return service;
});
