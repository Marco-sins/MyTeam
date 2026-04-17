import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:football_manager/presentation/team/cubit/team_context_cubit.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_cubit.dart';
import 'package:football_manager/presentation/team/pages/team_detail_page.dart';

/// Navegación al detalle del equipo reutilizando el mismo [TeamContextCubit].
abstract final class TeamSessionRoutes {
  static MaterialPageRoute<void> detailHomeReplacingStack(
    BuildContext context,
  ) {
    final teamContext = context.read<TeamContextCubit>();
    final getPlayers = context.read<GetPlayersByTeamUseCase>();
    final teamId = teamContext.state.id;
    return MaterialPageRoute<void>(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: teamContext),
          BlocProvider(
            create: (_) => TeamDetailCubit(getPlayers)..loadTeam(teamId),
          ),
        ],
        child: const TeamDetailPage(),
      ),
    );
  }
}
