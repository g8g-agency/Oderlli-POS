import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/inactivity_provider.dart';

class InactivityRouteObserver extends NavigatorObserver {
  final Ref ref;

  InactivityRouteObserver(this.ref);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    ref.read(inactivityServiceProvider).resetTimer();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    ref.read(inactivityServiceProvider).resetTimer();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    ref.read(inactivityServiceProvider).resetTimer();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    ref.read(inactivityServiceProvider).resetTimer();
  }
}
