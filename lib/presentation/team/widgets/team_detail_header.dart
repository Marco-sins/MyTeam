import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tfg1/domain/entities/team.dart';
import 'package:tfg1/presentation/team/bloc/team_detail_cubit.dart';
import 'package:tfg1/presentation/team/bloc/team_detail_state.dart';

class TeamDetailHeader extends StatelessWidget {
  final Team team;

  const TeamDetailHeader({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            backgroundImage:
                team.logoUrl != null &&
                    (team.logoUrl!.startsWith('http://') ||
                        team.logoUrl!.startsWith('https://'))
                ? NetworkImage(team.logoUrl!)
                : null,
            child:
                team.logoUrl == null ||
                    !(team.logoUrl!.startsWith('http://') ||
                        team.logoUrl!.startsWith('https://'))
                ? const Icon(Icons.shield, color: Color(0xFF1B5E20))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        team.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        team.category,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    BlocBuilder<TeamDetailCubit, TeamDetailState>(
                      builder: (context, state) {
                        int count = 0;
                        if (state is TeamDetailLoaded) {
                          count = state.players.length;
                        }
                        return Text(
                          count > 0 ? '$count jugadores' : '0 jugadores',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
