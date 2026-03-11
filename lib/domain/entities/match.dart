import 'package:tfg1/domain/entities/enum/match_status.dart';
import 'package:tfg1/domain/entities/match_lineup.dart';

class Match {
  final int id;
  final int teamId;
  final String opponent;
  final int goalsScored;
  final int goalsConceded;
  final DateTime date;
  final MatchStatus status;
  final List<MatchLineup> lineups;  

  const Match({
    required this.id,
    required this.teamId,
    required this.opponent,
    required this.goalsScored,
    required this.goalsConceded,
    required this.date,
    required this.status, 
    required this.lineups,
  });
}