/// Suscripción a cambios en `invitation` filtrada por el correo del buzón.
abstract class IInvitationInboxRealtime {
  void start({
    required String userId,
    required String normalizedInboxEmail,
    required void Function() onInboxMayHaveChanged,
  });

  void stop();
}
