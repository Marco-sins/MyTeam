import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/entities/player_stats.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/presentation/common/widgets/player_name_text.dart';
import 'package:football_manager/presentation/player/widgets/player_avatar.dart';

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

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    scheme.primaryContainer.withValues(alpha: 0.75),
                    scheme.surface,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 18, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.shadow.withValues(alpha: 0.16),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: PlayerPhotoRect(
                        player: player,
                        width: 88,
                        height: 110,
                        borderRadius: 14,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PlayerNameText(
                            player: player,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleLarge?.copyWith(
                              height: 1.2,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.secondaryContainer
                                  .withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Dorsal ${player.number?.toString() ?? '—'}',
                              style: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.secondaryContainer
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              player.anioNacimiento != null
                                  ? 'Año de nacimiento: ${player.anioNacimiento}'
                                  : 'Año de nacimiento: —',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.sports_soccer_outlined,
                        size: 20,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _positionsText(player),
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Estadísticas de entrenamientos',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<_TrainingStats>(
                    future: _trainingStatsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
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
                  const SizedBox(height: 18),
                  Text(
                    'Estadísticas de partidos (todas las temporadas)',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
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
          ],
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
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
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
