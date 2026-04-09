import 'package:flutter/material.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/presentation/attendance/widgets/attendance_summary_table.dart';

class TeamAttendanceSection extends StatelessWidget {
  final Team team;
  final List<Player> players;

  const TeamAttendanceSection({
    super.key,
    required this.team,
    required this.players,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.symmetric(vertical: 8.0)),
          Expanded(
            child: AttendanceSummaryTable(team: team, players: players),
          ),
        ],
      ),
    );
  }
}
