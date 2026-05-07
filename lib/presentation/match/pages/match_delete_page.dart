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

/// Formatea la fecha y hora del partido para mostrarla en la lista.
/// Lo hace rellenando dia, mes, hora y minuto con ceros.
String _formatMatchDateTime(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}

/// Devuelve el texto localizado para el estado del partido.
/// Lo hace usando un switch sobre [MatchStatus].
String _matchDeleteStatusLabel(AppLocalizations l10n, MatchStatus status) {
  switch (status) {
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
}

/// Pantalla para borrar partidos del equipo actual.
/// Muestra una lista y confirma antes de eliminar.
class MatchDeletePage extends StatefulWidget {
  final Team team;

  /// Crea la pantalla con el equipo asociado.
  const MatchDeletePage({super.key, required this.team});

  /// Crea el estado de la pantalla.
  @override
  State<MatchDeletePage> createState() => _MatchDeletePageState();
}

class _MatchDeletePageState extends State<MatchDeletePage> {
  late Future<dynamic> _matchesFuture;

  /// Carga inicial de datos al montar el widget.
  /// Lo hace arrancando el future de partidos.
  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  /// Ejecuta el caso de uso y guarda el future para el FutureBuilder.
  /// Lo hace leyendo el use case desde el contexto.
  void _loadMatches() {
    _matchesFuture = context.read<GetMatchesByTeamUseCase>().call(
      widget.team.id,
    );
  }

  /// Construye la UI con estados de carga y la lista de borrado.
  /// Lo hace con un FutureBuilder y dialogo de confirmacion.
  @override
  Widget build(BuildContext context) {
    final team = context.watch<TeamContextCubit>().state;
    final l10n = AppLocalizations.of(context)!;
    return TeamBrandedScope(
      team: team,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.screenDeleteMatch),
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
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData) {
                    return Center(child: Text(l10n.matchListLoadError));
                  }

                  final either = snapshot.data!;
                  return either.fold(
                    (failure) => Center(child: Text(failure.message)),
                    (matches) {
                      if (matches.isEmpty) {
                        return Center(child: Text(l10n.matchListEmpty));
                      }

                      return ListView.builder(
                        itemCount: matches.length,
                        itemBuilder: (_, index) {
                          final match = matches[index];
                          final statusText = _matchDeleteStatusLabel(
                            l10n,
                            match.status,
                          );
                          final dateText = _formatMatchDateTime(match.date);

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              title: Text(match.opponent),
                              subtitle: Text('$dateText · $statusText'),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  final authState = context
                                      .read<AuthCubit>()
                                      .state;
                                  if (authState is! Authenticated) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.matchDeleteNeedLogin,
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) {
                                      return AlertDialog(
                                        title: Text(l10n.screenDeleteMatch),
                                        content: Text(
                                          l10n.matchDeleteConfirmBody(
                                            match.opponent,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(false),
                                            child: Text(l10n.actionCancel),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(true),
                                            child: Text(
                                              l10n.actionRemove,
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
                                            l10n.matchDeletedSuccess,
                                          ),
                                          backgroundColor: Colors.green,
                                          duration: const Duration(seconds: 4),
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
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
