import 'package:flutter/material.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/presentation/team/widgets/team_roster_widget.dart';

class TeamRosterPage extends StatelessWidget {
  final Team team;

  const TeamRosterPage({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plantilla'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TeamRosterWidget(team: team),
      ),
    );
  }
}
