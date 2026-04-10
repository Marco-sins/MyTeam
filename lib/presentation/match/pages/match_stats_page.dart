import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/enum/match_event_enum.dart';
import 'package:football_manager/domain/entities/enum/match_status.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/entities/match.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/presentation/auth/bloc/auth_cubit.dart';
import 'package:football_manager/presentation/auth/bloc/auth_state.dart';
import 'package:football_manager/presentation/match/cubit/match_stats_cubit.dart';
import 'package:football_manager/presentation/match/widgets/match_stats_events_widgets.dart';
import 'package:football_manager/presentation/match/widgets/match_stats_lineup_section.dart';

class MatchStatsPage extends StatelessWidget {
  const MatchStatsPage({super.key, required this.match});

  final Match match;

  String _statusText(MatchStatus status) {
    switch (status) {
      case MatchStatus.notStarted:
        return 'Pendiente';
      case MatchStatus.firstHalf:
        return '1ª parte';
      case MatchStatus.halfTime:
        return 'Half time';
      case MatchStatus.secondHalf:
        return '2ª parte';
      case MatchStatus.finished:
        return 'Finalizado';
    }
  }

  String _shortPlayerName(Player player) {
    final dorsal = player.number?.toString() ?? '-';
    final firstName = player.firstName;
    final rawLastName = (player.lastName ?? '').trim();
    final firstLastName = rawLastName.isEmpty
        ? ''
        : rawLastName.split(' ').first;
    final fullName = firstLastName.isEmpty
        ? firstName
        : '$firstName $firstLastName';
    return '$dorsal  $fullName';
  }

  String _shortPlayerNameOrFallback(Player? player, {int? fallbackId}) {
    if (player == null) {
      return fallbackId != null ? 'Jugador $fallbackId' : 'Jugador';
    }
    return _shortPlayerName(player);
  }

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${match.date.day.toString().padLeft(2, '0')}/${match.date.month.toString().padLeft(2, '0')} ${match.date.hour.toString().padLeft(2, '0')}:${match.date.minute.toString().padLeft(2, '0')}';

    final authState = context.read<AuthCubit>().state;
    bool isExternal = false;
    if (authState is Authenticated) {
      isExternal = authState.user.teamRoles[match.teamId] == UserRole.external;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del partido'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocBuilder<MatchStatsCubit, MatchStatsState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.error != null) {
              return Center(child: Text(state.error!));
            }

            final bool showLineupSection =
                match.status == MatchStatus.finished &&
                (state.startingPlayers.isNotEmpty ||
                    state.substitutePlayers.isNotEmpty);

            // Toda la pantalla (card + eventos + plantilla) se desplaza junta.
            return ListView.builder(
              itemCount: () {
                if (state.events.isEmpty) {
                  // Card + espacio + título + espacio + mensaje + plantilla opcional
                  return 5 + (showLineupSection ? 1 : 0);
                } else {
                  // Card + espacio + título + espacio + eventos + plantilla opcional
                  return 4 + state.events.length + (showLineupSection ? 1 : 0);
                }
              }(),
              itemBuilder: (context, index) {
                // 0: Card con info básica de partido
                if (index == 0) {
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Vs ${match.opponent}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dateText,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _statusText(match.status),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              '${match.goalsScored}  -  ${match.goalsConceded}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Center(
                            child: Text(
                              'Marcador final',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // 1: separación debajo de la card
                if (index == 1) {
                  return const SizedBox(height: 16);
                }

                // 2: título de eventos
                if (index == 2) {
                  return const Text(
                    'Eventos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  );
                }

                // 3: separación bajo el título
                if (index == 3) {
                  return const SizedBox(height: 8);
                }

                if (state.events.isEmpty) {
                  // 4: mensaje de que no hay eventos
                  if (index == 4) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Text('No hay eventos registrados'),
                      ),
                    );
                  }

                  // 5: sección de plantilla (si procede)
                  if (showLineupSection && index == 5) {
                    return MatchLineupSection(
                      startingPlayers: state.startingPlayers,
                      substitutePlayers: state.substitutePlayers,
                      playerRatings: state.playerRatings,
                      showRatings: !isExternal,
                      onPlayerTap: (player) {
                        if (isExternal) return;
                        _showPlayerMatchStats(context, state, player);
                      },
                    );
                  }

                  return const SizedBox.shrink();
                }

                // Con eventos: a partir de aquí vienen eventos y luego plantilla
                final firstEventIndex = 4;
                final lastEventIndex =
                    firstEventIndex + state.events.length - 1;

                if (index >= firstEventIndex && index <= lastEventIndex) {
                  final event = state.events[index - firstEventIndex];
                  final rawType = event['type'];
                  final typeString = rawType?.toString().split('.').last ?? '';
                  final minute = (event['minute'] as int?) ?? 0;
                  final int? playerId1 = event['player_id1'] as int?;
                  final int? playerId2 = event['player_id2'] as int?;

                  // 1) Cambios de tiempo (inicio 1ª, descanso, inicio 2ª, final)
                  if (typeString == 'statusChange' ||
                      typeString ==
                          MatchEventEnum.statusChange
                              .toString()
                              .split('.')
                              .last) {
                    final rawLabel = (event['note'] as String?) ?? '';
                    final lowerLabel = rawLabel.toLowerCase();
                    const allowedStatusNotes = [
                      'inicio 1ª parte',
                      'inicio 1a parte',
                      'descanso',
                      'inicio 2ª parte',
                      'inicio 2a parte',
                      'final del partido',
                    ];

                    final isTimeChange = allowedStatusNotes.any(
                      (n) => lowerLabel == n.toLowerCase(),
                    );

                    if (isTimeChange) {
                      final label = rawLabel.isEmpty
                          ? 'Cambio de tiempo'
                          : rawLabel;
                      return MatchStatusChangeItem(
                        label: label,
                        minute: minute,
                      );
                    }

                    // Otros statusChange (buen pase, mala jugada, etc.) no se muestran.
                    return const SizedBox.shrink();
                  }

                  // 2) Cambios (sustituciones)
                  if (typeString ==
                          MatchEventEnum.substitution
                              .toString()
                              .split('.')
                              .last ||
                      typeString == 'substitution') {
                    final int? inId = event['player_id1'] as int?;
                    final int? outId = event['player_id2'] as int?;
                    if (inId == null || outId == null) {
                      // Solo mostramos cambios entre dos jugadores.
                      return const SizedBox.shrink();
                    }
                    final inPlayer = state.playersById[inId];
                    final outPlayer = state.playersById[outId];
                    return MatchSubstitutionItem(
                      minute: minute,
                      inName: _shortPlayerNameOrFallback(
                        inPlayer,
                        fallbackId: inId,
                      ),
                      outName: _shortPlayerNameOrFallback(
                        outPlayer,
                        fallbackId: outId,
                      ),
                    );
                  }

                  // 3) Goles (nuestros, en contra y en propia)
                  if (typeString ==
                          MatchEventEnum.scoreGoal.toString().split('.').last ||
                      typeString == 'scoreGoal' ||
                      typeString ==
                          MatchEventEnum.concedeGoal
                              .toString()
                              .split('.')
                              .last ||
                      typeString == 'concedeGoal' ||
                      typeString ==
                          MatchEventEnum.ownGoal.toString().split('.').last ||
                      typeString == 'ownGoal') {
                    final isOurGoal = typeString == 'scoreGoal';
                    final isAgainstGoal =
                        typeString == 'concedeGoal' || typeString == 'ownGoal';

                    String? scorerName;
                    String? assistName;

                    if (isOurGoal && playerId1 != null) {
                      final scorerPlayer = state.playersById[playerId1];
                      if (scorerPlayer != null) {
                        scorerName = _shortPlayerName(scorerPlayer);
                      }
                      if (playerId2 != null) {
                        final assistPlayer = state.playersById[playerId2];
                        if (assistPlayer != null) {
                          assistName = _shortPlayerName(assistPlayer);
                        }
                      }
                    }

                    return MatchGoalItem(
                      minute: minute,
                      isOurGoal: isOurGoal,
                      isAgainstGoal: isAgainstGoal,
                      scorerName: scorerName,
                      assistName: assistName,
                    );
                  }

                  // 4) Buenas paradas (buena / increíble parada)
                  if (typeString ==
                          MatchEventEnum.goodSave.toString().split('.').last ||
                      typeString == 'goodSave') {
                    String label = (event['note'] as String?) ?? 'Buena parada';
                    final player = playerId1 != null
                        ? state.playersById[playerId1]
                        : null;
                    if (player != null) {
                      label = '${_shortPlayerName(player)} - $label';
                    }
                    return MatchStatusChangeItem(label: label, minute: minute);
                  }

                  // 5) Tarjetas amarillas y rojas
                  if (typeString ==
                          MatchEventEnum.yellowCard
                              .toString()
                              .split('.')
                              .last ||
                      typeString == 'yellowCard' ||
                      typeString ==
                          MatchEventEnum.redCard.toString().split('.').last ||
                      typeString == 'redCard') {
                    final isRed = typeString == 'redCard';
                    final player = playerId1 != null
                        ? state.playersById[playerId1]
                        : null;
                    final playerName = _shortPlayerNameOrFallback(
                      player,
                      fallbackId: playerId1,
                    );
                    return MatchCardItem(
                      minute: minute,
                      playerName: playerName,
                      isRed: isRed,
                    );
                  }

                  // Ignoramos otros tipos (formation, pases, jugadas, etc.)
                  return const SizedBox.shrink();
                }

                // Después del último evento, si hay plantilla se muestra aquí
                if (showLineupSection && index == lastEventIndex + 1) {
                  return MatchLineupSection(
                    startingPlayers: state.startingPlayers,
                    substitutePlayers: state.substitutePlayers,
                    playerRatings: state.playerRatings,
                    onPlayerTap: (player) =>
                        _showPlayerMatchStats(context, state, player),
                  );
                }

                return const SizedBox.shrink();
              },
            );
          },
        ),
      ),
    );
  }
}

class _PlayerMatchStats {
  const _PlayerMatchStats({
    required this.goals,
    required this.assists,
    required this.goodPasses,
    required this.badPasses,
    required this.goodPlays,
    required this.badPlays,
    required this.minutesPlayed,
  });

  final int goals;
  final int assists;
  final int goodPasses;
  final int badPasses;
  final int goodPlays;
  final int badPlays;
  final int minutesPlayed;
}

Future<void> _showPlayerMatchStats(
  BuildContext context,
  MatchStatsState state,
  Player player,
) async {
  final stats = _calculatePlayerMatchStats(state, player);

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(player.fullName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Minutos jugados: ${stats.minutesPlayed}'),
            const SizedBox(height: 8),
            Text('Goles: ${stats.goals}'),
            Text('Asistencias: ${stats.assists}'),
            const SizedBox(height: 8),
            Text('Pases buenos: ${stats.goodPasses}'),
            Text('Pases malos: ${stats.badPasses}'),
            const SizedBox(height: 8),
            Text('Buenas jugadas: ${stats.goodPlays}'),
            Text('Malas jugadas: ${stats.badPlays}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      );
    },
  );
}

_PlayerMatchStats _calculatePlayerMatchStats(
  MatchStatsState state,
  Player player,
) {
  final int playerId = player.id;

  int goals = 0;
  int assists = 0;
  int goodPasses = 0;
  int badPasses = 0;
  int goodPlays = 0;
  int badPlays = 0;

  for (final event in state.events) {
    final rawType = event['type'];
    final typeString = rawType?.toString().split('.').last ?? '';
    final int? p1 = event['player_id1'] as int?;
    final int? p2 = event['player_id2'] as int?;
    final String? note = event['note'] as String?;

    if (typeString == MatchEventEnum.scoreGoal.toString().split('.').last ||
        typeString == 'scoreGoal') {
      if (p1 == playerId) {
        goals++;
      }
      if (p2 == playerId) {
        assists++;
      }
    }

    if (p1 != playerId) continue;

    if (note == 'Buen pase') {
      goodPasses++;
    } else if (note == 'Mal pase') {
      badPasses++;
    } else if (note == 'Pase clave') {
      goodPlays++;
    } else if (note == 'Buena jugada' ||
        note == 'Buen tiro' ||
        note == 'Recupera posesión' ||
        note == 'Gana posesión') {
      goodPlays++;
    } else if (note == 'Mala jugada' ||
        note == 'Pierde marca' ||
        note == 'Pierde posición' ||
        note == 'Pierde posesión' ||
        note == 'Gol concedido' ||
        note == 'Gol en propia') {
      badPlays++;
    }
  }

  final minutesPlayed = _calculateMinutesPlayed(state, player);

  return _PlayerMatchStats(
    goals: goals,
    assists: assists,
    goodPasses: goodPasses,
    badPasses: badPasses,
    goodPlays: goodPlays,
    badPlays: badPlays,
    minutesPlayed: minutesPlayed,
  );
}

int _calculateMinutesPlayed(MatchStatsState state, Player player) {
  final int playerId = player.id;

  // Ordenamos eventos ascendentemente por minuto y created_at para
  // reconstruir bien las entradas y salidas al campo.
  final List<Map<String, dynamic>> sortedEvents =
      List<Map<String, dynamic>>.from(state.events);
  sortedEvents.sort((a, b) {
    final ma = (a['minute'] as int?) ?? 0;
    final mb = (b['minute'] as int?) ?? 0;
    if (ma != mb) return ma.compareTo(mb);

    final caRaw = a['created_at'];
    final cbRaw = b['created_at'];
    DateTime ca;
    DateTime cb;
    try {
      ca = caRaw != null ? DateTime.parse(caRaw.toString()) : DateTime(1970);
    } catch (_) {
      ca = DateTime(1970);
    }
    try {
      cb = cbRaw != null ? DateTime.parse(cbRaw.toString()) : DateTime(1970);
    } catch (_) {
      cb = DateTime(1970);
    }
    return ca.compareTo(cb);
  });

  final bool isStarter = state.isStarterById[playerId] ?? false;
  final int matchEndMinute = _getMatchEndMinute(state);
  if (matchEndMinute <= 0) {
    return 0;
  }

  bool onField = isStarter;
  int lastOnMinute = isStarter ? 0 : -1;
  int totalMinutes = 0;

  for (final event in sortedEvents) {
    final rawType = event['type'];
    final typeString = rawType?.toString().split('.').last ?? '';
    if (!(typeString ==
            MatchEventEnum.substitution.toString().split('.').last ||
        typeString == 'substitution')) {
      continue;
    }

    final minute = (event['minute'] as int?) ?? 0;
    final int? inId = event['player_id1'] as int?;
    final int? outId = event['player_id2'] as int?;

    if (outId == playerId && onField) {
      final start = lastOnMinute >= 0 ? lastOnMinute : minute;
      if (minute > start) {
        totalMinutes += minute - start;
      }
      onField = false;
      lastOnMinute = -1;
    } else if (inId == playerId && !onField) {
      onField = true;
      lastOnMinute = minute;
    }
  }

  if (onField) {
    final start = lastOnMinute >= 0 ? lastOnMinute : 0;
    if (matchEndMinute > start) {
      totalMinutes += matchEndMinute - start;
    }
  }

  if (totalMinutes < 0) {
    return 0;
  }
  return totalMinutes;
}

int _getMatchEndMinute(MatchStatsState state) {
  int? finishedMinute;

  for (final event in state.events) {
    final rawType = event['type'];
    final typeString = rawType?.toString().split('.').last ?? '';
    final String? note = event['note'] as String?;
    if ((typeString == MatchEventEnum.statusChange.toString().split('.').last ||
            typeString == 'statusChange') &&
        note != null &&
        note.toLowerCase().contains('final')) {
      final minute = (event['minute'] as int?) ?? 0;
      finishedMinute = minute;
    }
  }

  if (finishedMinute != null) {
    return finishedMinute;
  }

  int maxMinute = 0;
  for (final event in state.events) {
    final minute = (event['minute'] as int?) ?? 0;
    if (minute > maxMinute) {
      maxMinute = minute;
    }
  }

  if (maxMinute > 0) {
    return maxMinute;
  }

  // Valor por defecto si no hay eventos con minuto registrado.
  return 70;
}
