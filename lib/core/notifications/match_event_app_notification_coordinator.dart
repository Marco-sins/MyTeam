import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:football_manager/core/di/injection_container.dart';
import 'package:football_manager/core/notifications/match_notif_l10n.dart';
import 'package:football_manager/core/notifications/match_realtime_local_notifications.dart';
import 'package:football_manager/domain/entities/match_event_realtime_snapshot.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/usecase/match/get_match_by_id_use_case.dart';
import 'package:football_manager/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:football_manager/domain/usecase/team/get_team_by_id_use_case.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Realtime `INSERT` en [match_events] para toda la app (misma sesión).
/// Depende de RLS: solo verás filas de partidos a los que tu usuario tiene acceso.
class MatchEventAppNotificationCoordinator {
  MatchEventAppNotificationCoordinator._();
  static final MatchEventAppNotificationCoordinator instance =
      MatchEventAppNotificationCoordinator._();

  RealtimeChannel? _channel;
  bool _starting = false;
  /// True mientras haya que escuchar (sesión; [stop] del logout lo pone a false).
  bool _wantsAppWideNotifs = false;

  /// Idem [handleMatchEventRealtimeForLocalNotification] pero asume [map] ya listo.
  Future<void> _dispatchFromRow(Map<String, dynamic> map) async {
    if (kIsWeb) return;
    if (!MatchRealtimeLocalNotifications.instance.isReady) return;

    // Sin depender de un [BuildContext] “montado”: minimizado, el árbol puede
    // no considerarse montado y antes se descartaba el aviso.
    final l10n = matchNotificationLocalizations();

    final matchId = map['match_id'];
    final mid = matchId is int
        ? matchId
        : (matchId is num ? matchId.toInt() : int.tryParse('$matchId'));
    if (mid == null) return;

    final getMatch = sl<GetMatchByIdUseCase>();
    final getTeam = sl<GetTeamByIdUseCase>();
    final getPlayers = sl<GetPlayersByTeamUseCase>();

    final matchEither = await getMatch(mid);
    final match = matchEither.fold((_) => null, (m) => m);
    if (match == null) return;

    final teamEither = await getTeam(match.teamId);
    final team = teamEither.fold((_) => null, (t) => t);
    if (team == null) return;

    final ourTeamName = team.name;
    final opponentName = match.opponent;

    final playersEither = await getPlayers(match.teamId);
    final players = playersEither.fold((_) => <Player>[], (p) => p);

    String playerNameFor(int? id) {
      if (id == null) return l10n.matchNotifPlayerUnknown;
      for (final p in players) {
        if (p.id == id) return p.fullName;
      }
      return l10n.matchNotifPlayerUnknown;
    }

    final snap = MatchEventRealtimeSnapshot(isInsert: true, row: map);
    handleMatchEventRealtimeForLocalNotification(
      snap,
      l10n: l10n,
      ourTeamName: ourTeamName,
      opponentName: opponentName,
      playerNameFor: playerNameFor,
    );
  }

  void _onPayload(PostgresChangePayload payload) {
    if (payload.eventType != PostgresChangeEvent.insert) return;
    unawaited(_dispatchFromRow(Map<String, dynamic>.from(payload.newRecord)));
  }

  Future<void> _bindChannel() async {
    final ch = Supabase.instance.client
        .channel('match_events_app_wide_notif')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'match_events',
          callback: _onPayload,
        );
    _channel = ch;
    ch.subscribe();
  }

  Future<void> _unbindChannel() async {
    final ch = _channel;
    _channel = null;
    if (ch == null) return;
    try {
      await Supabase.instance.client.removeChannel(ch);
    } catch (e) {
      debugPrint('MatchEventAppNotif: removeChannel: $e');
    }
  }

  Future<void> start() async {
    if (kIsWeb) return;
    if (_channel != null || _starting) return;
    _starting = true;
    try {
      await MatchRealtimeLocalNotifications.instance.ensureInitialized();
      await _bindChannel();
      _wantsAppWideNotifs = true;
    } finally {
      _starting = false;
    }
  }

  /// Vuelve a abrir el canal Realtime (el socket suele caerse con la app
  /// minimizada / en caché). Llamar al pasar a [AppLifecycleState.resumed].
  Future<void> resubscribeIfActive() async {
    if (kIsWeb) return;
    if (!_wantsAppWideNotifs) return;
    if (Supabase.instance.client.auth.currentUser == null) {
      await stop();
      return;
    }
    if (_starting) return;
    _starting = true;
    try {
      await _unbindChannel();
      await MatchRealtimeLocalNotifications.instance.ensureInitialized();
      await _bindChannel();
    } finally {
      _starting = false;
    }
  }

  Future<void> stop() async {
    _wantsAppWideNotifs = false;
    await _unbindChannel();
  }
}
