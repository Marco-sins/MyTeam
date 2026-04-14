import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/enum/match_event_enum.dart';
import 'package:football_manager/domain/entities/enum/match_status.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/entities/match.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/presentation/match/cubit/match_stats_cubit.dart';
import 'package:football_manager/presentation/match/widgets/match_field_with_formation.dart';
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
        return 'Descanso';
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

  Widget? _eventTile(BuildContext context, MatchStatsState state, Map<String, dynamic> event) {
    final rawType = event['type'];
    final typeString = rawType?.toString().split('.').last ?? '';
    final minute = (event['minute'] as int?) ?? 0;
    final int? playerId1 = event['player_id1'] as int?;
    final int? playerId2 = event['player_id2'] as int?;

    if (typeString == 'statusChange' ||
        typeString ==
            MatchEventEnum.statusChange.toString().split('.').last) {
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
        final label = rawLabel.isEmpty ? 'Cambio de tiempo' : rawLabel;
        return MatchStatusChangeItem(
          label: label,
          minute: minute,
        );
      }

      return null;
    }

    if (typeString ==
            MatchEventEnum.substitution.toString().split('.').last ||
        typeString == 'substitution') {
      final int? inId = event['player_id1'] as int?;
      final int? outId = event['player_id2'] as int?;
      if (inId == null || outId == null) {
        return null;
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

    if (typeString == MatchEventEnum.scoreGoal.toString().split('.').last ||
        typeString == 'scoreGoal' ||
        typeString ==
            MatchEventEnum.concedeGoal.toString().split('.').last ||
        typeString == 'concedeGoal' ||
        typeString == MatchEventEnum.ownGoal.toString().split('.').last ||
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

    if (typeString == MatchEventEnum.goodSave.toString().split('.').last ||
        typeString == 'goodSave') {
      String label = (event['note'] as String?) ?? 'Buena parada';
      final player = playerId1 != null ? state.playersById[playerId1] : null;
      if (player != null) {
        label = '${_shortPlayerName(player)} · $label';
      }
      return MatchStatusChangeItem(label: label, minute: minute);
    }

    if (typeString == MatchEventEnum.yellowCard.toString().split('.').last ||
        typeString == 'yellowCard' ||
        typeString == MatchEventEnum.redCard.toString().split('.').last ||
        typeString == 'redCard') {
      final isRed = typeString == 'redCard';
      final player = playerId1 != null ? state.playersById[playerId1] : null;
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

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final dateText =
        '${match.date.day.toString().padLeft(2, '0')}/${match.date.month.toString().padLeft(2, '0')} · '
        '${match.date.hour.toString().padLeft(2, '0')}:${match.date.minute.toString().padLeft(2, '0')}';

    final authState = context.read<AuthCubit>().state;
    var isExternal = false;
    if (authState is Authenticated) {
      isExternal = authState.user.teamRoles[match.teamId] == UserRole.external;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del partido'),
        centerTitle: true,
      ),
      body: BlocBuilder<MatchStatsCubit, MatchStatsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 36,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: scheme.primary),
                          const SizedBox(height: 20),
                          Text(
                            'Cargando resumen del partido…',
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          if (state.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: scheme.error,
                            size: 40,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              state.error!,
                              style: textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          final bool showLineupSection =
              match.status == MatchStatus.finished &&
                  (state.startingPlayers.isNotEmpty ||
                      state.substitutePlayers.isNotEmpty);

          final eventTiles = <Widget>[];
          for (final e in state.events) {
            final tile = _eventTile(context, state, e);
            if (tile != null) {
              eventTiles.add(tile);
            }
          }

          final scoreSubtitle = match.status == MatchStatus.finished
              ? 'Marcador final'
              : 'Marcador';

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _MatchSummaryCard(
                match: match,
                dateText: dateText,
                statusLabel: _statusText(match.status),
                scoreSubtitle: scoreSubtitle,
                scheme: scheme,
                textTheme: textTheme,
              ),
              if (match.status == MatchStatus.finished &&
                  state.formationLines.isNotEmpty) ...[
                const SizedBox(height: 20),
                _MatchSectionTitle(
                  icon: Icons.grid_on_rounded,
                  title: 'Campo final',
                  scheme: scheme,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 10),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.formationLabel != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Chip(
                                avatar: Icon(
                                  Icons.grid_view_rounded,
                                  size: 18,
                                  color: scheme.primary,
                                ),
                                label: Text(
                                  'Formación ${state.formationLabel}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                backgroundColor: scheme.secondaryContainer
                                    .withValues(alpha: 0.55),
                                side: BorderSide.none,
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              'Disposición según las posiciones guardadas al terminar el partido.',
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 420,
                              maxHeight: 320,
                            ),
                            child: AspectRatio(
                              aspectRatio: 4 / 3,
                              child: MatchFieldWithFormation(
                                formationLines: state.formationLines,
                                positionPlayers: state.fieldPositionPlayers,
                                selectedPlayer: null,
                                sentOffPlayerIds: state.sentOffPlayerIds,
                                currentPlayersOnField: () => state
                                    .fieldPositionPlayers
                                    .where((p) => p != null)
                                    .length,
                                maxPlayersOnField: () =>
                                    state.fieldPositionPlayers.length,
                                showSnack: (_, {bool error = false}) {},
                                onPositionsChanged: (_) {},
                                onSubstitutionRequested: (playerIn, playerOut) {},
                                onPlayerActionRequested: (_) {},
                                readOnly: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _MatchSectionTitle(
                icon: Icons.timeline_rounded,
                title: 'Cronología',
                scheme: scheme,
                textTheme: textTheme,
              ),
              const SizedBox(height: 10),
              if (eventTiles.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 20,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_note_outlined,
                          size: 48,
                          color: scheme.outline.withValues(alpha: 0.85),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'No hay eventos registrados',
                          style: textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Los goles, cambios y tarjetas aparecerán aquí cuando se registren en el partido.',
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < eventTiles.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 20,
                              thickness: 1,
                              color: scheme.outlineVariant.withValues(alpha: 0.35),
                            ),
                          eventTiles[i],
                        ],
                      ],
                    ),
                  ),
                ),
              if (showLineupSection) ...[
                const SizedBox(height: 20),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
                    child: MatchLineupSection(
                      startingPlayers: state.startingPlayers,
                      substitutePlayers: state.substitutePlayers,
                      playerRatings: state.playerRatings,
                      showRatings: !isExternal,
                      onPlayerTap: (player) {
                        if (isExternal) return;
                        _showPlayerMatchStats(context, state, player);
                      },
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MatchSummaryCard extends StatelessWidget {
  const _MatchSummaryCard({
    required this.match,
    required this.dateText,
    required this.statusLabel,
    required this.scoreSubtitle,
    required this.scheme,
    required this.textTheme,
  });

  final Match match;
  final String dateText;
  final String statusLabel;
  final String scoreSubtitle;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            color: scheme.primary.withValues(alpha: 0.12),
            child: Row(
              children: [
                Icon(Icons.sports_soccer_rounded, color: scheme.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'vs ${match.opponent}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dateText,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: Icon(
                        match.isHome ? Icons.home_rounded : Icons.flight_takeoff_rounded,
                        size: 18,
                        color: scheme.primary,
                      ),
                      label: Text(
                        match.isHome ? 'Local' : 'Visitante',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      backgroundColor:
                          scheme.secondaryContainer.withValues(alpha: 0.55),
                      side: BorderSide.none,
                    ),
                    Chip(
                      label: Text(
                        statusLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      backgroundColor:
                          scheme.primaryContainer.withValues(alpha: 0.45),
                      side: BorderSide.none,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${match.goalsScored}',
                              style: textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: scheme.primary,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'A favor',
                              style: textTheme.labelLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '—',
                          style: textTheme.headlineSmall?.copyWith(
                            color: scheme.outline,
                            fontWeight: FontWeight.w200,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${match.goalsConceded}',
                              style: textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: scheme.error,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Encajados',
                              style: textTheme.labelLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    scoreSubtitle,
                    style: textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
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

class _MatchSectionTitle extends StatelessWidget {
  const _MatchSectionTitle({
    required this.icon,
    required this.title,
    required this.scheme,
    required this.textTheme,
  });

  final IconData icon;
  final String title;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: scheme.primary, size: 24),
        const SizedBox(width: 10),
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
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
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final textTheme = theme.textTheme;

  Widget statRow(IconData icon, String label, String value, {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: iconColor ?? scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        icon: Icon(Icons.person_rounded, size: 36, color: scheme.primary),
        title: Text(
          player.fullName,
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              statRow(
                Icons.timer_outlined,
                'Minutos jugados',
                '${stats.minutesPlayed}',
                iconColor: scheme.tertiary,
              ),
              const Divider(height: 20),
              statRow(
                Icons.sports_soccer_rounded,
                'Goles',
                '${stats.goals}',
              ),
              statRow(
                Icons.directions_run_rounded,
                'Asistencias',
                '${stats.assists}',
              ),
              const Divider(height: 20),
              statRow(
                Icons.check_circle_outline_rounded,
                'Pases buenos',
                '${stats.goodPasses}',
                iconColor: scheme.tertiary,
              ),
              statRow(
                Icons.cancel_outlined,
                'Pases malos',
                '${stats.badPasses}',
                iconColor: scheme.error,
              ),
              const Divider(height: 20),
              statRow(
                Icons.thumb_up_outlined,
                'Buenas jugadas',
                '${stats.goodPlays}',
                iconColor: scheme.tertiary,
              ),
              statRow(
                Icons.thumb_down_outlined,
                'Malas jugadas',
                '${stats.badPlays}',
                iconColor: scheme.outline,
              ),
            ],
          ),
        ),
        actions: [
          FilledButton.tonal(
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
  for (final event in state.events) {
    final minute = (event['minute'] as int?) ?? 0;
    if (minute > maxMinute) {
      maxMinute = minute;
    }
  }

  if (maxMinute > 0) {
    return maxMinute;
  }

  return 70;
}
