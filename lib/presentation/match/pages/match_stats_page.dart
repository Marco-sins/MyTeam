import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg1/domain/entities/enum/match_event_enum.dart';
import 'package:tfg1/domain/entities/enum/match_status.dart';
import 'package:tfg1/domain/entities/match.dart';
import 'package:tfg1/domain/entities/player.dart';
import 'package:tfg1/domain/usecase/player/get_players_by_team_use_case.dart';

class MatchStatsPage extends StatefulWidget {
  final Match match;

  const MatchStatsPage({super.key, required this.match});

  @override
  State<MatchStatsPage> createState() => _MatchStatsPageState();
}

class _MatchStatsPageState extends State<MatchStatsPage> {
  late Future<void> _loadFuture;
  List<Map<String, dynamic>> _events = [];
  Map<int, Player> _playersById = {};
  String? _error;
  List<Player> _startingPlayers = [];
  List<Player> _substitutePlayers = [];
  final Map<int, bool> _isStarterById = {};

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadData();
  }

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

  Future<void> _loadData() async {
    try {
      final supabase = Supabase.instance.client;
      final rawEvents = await supabase
          .from('match_events')
          .select('id, type, minute, player_id1, player_id2, note, created_at')
          .eq('match_id', widget.match.id)
          .order('minute', ascending: false)
          .order('created_at', ascending: false);

      _events = List<Map<String, dynamic>>.from(rawEvents as List);

      final getPlayersByTeamUseCase = context.read<GetPlayersByTeamUseCase>();
      final playersEither = await getPlayersByTeamUseCase(widget.match.teamId);

      playersEither.fold(
        (failure) {
          _error = failure.message;
        },
        (players) {
          _playersById = {for (final p in players) p.id: p};
        },
      );

      // Cargamos la plantilla que ha ido al partido desde match_lineup
      final rawLineups = await supabase
          .from('match_lineup')
          .select('player_id, is_start')
          .eq('match_id', widget.match.id);

      final starting = <Player>[];
      final subs = <Player>[];

      for (final row in rawLineups as List) {
        final playerId = row['player_id'] as int?;
        if (playerId == null) continue;
        final player = _playersById[playerId];
        if (player == null) continue;
        final isStart = (row['is_start'] as bool?) ?? false;
        _isStarterById[player.id] = isStart;
        if (isStart) {
          starting.add(player);
        } else {
          subs.add(player);
        }
      }

      int byDorsal(Player a, Player b) {
        final na = a.number ?? 9999;
        final nb = b.number ?? 9999;
        return na.compareTo(nb);
      }

      starting.sort(byDorsal);
      subs.sort(byDorsal);

      _startingPlayers = starting;
      _substitutePlayers = subs;
    } catch (_) {
      _error = 'No se han podido cargar los eventos del partido';
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final dateText =
        '${match.date.day.toString().padLeft(2, '0')}/${match.date.month.toString().padLeft(2, '0')} ${match.date.hour.toString().padLeft(2, '0')}:${match.date.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del partido'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<void>(
          future: _loadFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_error != null) {
              return Center(child: Text(_error!));
            }

            final bool showLineupSection =
                match.status == MatchStatus.finished &&
                (_startingPlayers.isNotEmpty || _substitutePlayers.isNotEmpty);

            // Toda la pantalla (card + eventos + plantilla) se desplaza junta.
            return ListView.builder(
              itemCount: () {
                if (_events.isEmpty) {
                  // Card + espacio + título + espacio + mensaje + plantilla opcional
                  return 5 + (showLineupSection ? 1 : 0);
                } else {
                  // Card + espacio + título + espacio + eventos + plantilla opcional
                  return 4 + _events.length + (showLineupSection ? 1 : 0);
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

                if (_events.isEmpty) {
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
                    return _LineupSection(
                      startingPlayers: _startingPlayers,
                      substitutePlayers: _substitutePlayers,
                      onPlayerTap: _showPlayerMatchStats,
                    );
                  }

                  return const SizedBox.shrink();
                }

                // Con eventos: a partir de aquí vienen eventos y luego plantilla
                final firstEventIndex = 4;
                final lastEventIndex = firstEventIndex + _events.length - 1;

                if (index >= firstEventIndex && index <= lastEventIndex) {
                  final event = _events[index - firstEventIndex];
                  final rawType = event['type'];
                  final typeString = rawType?.toString().split('.').last ?? '';
                  final minute = (event['minute'] as int?) ?? 0;
                  final int? playerId1 = event['player_id1'] as int?;
                  final int? playerId2 = event['player_id2'] as int?;

                  if (typeString == 'statusChange' ||
                      typeString ==
                          MatchEventEnum.statusChange
                              .toString()
                              .split('.')
                              .last ||
                      typeString == 'firstHalf' ||
                      typeString == 'halfTime' ||
                      typeString == 'secondHalf' ||
                      typeString == 'finished') {
                    final label = (event['note'] as String?) ?? 'Cambio estado';
                    final bool isPartChange =
                        typeString == 'firstHalf' ||
                        typeString == 'halfTime' ||
                        typeString == 'secondHalf' ||
                        typeString == 'finished';
                    return _StatusChangeItem(
                      label: label,
                      minute: isPartChange ? minute : null,
                    );
                  }

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
                    final inPlayer = _playersById[inId];
                    final outPlayer = _playersById[outId];
                    return _SubstitutionItem(
                      minute: minute,
                      inName: inPlayer?.fullName ?? 'Jugador $inId',
                      outName: outPlayer?.fullName ?? 'Jugador $outId',
                    );
                  }

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
                      scorerName = _playersById[playerId1]?.fullName;
                      if (playerId2 != null) {
                        assistName = _playersById[playerId2]?.fullName;
                      }
                    }

                    return _GoalItem(
                      minute: minute,
                      isOurGoal: isOurGoal,
                      isAgainstGoal: isAgainstGoal,
                      scorerName: scorerName,
                      assistName: assistName,
                    );
                  }

                  // Ignoramos otros tipos (formation, etc.)
                  return const SizedBox.shrink();
                }

                // Después del último evento, si hay plantilla se muestra aquí
                if (showLineupSection && index == lastEventIndex + 1) {
                  return _LineupSection(
                    startingPlayers: _startingPlayers,
                    substitutePlayers: _substitutePlayers,
                    onPlayerTap: _showPlayerMatchStats,
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
  final int goals;
  final int assists;
  final int goodPasses;
  final int badPasses;
  final int goodPlays;
  final int badPlays;
  final int minutesPlayed;

  const _PlayerMatchStats({
    required this.goals,
    required this.assists,
    required this.goodPasses,
    required this.badPasses,
    required this.goodPlays,
    required this.badPlays,
    required this.minutesPlayed,
  });
}

extension on _MatchStatsPageState {
  Future<void> _showPlayerMatchStats(Player player) async {
    final stats = _calculatePlayerMatchStats(player);

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

  _PlayerMatchStats _calculatePlayerMatchStats(Player player) {
    final int playerId = player.id;

    int goals = 0;
    int assists = 0;
    int goodPasses = 0;
    int badPasses = 0;
    int goodPlays = 0;
    int badPlays = 0;

    for (final event in _events) {
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
      } else if (note == 'Buen tiro' || note == 'Recupera posesión') {
        goodPlays++;
      } else if (note == 'Mala jugada' || note == 'Pierde marca') {
        badPlays++;
      }
    }

    final minutesPlayed = _calculateMinutesPlayed(player);

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

  int _calculateMinutesPlayed(Player player) {
    final int playerId = player.id;

    // Ordenamos eventos ascendentemente por minuto y created_at para
    // reconstruir bien las entradas y salidas al campo.
    final List<Map<String, dynamic>> sortedEvents =
        List<Map<String, dynamic>>.from(_events);
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

    final bool isStarter = _isStarterById[playerId] ?? false;
    final int matchEndMinute = _getMatchEndMinute();
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

  int _getMatchEndMinute() {
    int? finishedMinute;

    for (final event in _events) {
      final rawType = event['type'];
      final typeString = rawType?.toString().split('.').last ?? '';
      final String? note = event['note'] as String?;
      if ((typeString ==
                  MatchEventEnum.statusChange.toString().split('.').last ||
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
    for (final event in _events) {
      final minute = (event['minute'] as int?) ?? 0;
      if (minute > maxMinute) {
        maxMinute = minute;
      }
    }

    if (maxMinute > 0) {
      return maxMinute;
    }

    return widget.match.status == MatchStatus.finished ? 70 : 0;
  }
}

class _StatusChangeItem extends StatelessWidget {
  final String label;
  final int? minute;

  const _StatusChangeItem({required this.label, this.minute});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: minute != null
                ? Text(
                    "${minute!}'",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineupSection extends StatelessWidget {
  final List<Player> startingPlayers;
  final List<Player> substitutePlayers;
  final void Function(Player) onPlayerTap;

  const _LineupSection({
    required this.startingPlayers,
    required this.substitutePlayers,
    required this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 24),
          const Text(
            'Plantilla del partido',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (startingPlayers.isNotEmpty) ...[
            const Text(
              'Titulares',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            for (final p in startingPlayers)
              _LineupPlayerRow(
                player: p,
                label: 'Titular',
                onTap: () => onPlayerTap(p),
              ),
            const SizedBox(height: 12),
          ],
          if (substitutePlayers.isNotEmpty) ...[
            const Text(
              'Suplentes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            for (final p in substitutePlayers)
              _LineupPlayerRow(
                player: p,
                label: 'Suplente',
                onTap: () => onPlayerTap(p),
              ),
          ],
        ],
      ),
    );
  }
}

class _LineupPlayerRow extends StatelessWidget {
  final Player player;
  final String label;
  final VoidCallback onTap;

  const _LineupPlayerRow({
    required this.player,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                player.number?.toString() ?? '-',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                player.fullName,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: label == 'Titular'
                    ? Colors.green.withOpacity(0.1)
                    : Colors.blueGrey.withOpacity(0.1),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: label == 'Titular'
                      ? Colors.green[800]
                      : Colors.blueGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubstitutionItem extends StatelessWidget {
  final int minute;
  final String inName;
  final String outName;

  const _SubstitutionItem({
    required this.minute,
    required this.inName,
    required this.outName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              "$minute'",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    inName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
                const SizedBox(width: 4),
                const Text('→'),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    outName,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalItem extends StatelessWidget {
  final int minute;
  final bool isOurGoal;
  final bool isAgainstGoal;
  final String? scorerName;
  final String? assistName;

  const _GoalItem({
    required this.minute,
    required this.isOurGoal,
    required this.isAgainstGoal,
    this.scorerName,
    this.assistName,
  });

  @override
  Widget build(BuildContext context) {
    // Para goles nuestros con jugador identificado, mostramos goleador y
    // asistente (si existe) con iconos de pelota y bota.
    if (isOurGoal && scorerName != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                "$minute'",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  // Goleador con icono de pelota
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sports_soccer, size: 18),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            scorerName!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (assistName != null) ...[
                    const SizedBox(width: 8),
                    // Asistente alineado a la derecha con icono de bota
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              assistName!,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.directions_run, size: 18),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Para el resto de goles (sin jugador o goles en contra),
    // mantenemos el chip anterior.
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOurGoal ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text('Gol', style: TextStyle(color: Colors.white)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              "$minute'",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: isOurGoal
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: chip,
            ),
          ),
        ],
      ),
    );
  }
}
