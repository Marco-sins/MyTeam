/// Escucha cambios en tablas relacionadas con un partido (espectador externo).
/// Implementación en capa data (Supabase Realtime).
abstract class IMatchSpectatorRealtime {
  /// Suscripción a cambios en [match_events], [match_lineup] y [matches] del partido.
  void subscribeToMatch(int matchId, void Function() onTablesChanged);

  Future<void> unsubscribe();
}
