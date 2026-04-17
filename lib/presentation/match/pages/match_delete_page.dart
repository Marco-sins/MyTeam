import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/core/theme/team_brand_theme.dart';
import 'package:football_manager/domain/entities/enum/match_status.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/usecase/match/get_matches_by_team_use_case.dart';
import 'package:football_manager/domain/usecase/match/delete_match_use_case.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/presentation/team/cubit/team_context_cubit.dart';
import 'package:football_manager/presentation/team/widgets/team_area_background.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/presentation/team/widgets/team_quick_nav_bubble.dart';

class MatchDeletePage extends StatefulWidget {
  final Team team;

  const MatchDeletePage({super.key, required this.team});

  @override
  State<MatchDeletePage> createState() => _MatchDeletePageState();
}

class _MatchDeletePageState extends State<MatchDeletePage> {
  late Future<dynamic> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  void _loadMatches() {
    _matchesFuture = context.read<GetMatchesByTeamUseCase>().call(
      widget.team.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final team = context.watch<TeamContextCubit>().state;
    return TeamBrandedScope(
      team: team,
      child: Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.screenDeleteMatch),
        centerTitle: true,
        actions: const [TeamQuickNavAppBarButton()],
      ),
      body: SafeArea(
        top: false,
        child: TeamAreaBackground(
          team: team,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder(
            future: _matchesFuture,
            builder: (context, snapshot) {
              final l10n = AppLocalizations.of(context)!;
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData) {
                return Center(
                  child: Text(l10n.matchListLoadError),
                );
              }

              final either = snapshot.data!;
              return either.fold((failure) => Center(child: Text(failure.message)), (
                matches,
              ) {
                if (matches.isEmpty) {
                  return Center(
                    child: Text(l10n.matchListEmpty),
                  );
                }

                return ListView.builder(
                  itemCount: matches.length,
                  itemBuilder: (_, index) {
                    final match = matches[index];
                    final statusText = () {
                      switch (match.status) {
                        case MatchStatus.notStarted:
                          return l10n.matchStatusPending;
                        case MatchStatus.firstHalf:
                          return l10n.matchStatusFirstHalf;
                        case MatchStatus.halfTime:
                          return l10n.matchStatusHalfTime;
                        case MatchStatus.secondHalf:
                          return l10n.matchStatusSecondHalf;
                        case MatchStatus.finished:
                          return l10n.matchStatusFinished;
                      }
                    }();

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(match.opponent),
                        subtitle: Text(
                          '${match.date.day.toString().padLeft(2, '0')}/${match.date.month.toString().padLeft(2, '0')} ${match.date.hour.toString().padLeft(2, '0')}:${match.date.minute.toString().padLeft(2, '0')} · $statusText',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final authState = context.read<AuthCubit>().state;
                            if (authState is! Authenticated) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(context)!
                                        .matchDeleteNeedLogin,
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) {
                                final dlgL10n = AppLocalizations.of(context)!;
                                return AlertDialog(
                                  title: Text(dlgL10n.screenDeleteMatch),
                                  content: Text(
                                    dlgL10n.matchDeleteConfirmBody(
                                      match.opponent,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: Text(dlgL10n.actionCancel),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: Text(
                                        dlgL10n.actionRemove,
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirm != true) return;
                            if (!context.mounted) return;

                            final deleteMatchUseCase = context
                                .read<DeleteMatchUseCase>();
                            final result = await deleteMatchUseCase(
                              match,
                              authState.user,
                            );

                            if (!context.mounted) return;

                            result.fold(
                              (failure) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(failure.message),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              },
                              (_) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(context)!
                                          .matchDeletedSuccess,
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                                setState(_loadMatches);
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              });
            },
          ),
        ),
        ),
      ),
    ),
    );
  }
}
