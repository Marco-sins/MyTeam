import 'dart:async';

import 'package:flutter/material.dart';
import 'package:football_manager/core/notifications/match_event_app_notification_coordinator.dart';

/// Al volver al primer plano, reabre el canal Realtime (mejor entrega con la
/// app minimizada; el SO puede cortar el WebSocket mientras no hay foco).
class MatchNotifAppLifecycle extends StatefulWidget {
  const MatchNotifAppLifecycle({super.key, required this.child});

  final Widget child;

  @override
  State<MatchNotifAppLifecycle> createState() => _MatchNotifAppLifecycleState();
}

class _MatchNotifAppLifecycleState extends State<MatchNotifAppLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(
        MatchEventAppNotificationCoordinator.instance.resubscribeIfActive(),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
