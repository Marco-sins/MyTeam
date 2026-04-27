import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/usecase/player/delete_player_use_case.dart';
import 'package:football_manager/domain/usecase/player/update_player_use_case.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/presentation/player/pages/edit_player_page.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_cubit.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_state.dart';
import 'package:football_manager/presentation/common/widgets/player_name_text.dart';
import 'package:football_manager/presentation/player/widgets/player_avatar.dart';
import 'package:football_manager/presentation/player/widgets/player_detail_dialog.dart';

class TeamPlayersList extends StatelessWidget {
  final Team team;

  const TeamPlayersList({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<TeamDetailCubit, TeamDetailState>(
      builder: (context, state) {
        if (state is TeamDetailLoading || state is TeamDetailInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is TeamDetailError) {
          return Center(child: Text(state.message));
        }
        if (state is TeamDetailLoaded) {
          if (state.players.isEmpty) {
            return Center(
              child: Text(l10n.convocationEmptyRoster),
            );
          }
          final players = List.of(state.players)
            ..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));
          return ListView.separated(
            itemCount: players.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final player = players[index];
              return ListTile(
                leading: PlayerAvatar(player: player, radius: 22),
                title: PlayerDorsalNameText(
                  player: player,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) =>
                        PlayerDetailDialog(team: team, player: player),
                  );
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {
                        final authState = context.read<AuthCubit>().state;
                        if (authState is! Authenticated) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.teamMustLoginEditPlayers),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final updatePlayerUseCase = context
                            .read<UpdatePlayerUseCase>();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditPlayerPage(
                              team: team,
                              player: player,
                              currentUser: authState.user,
                              updatePlayerUseCase: updatePlayerUseCase,
                            ),
                          ),
                        ).then((_) {
                          if (context.mounted) {
                            context.read<TeamDetailCubit>().loadTeam(team.id);
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.red,
                      ),
                      onPressed: () async {
                        final authState = context.read<AuthCubit>().state;
                        if (authState is! Authenticated) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.teamMustLoginDeletePlayers),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) {
                            final dlg = AppLocalizations.of(ctx)!;
                            return AlertDialog(
                              title: Text(dlg.dialogDeletePlayerTitle),
                              content: Text.rich(
                                TextSpan(
                                  style: Theme.of(ctx).textTheme.bodyMedium,
                                  children: [
                                    TextSpan(text: dlg.dialogDeletePlayerLead),
                                    ...playerNameSpanList(
                                      player,
                                      Theme.of(ctx).textTheme.bodyMedium!,
                                    ),
                                    const TextSpan(text: '?'),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: Text(dlg.actionCancel),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: Text(
                                    dlg.actionDelete,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                        if (confirm != true) return;
                        if (!context.mounted) return;

                        final deletePlayerUseCase = context
                            .read<DeletePlayerUseCase>();
                        final result = await deletePlayerUseCase(
                          player,
                          authState.user,
                        );

                        if (!context.mounted) return;
                        result.fold(
                          (failure) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(failure.message),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                          (_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Jugador borrado correctamente'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                            context.read<TeamDetailCubit>().loadTeam(team.id);
                          },
                        );
                      },
                    ),
                  ],
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
