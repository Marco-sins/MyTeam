import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/presentation/common/widgets/player_name_text.dart';
import 'package:football_manager/presentation/convocation/cubit/convocation_cubit.dart';
import 'package:football_manager/presentation/convocation/cubit/convocation_state.dart';

class ConvocationPlayersSection extends StatelessWidget {
  final List<Player> players;

  const ConvocationPlayersSection({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return BlocBuilder<ConvocationCubit, ConvocationState>(
      builder: (context, state) {
        if (players.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No hay jugadores en la plantilla',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final sortedPlayers = List<Player>.from(players)
          ..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));

        final calledCount = context.read<ConvocationCubit>().calledCountFor(
              sortedPlayers.map((p) => p.id),
            );

        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.person_search, size: 22, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Convocados',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(
                        '$calledCount / ${sortedPlayers.length}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      backgroundColor:
                          scheme.secondaryContainer.withValues(alpha: 0.65),
                      side: BorderSide.none,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: scheme.surfaceContainerHigh.withValues(alpha: 0.45),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        '#',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Jugador',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      'Estado',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedPlayers.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),
                itemBuilder: (context, index) {
                  final player = sortedPlayers[index];
                  final isCalled = state.calledUp[player.id] ?? false;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text(
                            player.number?.toString() ?? '–',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: PlayerNameText(
                            player: player,
                            style: theme.textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => context
                              .read<ConvocationCubit>()
                              .toggleCalledUp(player.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isCalled
                                  ? scheme.primary
                                  : scheme.error,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              isCalled ? 'Sí' : 'No',
                              style: TextStyle(
                                color: isCalled
                                    ? scheme.onPrimary
                                    : scheme.onError,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: Text(
                  'Toca el botón de cada jugador para alternar entre Sí y No.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
