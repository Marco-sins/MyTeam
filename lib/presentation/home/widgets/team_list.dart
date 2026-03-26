import 'package:flutter/material.dart';
import 'package:tfg1/presentation/home/widgets/team_card.dart';

class TeamList extends StatelessWidget {
  final List<dynamic> teams; // Idealmente usa tu Entity: List<Team>
  const TeamList({super.key, required this.teams});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: teams.length,
      itemBuilder: (context, index) => TeamCard(team: teams[index]),
    );
  }
}
