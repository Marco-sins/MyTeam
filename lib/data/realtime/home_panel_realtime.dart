import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/domain/repositories/i_home_panel_realtime.dart';

class HomePanelRealtime implements IHomePanelRealtime {
  HomePanelRealtime(this._client);

  final SupabaseClient _client;
  RealtimeChannel? _teamMembersChannel;
  RealtimeChannel? _invitationsChannel;

  @override
  void start({
    required String userId,
    required String normalizedInboxEmail,
    required void Function() onUserRemovedFromATeam,
    required void Function() onInvitationInboxChanged,
  }) {
    stop();

    _teamMembersChannel = _client
        .channel('team_members_panel_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'team_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id_user',
            value: userId,
          ),
          callback: (_) => onUserRemovedFromATeam(),
        )
        .subscribe();

    if (normalizedInboxEmail.isEmpty) return;

    final channelId =
        'inv_inbox_${normalizedInboxEmail.hashCode}_${userId.hashCode}';

    _invitationsChannel = _client
        .channel(channelId)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'invitation',
          callback: (payload) {
            String? rowEmail;
            switch (payload.eventType) {
              case PostgresChangeEvent.insert:
                rowEmail = payload.newRecord['email']?.toString();
                break;
              case PostgresChangeEvent.update:
                rowEmail = payload.newRecord['email']?.toString() ??
                    payload.oldRecord['email']?.toString();
                break;
              case PostgresChangeEvent.delete:
                rowEmail = payload.oldRecord['email']?.toString();
                break;
              case PostgresChangeEvent.all:
                return;
            }
            if (rowEmail == null) return;
            if (rowEmail.trim().toLowerCase() != normalizedInboxEmail) {
              return;
            }
            onInvitationInboxChanged();
          },
        )
        .subscribe();
  }

  @override
  void stop() {
    final chTeam = _teamMembersChannel;
    _teamMembersChannel = null;
    if (chTeam != null) {
      unawaited(_client.removeChannel(chTeam));
    }
    final chInv = _invitationsChannel;
    _invitationsChannel = null;
    if (chInv != null) {
      unawaited(_client.removeChannel(chInv));
    }
  }
}
