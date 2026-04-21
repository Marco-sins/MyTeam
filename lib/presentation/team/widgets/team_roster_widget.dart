import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/usecase/player/add_new_player_use_case.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/presentation/player/pages/add_player_page.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_cubit.dart';
import 'package:football_manager/presentation/team/pages/import_player_from_other_team_page.dart';
import 'package:football_manager/presentation/common/widgets/player_name_text.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_state.dart';
import 'package:football_manager/presentation/team/widgets/team_players_list.dart';

class TeamRosterWidget extends StatelessWidget {
  final Team team;

  const TeamRosterWidget({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final authState = context.read<AuthCubit>().state;
    bool isExternal = false;
    if (authState is Authenticated) {
      isExternal =
          authState.user.teamRoles[team.id] == UserRole.external;
    }

    final Widget playersWidget = isExternal
        ? _ExternalPlayersTable(team: team)
        : TeamPlayersList(team: team);

    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;
        const kGapIdeal = 12.0;
        const kBtnIdeal = 52.0;
        const kBetweenButtons = 6.0;
        var bottomGap = kGapIdeal;
        /// Alto de cada botón (alta + importar); dos filas.
        var rowH = kBtnIdeal;
        if (!isExternal) {
          final idealFooter = kGapIdeal + kBtnIdeal * 2 + kBetweenButtons;
          if (maxH < idealFooter) {
            final scale = maxH / idealFooter;
            bottomGap = (kGapIdeal * scale).clamp(4.0, kGapIdeal);
            rowH = (kBtnIdeal * scale).clamp(28.0, kBtnIdeal);
            if (bottomGap + rowH * 2 + kBetweenButtons > maxH) {
              rowH = math.max(
                24,
                (maxH - bottomGap - kBetweenButtons) / 2,
              );
            }
          }
        }
        final reservedBottom =
            isExternal ? 0.0 : (bottomGap + rowH * 2 + kBetweenButtons);
        final remaining = maxH - reservedBottom;
        final titleH = remaining <= 0
            ? 0.0
            : ((remaining * 0.32).clamp(12.0, 44.0)).clamp(0.0, remaining);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (titleH > 0)
              SizedBox(
                height: titleH,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        l10n.screenRoster,
                        style: titleStyle,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: playersWidget,
              ),
            ),
            if (!isExternal && rowH > 0) ...[
              SizedBox(height: bottomGap),
              SizedBox(
                width: double.infinity,
                height: rowH * 2 + kBetweenButtons,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: rowH,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final authState = context.read<AuthCubit>().state;
                          if (authState is! Authenticated) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.teamMustLoginAddPlayers),
                                backgroundColor: scheme.error,
                              ),
                            );
                            return;
                          }

                          final addNewPlayerUseCase =
                              context.read<AddNewPlayerUseCase>();

                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddPlayerPage(
                                team: team,
                                currentUser: authState.user,
                                addNewPlayerUseCase: addNewPlayerUseCase,
                              ),
                            ),
                          );

                          if (!context.mounted) return;
                          context.read<TeamDetailCubit>().loadTeam(team.id);
                        },
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: Text(l10n.screenAddPlayer),
                        style: FilledButton.styleFrom(
                          minimumSize: Size.fromHeight(rowH),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: rowH < 36 ? 4 : 10,
                          ),
                          visualDensity: rowH < 36
                              ? VisualDensity.compact
                              : VisualDensity.standard,
                        ),
                      ),
                    ),
                    SizedBox(height: kBetweenButtons),
                    SizedBox(
                      width: double.infinity,
                      height: rowH,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final authState = context.read<AuthCubit>().state;
                          if (authState is! Authenticated) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.teamMustLoginAddPlayers),
                                backgroundColor: scheme.error,
                              ),
                            );
                            return;
                          }
                          final changed = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ImportPlayerFromOtherTeamPage(
                                targetTeam: team,
                              ),
                            ),
                          );
                          if (!context.mounted) return;
                          if (changed == true) {
                            context.read<TeamDetailCubit>().loadTeam(team.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.teamImportPlayerSuccess),
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.drive_folder_upload_outlined),
                        label: Text(l10n.teamImportPlayerButton),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size.fromHeight(rowH),
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: rowH < 36 ? 4 : 10,
                          ),
                          visualDensity: rowH < 36
                              ? VisualDensity.compact
                              : VisualDensity.standard,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ExternalPlayersTable extends StatelessWidget {
  final Team team;

  const _ExternalPlayersTable({required this.team});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<TeamDetailCubit, TeamDetailState>(
      builder: (context, state) {
        if (state is TeamDetailLoading || state is TeamDetailInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is TeamDetailError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                state.message,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.error),
              ),
            ),
          );
        }
        if (state is TeamDetailLoaded) {
          if (state.players.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.group_off_outlined,
                      size: 48,
                      color: scheme.outline.withValues(alpha: 0.65),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.convocationEmptyRoster,
                      style: Theme.of(context).textTheme.titleSmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final players = List.of(state.players)
            ..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: players.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
            itemBuilder: (context, index) {
              final player = players[index];
              final theme = Theme.of(context);
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: SizedBox(
                  width: 40,
                  child: Center(
                    child: Text(
                      player.number?.toString() ?? '—',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                title: PlayerNameText(
                  player: player,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
