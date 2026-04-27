import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/domain/repositories/i_team_access_members_realtime.dart';

class TeamAccessMembersRealtime implements ITeamAccessMembersRealtime {
  TeamAccessMembersRealtime(this._client);

  final SupabaseClient _client;
  RealtimeChannel? _channel;

  @override
  void start({
    required int teamId,
    required String currentUserId,
    required void Function() onMembersMayHaveChanged,
  }) {
    stop();
    _channel = _client
        .channel('team_access_${teamId}_$currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'team_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id_team',
            value: teamId,
          ),
          callback: (_) => onMembersMayHaveChanged(),
        )
        .subscribe();
  }

  @override
  void stop() {
    final ch = _channel;
    _channel = null;
    if (ch != null) {
      unawaited(_client.removeChannel(ch));
    }
  }
}
