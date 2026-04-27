/// Fila insertada/actualizada en [match_events] (Realtime), sin acoplar a Supabase.
class MatchEventRealtimeSnapshot {
  const MatchEventRealtimeSnapshot({
    required this.isInsert,
    required this.row,
  });

  final bool isInsert;
  final Map<String, dynamic> row;
}
