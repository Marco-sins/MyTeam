import 'package:football_manager/domain/entities/match_event_realtime_snapshot.dart';

/// Escucha cambios en tablas relacionadas con un partido (espectador externo).
/// Implementación en capa data (Supabase Realtime).
/// Suscripción a cambios de partido vía Realtime (goles, eventos, alineación, fila [matches]).
abstract class IMatchSpectatorRealtime {
  /// Suscripción a cambios en [match_events], [match_lineup] y [matches] del partido.
  /// [onMatchEventChange] solo refleja filas de [match_events] (p. ej. notificaciones locales).
  void subscribeToMatch(
    int matchId,
    void Function() onTablesChanged, {
    void Function(MatchEventRealtimeSnapshot snapshot)? onMatchEventChange,
  });

  Future<void> unsubscribe();
}
