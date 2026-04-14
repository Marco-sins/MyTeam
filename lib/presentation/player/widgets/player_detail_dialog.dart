import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/entities/player_stats.dart';
import 'package:football_manager/domain/entities/team.dart';

class PlayerDetailDialog extends StatefulWidget {
  final Team team;
  final Player player;

  const PlayerDetailDialog({
    super.key,
    required this.team,
    required this.player,
  });

  @override
  State<PlayerDetailDialog> createState() => _PlayerDetailDialogState();
}

class _PlayerDetailDialogState extends State<PlayerDetailDialog> {
  late Future<_TrainingStats> _trainingStatsFuture;

  @override
  void initState() {
    super.initState();
    _trainingStatsFuture = _loadTrainingStats();
  }

  Future<_TrainingStats> _loadTrainingStats() async {
    try {
      final supabase = Supabase.instance.client;
      final result = await supabase
          .from('attendances')
          .select('attended')
          .eq('team_id', widget.team.id)
          .eq('player_id', widget.player.id);

      final List<dynamic> rows = result as List<dynamic>;
      final total = rows.length;
      final attended = rows
          .where((row) => (row['attended'] as bool?) ?? false)
          .length;

      final percent = total > 0
          ? ((attended / total) * 100).toStringAsFixed(1)
          : '0.0';

      return _TrainingStats(
        attendedCount: attended,
        totalCount: total,
        attendancePercent: percent,
      );
    } catch (_) {
      // Si falla la carga, devolvemos 0 para no romper la UI.
      return const _TrainingStats(
        attendedCount: 0,
        totalCount: 0,
        attendancePercent: '0.0',
      );
    }
  }

  String _positionsText(Player player) {
    if (player.positions == null || player.positions!.isEmpty) {
      return 'Sin posición asignada';
    }
    return player.positions!.map((p) => p.name).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final stats = player.stats;

    return AlertDialog(
      contentPadding: const EdgeInsets.all(16),
      content: SizedBox(
        width: 340,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        player.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '#${player.number?.toString() ?? '-'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Posiciones: ${_positionsText(player)}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Estadísticas de entrenamientos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                FutureBuilder<_TrainingStats>(
                  future: _trainingStatsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    final training =
                        snapshot.data ??
                        const _TrainingStats(
                          attendedCount: 0,
                          totalCount: 0,
                          attendancePercent: '0.0',
                        );
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatChip(
                          label: 'Entrenos',
                          value:
                              '${training.attendedCount}/${training.totalCount}',
                        ),
                        _StatChip(
                          label: '% Asistencia',
                          value: '${training.attendancePercent}%',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Estadísticas de partidos (todas las temporadas)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final s = stats ?? const PlayerStats();
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _StatChip(
                          label: 'Partidos jugados',
                          value: s.matchesPlayed.toString(),
                        ),
                        _StatChip(
                          label: 'Como titular',
                          value: s.timesStarted.toString(),
                        ),
                        _StatChip(
                          label: 'Minutos',
                          value: s.minutesPlayed.toString(),
                        ),
                        _StatChip(
                          label: 'Goles',
                          value: s.goals.toString(),
                        ),
                        _StatChip(
                          label: 'Asist. gol',
                          value: s.assists.toString(),
                        ),
                        _StatChip(
                          label: 'Tarjetas (A/R)',
                          value: '${s.yellowCards}/${s.redCards}',
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

class _TrainingStats {
  final int attendedCount;
  final int totalCount;
  final String attendancePercent;

  const _TrainingStats({
    required this.attendedCount,
    required this.totalCount,
    required this.attendancePercent,
  });
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withAlpha((0.06 * 255).round()),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
