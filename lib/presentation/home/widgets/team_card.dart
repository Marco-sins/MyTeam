import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_cubit.dart';
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

    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final metaStyle = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );

    final hasNetworkLogo = team.logoUrl != null &&
        (team.logoUrl!.startsWith('http://') ||
            team.logoUrl!.startsWith('https://'));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (roleLabel != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: Chip(
                    label: Text(
                      roleLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor:
                        scheme.secondaryContainer.withValues(alpha: 0.75),
                    side: BorderSide.none,
                  ),
                ),
              if (roleLabel != null) const SizedBox(height: 4),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.75),
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: hasNetworkLogo
                            ? Image.network(
                                team.logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return ColoredBox(
                                    color: scheme.surfaceContainerLow,
                                    child: Icon(
                                      Icons.shield_outlined,
                                      color: scheme.primary,
                                      size: 34,
                                    ),
                                  );
                                },
                              )
                            : ColoredBox(
                                color: scheme.surfaceContainerLow,
                                child: Icon(
                                  Icons.shield_outlined,
                                  color: scheme.primary,
                                  size: 34,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      team.name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Chip(
                      label: Text(
                        team.category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor:
                          scheme.primaryContainer.withValues(alpha: 0.55),
                      side: BorderSide.none,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: FutureBuilder<int>(
                      future: _loadPlayersCount(getPlayersByTeamUseCase),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Text(
                            '…',
                            style: metaStyle,
                            textAlign: TextAlign.right,
                          );
                        }
                        final count = snapshot.data ?? 0;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.groups_outlined,
                              size: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '$count',
                                style: metaStyle?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: scheme.outline,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Superadmin';
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
