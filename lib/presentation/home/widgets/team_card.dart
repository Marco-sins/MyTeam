import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg1/data/datasource/player_remote_datasource.dart';
import 'package:tfg1/data/repositories/player_repository.dart';
import 'package:tfg1/domain/entities/team.dart';
import 'package:tfg1/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:tfg1/presentation/team/bloc/team_detail_cubit.dart';
import 'package:tfg1/presentation/team/pages/team_detail_page.dart';

class TeamCard extends StatelessWidget {
  final Team team;

  const TeamCard({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE8F5E9),
          child: Icon(Icons.group, color: Colors.green),
        ),
        title: Text(
          team.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(team.category),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          final supabase = Supabase.instance.client;
          final playerRepository = PlayerRepository(
            PlayerRemoteDatasource(supabase),
          );
          final getPlayersByTeamUseCase = GetPlayersByTeamUseCase(
            playerRepository,
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) =>
                    TeamDetailCubit(getPlayersByTeamUseCase)..loadTeam(team.id),
                child: TeamDetailPage(team: team),
              ),
            ),
          );
        },
      ),
    );
  }
}
