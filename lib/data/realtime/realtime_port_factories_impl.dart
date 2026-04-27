import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/data/realtime/home_panel_realtime.dart';
import 'package:football_manager/data/realtime/invitation_inbox_realtime.dart';
import 'package:football_manager/data/realtime/team_access_members_realtime.dart';
import 'package:football_manager/domain/factories/realtime_port_factories.dart';
import 'package:football_manager/domain/repositories/i_home_panel_realtime.dart';
import 'package:football_manager/domain/repositories/i_invitation_inbox_realtime.dart';
import 'package:football_manager/domain/repositories/i_team_access_members_realtime.dart';

class HomePanelRealtimeFactoryImpl implements IHomePanelRealtimeFactory {
  HomePanelRealtimeFactoryImpl(this._client);

  final SupabaseClient _client;

  @override
  IHomePanelRealtime create() => HomePanelRealtime(_client);
}

class InvitationInboxRealtimeFactoryImpl implements IInvitationInboxRealtimeFactory {
  InvitationInboxRealtimeFactoryImpl(this._client);

  final SupabaseClient _client;

  @override
  IInvitationInboxRealtime create() => InvitationInboxRealtime(_client);
}

class TeamAccessMembersRealtimeFactoryImpl
    implements ITeamAccessMembersRealtimeFactory {
  TeamAccessMembersRealtimeFactoryImpl(this._client);

  final SupabaseClient _client;

  @override
  ITeamAccessMembersRealtime create() => TeamAccessMembersRealtime(_client);
}
