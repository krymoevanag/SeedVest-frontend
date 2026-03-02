import 'package:flutter/material.dart';
import '../../core/services/inactivity_service.dart';

/// Wraps authenticated UI and resets the [InactivityService] timer on
/// any pointer event (tap, scroll, drag, hover).
class InactivityDetector extends StatelessWidget {
  final Widget child;
  const InactivityDetector({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => InactivityService.instance.resetTimer(),
      onPointerMove: (_) => InactivityService.instance.resetTimer(),
      onPointerUp: (_) => InactivityService.instance.resetTimer(),
      child: child,
    );
  }
}
