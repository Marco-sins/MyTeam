/// Suscripción a `team_members` de un mismo equipo.
abstract class ITeamAccessMembersRealtime {
  void start({
    required int teamId,
    required String currentUserId,
    required void Function() onMembersMayHaveChanged,
  });

  void stop();
}
