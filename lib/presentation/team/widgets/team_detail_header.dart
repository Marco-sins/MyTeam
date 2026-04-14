import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_cubit.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_state.dart';

class TeamDetailHeader extends StatelessWidget {
  final Team team;
  final VoidCallback? onLeaveTeam;

  const TeamDetailHeader({
    super.key,
    required this.team,
    this.onLeaveTeam,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasRemoteLogo = team.logoUrl != null &&
        (team.logoUrl!.startsWith('http://') ||
            team.logoUrl!.startsWith('https://'));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasRemoteLogo
                  ? Image.network(
                      team.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(
                          Icons.shield_outlined,
                          color: scheme.primary,
                          size: 36,
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.shield_outlined,
                        color: scheme.primary,
                        size: 36,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          team.name,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: scheme.onSurface,
                            height: 1.15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (onLeaveTeam != null)
                        TextButton.icon(
                          onPressed: onLeaveTeam,
                          icon: Icon(
                            Icons.logout_rounded,
                            size: 20,
                            color: scheme.error,
                          ),
                          label: Text(
                            'Salir',
                            style: TextStyle(
                              color: scheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.only(left: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Chip(
                        avatar: Icon(
                          Icons.category_outlined,
                          size: 18,
                          color: scheme.onSecondaryContainer,
                        ),
                        label: Text(
                          team.category,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        backgroundColor:
                            scheme.secondaryContainer.withValues(alpha: 0.65),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      BlocBuilder<TeamDetailCubit, TeamDetailState>(
                        builder: (context, state) {
                          int count = 0;
                          if (state is TeamDetailLoaded) {
                            count = state.players.length;
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer
                                  .withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.groups_outlined,
                                  size: 16,
                                  color: scheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  count == 1
                                      ? '1 jugador'
                                      : '$count jugadores',
                                  style: textTheme.labelLarge?.copyWith(
                                    color: scheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
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
      ),
    );
  }
}
