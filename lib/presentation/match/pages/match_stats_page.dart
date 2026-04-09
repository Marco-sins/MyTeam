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

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
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
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Eventos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _events.isEmpty
                      ? const Center(child: Text('No hay eventos registrados'))
                      : ListView.builder(
                          itemCount: _events.length,
                          itemBuilder: (context, index) {
                            final event = _events[index];
                            final rawType = event['type'];
                            final typeString =
                                rawType?.toString().split('.').last ?? '';
                            final minute = (event['minute'] as int?) ?? 0;

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
                              final label =
                                  (event['note'] as String?) ?? 'Cambio estado';
                              return _StatusChangeItem(
                                label: label,
                                minute: minute,
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
                              final inPlayer = inId != null
                                  ? _playersById[inId]
                                  : null;
                              final outPlayer = outId != null
                                  ? _playersById[outId]
                                  : null;
                              return _SubstitutionItem(
                                minute: minute,
                                inName: inPlayer?.fullName ?? 'Jugador $inId',
                                outName:
                                    outPlayer?.fullName ?? 'Jugador $outId',
                              );
                            }

                            if (typeString ==
                                    MatchEventEnum.scoreGoal
                                        .toString()
                                        .split('.')
                                        .last ||
                                typeString == 'scoreGoal' ||
                                typeString ==
                                    MatchEventEnum.concedeGoal
                                        .toString()
                                        .split('.')
                                        .last ||
                                typeString == 'concedeGoal' ||
                                typeString ==
                                    MatchEventEnum.ownGoal
                                        .toString()
                                        .split('.')
                                        .last ||
                                typeString == 'ownGoal') {
                              final isOurGoal = typeString == 'scoreGoal';
                              final isAgainstGoal =
                                  typeString == 'concedeGoal' ||
                                  typeString == 'ownGoal';
                              return _GoalItem(
                                minute: minute,
                                isOurGoal: isOurGoal,
                                isAgainstGoal: isAgainstGoal,
                              );
                            }

                            // Ignoramos otros tipos (formation, etc.)
                            return const SizedBox.shrink();
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatusChangeItem extends StatelessWidget {
  final String label;
  final int minute;

  const _StatusChangeItem({required this.label, required this.minute});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Text(
            "$minute'",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Row(
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
        ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "$minute'",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(inName, style: const TextStyle(color: Colors.green)),
              const Text('  ->  '),
              Text(outName, style: const TextStyle(color: Colors.red)),
            ],
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

  const _GoalItem({
    required this.minute,
    required this.isOurGoal,
    required this.isAgainstGoal,
  });

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOurGoal ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text("Gol $minute'", style: const TextStyle(color: Colors.white)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          if (isOurGoal)
            Expanded(
              child: Align(alignment: Alignment.centerLeft, child: chip),
            ),
          if (isAgainstGoal)
            Expanded(
              child: Align(alignment: Alignment.centerRight, child: chip),
            ),
        ],
      ),
    );
  }
}
