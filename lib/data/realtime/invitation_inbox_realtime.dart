import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/domain/repositories/i_invitation_inbox_realtime.dart';

class InvitationInboxRealtime implements IInvitationInboxRealtime {
  InvitationInboxRealtime(this._client);

  final SupabaseClient _client;
  RealtimeChannel? _channel;

  @override
  void start({
    required String userId,
    required String normalizedInboxEmail,
    required void Function() onInboxMayHaveChanged,
  }) {
    stop();
    if (normalizedInboxEmail.isEmpty) return;

    _channel = _client
        .channel(
          'inv_list_${normalizedInboxEmail.hashCode}_${userId.hashCode}',
        )
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
            onInboxMayHaveChanged();
          },
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
