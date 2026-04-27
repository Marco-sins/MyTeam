import 'package:football_manager/domain/repositories/i_home_panel_realtime.dart';
import 'package:football_manager/domain/repositories/i_invitation_inbox_realtime.dart';
import 'package:football_manager/domain/repositories/i_team_access_members_realtime.dart';

/// Composition root crea implementaciones en [data]; la UI solo recibe esta factoría.
abstract class IHomePanelRealtimeFactory {
  IHomePanelRealtime create();
}

abstract class IInvitationInboxRealtimeFactory {
  IInvitationInboxRealtime create();
}

abstract class ITeamAccessMembersRealtimeFactory {
  ITeamAccessMembersRealtime create();
}
