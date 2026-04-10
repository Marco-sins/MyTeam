import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:football_manager/presentation/auth/bloc/auth_cubit.dart';
import 'package:football_manager/presentation/auth/bloc/auth_state.dart';
import 'package:football_manager/presentation/team/bloc/team_detail_cubit.dart';
import 'package:football_manager/presentation/team/pages/team_detail_page.dart';

class TeamCard extends StatelessWidget {
  final Team team;

  const TeamCard({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final getPlayersByTeamUseCase = context.read<GetPlayersByTeamUseCase>();
    final authState = context.read<AuthCubit>().state;
    String? roleLabel;
    if (authState is Authenticated) {
      final role = authState.user.teamRoles[team.id];
      if (role != null) {
        roleLabel = _roleLabel(role);
      }
    }

    const smallTextStyle = TextStyle(fontSize: 12, color: Colors.grey);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
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
        child: Stack(
          children: [
            if (roleLabel != null)
              Positioned(
                top: 8,
                right: 8,
                child: Text(roleLabel, style: smallTextStyle),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                              ),
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.transparent,
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
                                  ? const Icon(
                                      Icons.shield,
                                      color: Colors.white,
                                      size: 38,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            team.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          team.category,
                          style: smallTextStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Flexible(
                        child: FutureBuilder<int>(
                          future: _loadPlayersCount(getPlayersByTeamUseCase),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Text(
                                '...',
                                style: smallTextStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              );
                            }
                            final count = snapshot.data ?? 0;
                            return Text(
                              '$count jugadores',
                              style: smallTextStyle.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.player:
        return 'Jugador';
      case UserRole.external:
        return 'Externo';
    }
  }

  Future<int> _loadPlayersCount(
    GetPlayersByTeamUseCase getPlayersByTeamUseCase,
  ) async {
    final result = await getPlayersByTeamUseCase(team.id);
    return result.fold((failure) => 0, (players) => players.length);
  }
}
