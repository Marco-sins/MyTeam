/// Suscripciones Realtime del panel inicio: pertenencia a equipos e invitaciones.
abstract class IHomePanelRealtime {
  void start({
    required String userId,
    required String normalizedInboxEmail,
    required void Function() onUserRemovedFromATeam,
    required void Function() onInvitationInboxChanged,
  });

  void stop();
}
