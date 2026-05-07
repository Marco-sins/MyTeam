import 'package:football_manager/domain/entities/enum/match_status.dart';
import 'package:football_manager/domain/entities/match_lineup.dart';

/// Entidad `Match` con metadatos del partido, marcador, fecha y alineaciones.
class Match {
  final int id;
  final int teamId;
  final String opponent;
  final int goalsScored;
  final int goalsConceded;
  final DateTime date;
  final String hour;
  final MatchStatus status;
  final List<MatchLineup> lineups;
  final bool isHome;

  const Match({
    required this.id,
    required this.teamId,
    required this.opponent,
    required this.goalsScored,
    required this.goalsConceded,
    required this.date,
    required this.hour,
    required this.status,
    required this.lineups,
    required this.isHome,
  });
}
