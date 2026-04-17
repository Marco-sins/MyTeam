import 'package:flutter/material.dart';
import 'package:football_manager/core/theme/team_brand_theme.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/presentation/team/widgets/team_quick_nav_bubble.dart';
import 'package:football_manager/presentation/team/widgets/team_roster_widget.dart';

class TeamRosterPage extends StatelessWidget {
  final Team team;

  const TeamRosterPage({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    return TeamBrandedScope(
      team: team,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Plantilla'),
          centerTitle: true,
          actions: const [TeamQuickNavAppBarButton()],
        ),
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TeamRosterWidget(team: team),
          ),
        ),
      ),
    );
  }
}
