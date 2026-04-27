import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/domain/entities/match_event_realtime_snapshot.dart';
import 'package:football_manager/domain/repositories/i_match_spectator_realtime.dart';

/// Supabase Realtime: escucha inserciones/actualizaciones en eventos, alineación y partido.
class MatchSpectatorRealtimeService implements IMatchSpectatorRealtime {
  MatchSpectatorRealtimeService(this._client);

  final SupabaseClient _client;
  RealtimeChannel? _channel;

  @override
  void subscribeToMatch(
    int matchId,
    void Function() onTablesChanged, {
    void Function(MatchEventRealtimeSnapshot snapshot)? onMatchEventChange,
  }) {
    final previous = _channel;
    _channel = null;
    if (previous != null) {
      unawaited(_client.removeChannel(previous));
    }

    _channel = _client
        .channel('match_spectator_$matchId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'match_events',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'match_id',
            value: matchId,
          ),
          callback: (PostgresChangePayload payload) {
            onMatchEventChange?.call(
              MatchEventRealtimeSnapshot(
                isInsert: payload.eventType == PostgresChangeEvent.insert,
                row: Map<String, dynamic>.from(payload.newRecord),
              ),
            );
            onTablesChanged();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'match_lineup',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'match_id',
            value: matchId,
          ),
          callback: (_) => onTablesChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'matches',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: matchId,
          ),
          callback: (_) => onTablesChanged(),
        )
        .subscribe();
  }

  @override
  Future<void> unsubscribe() async {
    final ch = _channel;
    _channel = null;
    if (ch != null) {
      await _client.removeChannel(ch);
    }
  }
}
