import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/presentation/common/widgets/player_name_text.dart';
import 'package:football_manager/presentation/convocation/cubit/convocation_cubit.dart';
import 'package:football_manager/presentation/convocation/cubit/convocation_state.dart';
import 'package:football_manager/l10n/app_localizations.dart';

class ConvocationPlayersSection extends StatelessWidget {
  final List<Player> players;

  const ConvocationPlayersSection({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

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
                      l10n.convocationEmptyRoster,
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
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const minW = 320.0;
                    final targetW = math.max(constraints.maxWidth, minW);
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: targetW,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search,
                              size: 22,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.matchSquadTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                minimumSize: const Size(0, 32),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                iconSize: 16,
                                textStyle:
                                    theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  letterSpacing: 0.15,
                                ),
                              ),
                              onPressed: () => context
                                  .read<ConvocationCubit>()
                                  .callUpAll(sortedPlayers.map((p) => p.id)),
                              icon: Icon(
                                Icons.done_all_rounded,
                                size: 16,
                                color: scheme.primary,
                              ),
                              label: Text(l10n.convocationCallAll),
                            ),
                            const SizedBox(width: 4),
                            Chip(
                              label: Text(
                                '$calledCount / ${sortedPlayers.length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              backgroundColor: scheme.secondaryContainer
                                  .withValues(alpha: 0.65),
                              side: BorderSide.none,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: scheme.surfaceContainerHigh.withValues(alpha: 0.45),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const minW = 260.0;
                    final targetW = math.max(constraints.maxWidth, minW);
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: targetW,
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
                                l10n.tableColumnPlayer,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                l10n.convocationPlayerStatus,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const minW = 280.0;
                        final targetW = math.max(
                          constraints.maxWidth,
                          minW,
                        );
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: targetW,
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
                                      isCalled
                                          ? l10n.commonYes
                                          : l10n.commonNo,
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
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: Text(
                  l10n.convocationToggleHint,
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
