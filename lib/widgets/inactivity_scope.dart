import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/inactivity_service.dart';
import '../providers/providers.dart';
import '../providers/inactivity_provider.dart';
import '../routes/app_router.dart';
import '../routes/app_routes.dart';

class InactivityScope extends ConsumerStatefulWidget {
  const InactivityScope({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<InactivityScope> createState() => _InactivityScopeState();
}

class _InactivityScopeState extends ConsumerState<InactivityScope>
    with WidgetsBindingObserver {
  late final InactivityService _service;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _service = ref.read(inactivityServiceProvider);
    
    // Set up the scope-specific timeout handler
    _service.onTimeout = _handleTimeout;
    
    // Read the initial timeout
    final initialMinutes = ref.read(posSettingsProvider).inactivityTimeout;
    _service.updateTimeout(Duration(minutes: initialMinutes));
    
    _service.start();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      _service.resetTimer();
    }
    return false; // Do not consume the event, let it propagate normally.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    // InactivityScope no longer disposes the service; the Provider does.
    // We just remove the callback.
    _service.onTimeout = null;
    super.dispose();
  }

  /// Pause timer when app goes to background;
  /// resume when it returns to foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _service.pause();
    } else if (state == AppLifecycleState.resumed) {
      _service.resetTimer();
    }
  }

  void _handleTimeout() {
    final authState = ref.read(authProvider);
    if (authState.user == null || authState.isLocked) return;

    ref.read(authProvider.notifier).lock();

    ref.read(cartSelectedTableProvider.notifier).state = null;
    ref.read(posCartProvider.notifier).clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(routerProvider).go(AppRoutes.employeeLogin);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final inactivityMinutes = ref.watch(posSettingsProvider.select((s) => s.inactivityTimeout));
    _service.updateTimeout(Duration(minutes: inactivityMinutes));

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _service.resetTimer(),
      onPointerMove: (_) => _service.resetTimer(),
      onPointerSignal: (_) => _service.resetTimer(),
      child: widget.child,
    );
  }
}
