import 'package:flutter/material.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/enum/match_status.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/entities/match.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/core/utils/supabase_dynamic.dart';
import 'package:football_manager/presentation/common/widgets/player_name_text.dart';
import 'package:football_manager/presentation/match/cubit/match_stats_cubit.dart';
import 'package:football_manager/presentation/match/widgets/match_field_with_formation.dart';
import 'package:football_manager/presentation/match/widgets/match_stats_events_widgets.dart';
import 'package:football_manager/presentation/match/widgets/match_stats_lineup_section.dart';

/// Tono para acciones guardadas como [statusChange] + nota (datos anteriores al enum dedicado).
Color _accentForLegacyStatusActionNote(ColorScheme scheme, String label) {
  final lower = label.toLowerCase();
  if (lower.contains('mal ') ||
      lower.contains('mala ') ||
      lower.contains('pase impreciso') ||
      lower.contains('poor pass') ||
      lower.contains('jugada imprecisa') ||
      lower.contains('poor play') ||
      lower.contains('pierde ') ||
      lower.contains('gol concedido') ||
      lower.contains('gol en propia') ||
      lower.contains('autogol') ||
      lower.contains('own goal')) {
    return scheme.error;
  }
  if (lower.contains('buen ') ||
      lower.contains('buena ') ||
      lower.contains('good pass') ||
      lower.contains('good play') ||
      lower.contains('pase clave') ||
      lower.contains('key pass') ||
      lower.contains('gana posesión') ||
      lower.contains('gana posicion') ||
      lower.contains('recupera posesión') ||
      lower.contains('recupera posesion') ||
      lower.contains('recuperación') ||
      lower.contains('recuperacion') ||
      lower.contains('ball recovered') ||
      lower.contains('balón recuperado') ||
      lower.contains('balon recuperado') ||
      lower.contains('jugada clave') ||
      lower.contains('buena parada') ||
      lower.contains('increíble parada') ||
      lower.contains('increible parada') ||
      lower.contains('buen tiro') ||
      lower.contains('great save')) {
    return scheme.tertiary;
  }
  return scheme.onSurface;
}

String _matchStatusLabel(AppLocalizations l10n, MatchStatus status) {
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

String _localizedTimeStatusNote(AppLocalizations l10n, String raw) {
  final lower = raw.trim().toLowerCase();
  if (lower == 'inicio 1ª parte' || lower == 'inicio 1a parte') {
    return l10n.matchNoteFirstHalfStart;
  }
  if (lower == 'descanso') return l10n.matchStatusHalfTime;
  if (lower == 'inicio 2ª parte' || lower == 'inicio 2a parte') {
    return l10n.matchNoteSecondHalfStart;
  }
  if (lower == 'final del partido') return l10n.matchNoteMatchFinished;
  return raw;
}

class MatchStatsPage extends StatelessWidget {
  const MatchStatsPage({super.key, required this.match});

  final Match match;

  Widget? _eventTile(
    BuildContext context,
    MatchStatsState state,
    Map<String, dynamic> event,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final rawType = event['type'];
    final typeKey = canonicalMatchEventTypeKey(rawType);
    final minute = supabaseInt(event['minute']) ?? 0;
    final int? playerId1 = supabaseInt(event['player_id1']);
    final int? playerId2 = supabaseInt(event['player_id2']);

    if (typeKey == 'statuschange') {
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
            ? l10n.matchLivePeriodFallback
            : _localizedTimeStatusNote(l10n, rawLabel);
        return MatchStatusChangeItem(label: label, minute: minute);
      }

      // Resto de statusChange: acciones de jugador antiguas (nota + jugador), no cronología de tiempo.
      final noteLabel = rawLabel.isEmpty
          ? l10n.matchEventLegacyActionRegistered
          : rawLabel;
      final scheme = Theme.of(context).colorScheme;
      final accentColor = _accentForLegacyStatusActionNote(scheme, noteLabel);
      final accentStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: accentColor,
          );
      final player = playerId1 != null ? state.playersById[playerId1] : null;
      if (player != null) {
        return MatchStatusChangeItem(
          minute: minute,
          label: noteLabel,
          labelWidget: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: accentStyle,
              children: [
                TextSpan(text: '$noteLabel: '),
                ...playerDorsalNameSpanList(player, accentStyle),
              ],
            ),
          ),
        );
      }
      return MatchStatusChangeItem(label: noteLabel, minute: minute);
    }

    if (typeKey == 'substitution') {
      final int? inId = playerId1;
      final int? outId = playerId2;
      if (inId == null || outId == null) {
        return null;
      }
      final inPlayer = state.playersById[inId];
      final outPlayer = state.playersById[outId];
      return MatchSubstitutionItem(
        minute: minute,
        inPlayer: inPlayer,
        outPlayer: outPlayer,
        inFallbackId: inId,
        outFallbackId: outId,
      );
    }

    if (typeKey == 'scoregoal' ||
        typeKey == 'concedegoal' ||
        typeKey == 'owngoal') {
      final isOurGoal = typeKey == 'scoregoal';
      final isOwnGoal = typeKey == 'owngoal';
      final isAgainstGoal =
          typeKey == 'concedegoal' || typeKey == 'owngoal';

      Player? scorerPlayer;
      Player? assistPlayer;
      if (isOurGoal && playerId1 != null) {
        scorerPlayer = state.playersById[playerId1];
        if (playerId2 != null) {
          assistPlayer = state.playersById[playerId2];
        }
      }

      return MatchGoalItem(
        minute: minute,
        isOurGoal: isOurGoal,
        isAgainstGoal: isAgainstGoal,
        isOwnGoal: isOwnGoal,
        scorerPlayer: scorerPlayer,
        assistPlayer: assistPlayer,
      );
    }

    if (typeKey == 'goodsave') {
      final noteRaw = (event['note'] as String?)?.trim() ?? '';
      final player = playerId1 != null ? state.playersById[playerId1] : null;
      final scheme = Theme.of(context).colorScheme;
      final accentStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.tertiary,
          );
      if (player != null) {
        return MatchStatusChangeItem(
          minute: minute,
          label: noteRaw.isNotEmpty ? noteRaw : l10n.matchLiveSaveOnly,
          labelWidget: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: accentStyle,
              children: [
                TextSpan(text: l10n.matchLiveSaveBy),
                ...playerDorsalNameSpanList(player, accentStyle),
                if (noteRaw.isNotEmpty) TextSpan(text: ' · $noteRaw'),
              ],
            ),
          ),
        );
      }
      return MatchStatusChangeItem(
        label: noteRaw.isNotEmpty ? noteRaw : l10n.matchLiveSaveOnly,
        minute: minute,
      );
    }

    if (typeKey == 'goodpass') {
      final player = playerId1 != null ? state.playersById[playerId1] : null;
      final scheme = Theme.of(context).colorScheme;
      final accentStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.tertiary,
          );
      final headline = l10n.matchActionLabelGoodPass;
      if (player != null) {
        return MatchStatusChangeItem(
          minute: minute,
          label: headline,
          labelWidget: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: accentStyle,
              children: [
                TextSpan(text: '$headline: '),
                ...playerDorsalNameSpanList(player, accentStyle),
              ],
            ),
          ),
        );
      }
      return MatchStatusChangeItem(label: headline, minute: minute);
    }

    if (typeKey == 'goodplay') {
      final player = playerId1 != null ? state.playersById[playerId1] : null;
      final scheme = Theme.of(context).colorScheme;
      final accentStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.tertiary,
          );
      final headline = l10n.matchActionLabelGoodPlay;
      if (player != null) {
        return MatchStatusChangeItem(
          minute: minute,
          label: headline,
          labelWidget: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: accentStyle,
              children: [
                TextSpan(text: '$headline: '),
                ...playerDorsalNameSpanList(player, accentStyle),
              ],
            ),
          ),
        );
      }
      return MatchStatusChangeItem(label: headline, minute: minute);
    }

    if (typeKey == 'ballrecovery') {
      final player = playerId1 != null ? state.playersById[playerId1] : null;
      final scheme = Theme.of(context).colorScheme;
      final accentStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.tertiary,
          );
      final headline = l10n.matchActionLabelBallRecovery;
      if (player != null) {
        return MatchStatusChangeItem(
          minute: minute,
          label: headline,
          labelWidget: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: accentStyle,
              children: [
                TextSpan(text: '$headline: '),
                ...playerDorsalNameSpanList(player, accentStyle),
              ],
            ),
          ),
        );
      }
      return MatchStatusChangeItem(label: headline, minute: minute);
    }

    if (typeKey == 'badpass') {
      final player = playerId1 != null ? state.playersById[playerId1] : null;
      final scheme = Theme.of(context).colorScheme;
      final accentStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.error,
          );
      final headline = l10n.matchActionLabelBadPass;
      if (player != null) {
        return MatchStatusChangeItem(
          minute: minute,
          label: headline,
          labelWidget: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: accentStyle,
              children: [
                TextSpan(text: '$headline: '),
                ...playerDorsalNameSpanList(player, accentStyle),
              ],
            ),
          ),
        );
      }
      return MatchStatusChangeItem(label: headline, minute: minute);
    }

    if (typeKey == 'badplay') {
      final player = playerId1 != null ? state.playersById[playerId1] : null;
      final scheme = Theme.of(context).colorScheme;
      final accentStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.error,
          );
      final headline = l10n.matchActionLabelBadPlay;
      if (player != null) {
        return MatchStatusChangeItem(
          minute: minute,
          label: headline,
          labelWidget: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: accentStyle,
              children: [
                TextSpan(text: '$headline: '),
                ...playerDorsalNameSpanList(player, accentStyle),
              ],
            ),
          ),
        );
      }
      return MatchStatusChangeItem(label: headline, minute: minute);
    }

    if (typeKey == 'keypass') {
      final player = playerId1 != null ? state.playersById[playerId1] : null;
      final scheme = Theme.of(context).colorScheme;
      final accentStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.tertiary,
          );
      final notePass = (event['note'] as String?)?.trim();
      final headline = (notePass != null && notePass.isNotEmpty)
          ? notePass
          : l10n.matchActionLabelKeyPass;
      if (player != null) {
        return MatchStatusChangeItem(
          minute: minute,
          label: headline,
          labelWidget: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: accentStyle,
              children: [
                TextSpan(text: '$headline: '),
                ...playerDorsalNameSpanList(player, accentStyle),
              ],
            ),
          ),
        );
      }
      return MatchStatusChangeItem(label: headline, minute: minute);
    }

    if (typeKey == 'yellowcard' || typeKey == 'redcard') {
      final isRed = typeKey == 'redcard';
      final player = playerId1 != null ? state.playersById[playerId1] : null;
      return MatchCardItem(
        minute: minute,
        player: player,
        fallbackPlayerId: playerId1,
        isRed: isRed,
      );
    }

    // Respaldo: tipos nuevos en BD o etiquetas de enum que no coinciden con el cliente.
    final noteFallback = (event['note'] as String?)?.trim();
    if (typeKey != 'formation' &&
        noteFallback != null &&
        noteFallback.isNotEmpty) {
      final scheme = Theme.of(context).colorScheme;
      final accentColor =
          _accentForLegacyStatusActionNote(scheme, noteFallback);
      final accentStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: accentColor,
          );
      final player =
          playerId1 != null ? state.playersById[playerId1] : null;
      if (player != null) {
        return MatchStatusChangeItem(
          minute: minute,
          label: noteFallback,
          labelWidget: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: accentStyle,
              children: [
                TextSpan(text: '$noteFallback: '),
                ...playerDorsalNameSpanList(player, accentStyle),
              ],
            ),
          ),
        );
      }
      return MatchStatusChangeItem(label: noteFallback, minute: minute);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;

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
        title: Text(AppLocalizations.of(context)!.screenMatchDetail),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<MatchStatsCubit, MatchStatsState>(
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
                              l10n.matchStatsLoadingSummary,
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
                ? l10n.matchStatsScoreFinal
                : l10n.matchStatsScoreLive;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                _MatchSummaryCard(
                  match: match,
                  dateText: dateText,
                  statusLabel: _matchStatusLabel(l10n, match.status),
                  scoreSubtitle: scoreSubtitle,
                  scheme: scheme,
                  textTheme: textTheme,
                  vsTitle: l10n.matchSummaryVs(match.opponent),
                  homeVenueLabel: l10n.matchVenueHome,
                  awayVenueLabel: l10n.matchVenueAway,
                  goalsForLabel: l10n.matchScoreForLabel,
                  goalsAgainstLabel: l10n.matchScoreAgainstLabel,
                ),
                if (match.status == MatchStatus.finished &&
                    state.formationLines.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _MatchSectionTitle(
                    icon: Icons.grid_on_rounded,
                    title: l10n.matchStatsSectionField,
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
                                    l10n.matchStatsFormationChip(
                                      state.formationLabel!,
                                    ),
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
                                l10n.matchStatsFieldDispositionHint,
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
                                  onSubstitutionRequested:
                                      (playerIn, playerOut) {},
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
                  title: l10n.matchStatsSectionTimeline,
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
                            l10n.matchStatsTimelineEmpty,
                            style: textTheme.bodyLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.matchStatsTimelineEmptyHint,
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
                                color: scheme.outlineVariant.withValues(
                                  alpha: 0.35,
                                ),
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
    required this.vsTitle,
    required this.homeVenueLabel,
    required this.awayVenueLabel,
    required this.goalsForLabel,
    required this.goalsAgainstLabel,
  });

  final Match match;
  final String dateText;
  final String statusLabel;
  final String scoreSubtitle;
  final ColorScheme scheme;
  final TextTheme textTheme;
  final String vsTitle;
  final String homeVenueLabel;
  final String awayVenueLabel;
  final String goalsForLabel;
  final String goalsAgainstLabel;

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
                Icon(
                  Icons.sports_soccer_rounded,
                  color: scheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vsTitle,
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
                        match.isHome
                            ? Icons.home_rounded
                            : Icons.flight_takeoff_rounded,
                        size: 18,
                        color: scheme.primary,
                      ),
                      label: Text(
                        match.isHome ? homeVenueLabel : awayVenueLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      backgroundColor: scheme.secondaryContainer.withValues(
                        alpha: 0.55,
                      ),
                      side: BorderSide.none,
                    ),
                    Chip(
                      label: Text(
                        statusLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      backgroundColor: scheme.primaryContainer.withValues(
                        alpha: 0.45,
                      ),
                      side: BorderSide.none,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
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
                              goalsForLabel,
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
                              goalsAgainstLabel,
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
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
  final l10n = AppLocalizations.of(context)!;

  Widget statRow(
    IconData icon,
    String label,
    String value, {
    Color? iconColor,
  }) {
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
        title: PlayerNameText(
          player: player,
          mode: PlayerNameTextMode.general,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              statRow(
                Icons.timer_outlined,
                l10n.matchStatsMinutesPlayed,
                '${stats.minutesPlayed}',
                iconColor: scheme.tertiary,
              ),
              const Divider(height: 20),
              statRow(
                Icons.sports_soccer_rounded,
                l10n.matchStatsStatGoals,
                '${stats.goals}',
              ),
              statRow(
                Icons.directions_run_rounded,
                l10n.matchStatsStatAssists,
                '${stats.assists}',
              ),
              const Divider(height: 20),
              statRow(
                Icons.check_circle_outline_rounded,
                l10n.matchStatsStatGoodPasses,
                '${stats.goodPasses}',
                iconColor: scheme.tertiary,
              ),
              statRow(
                Icons.cancel_outlined,
                l10n.matchStatsStatBadPasses,
                '${stats.badPasses}',
                iconColor: scheme.error,
              ),
              const Divider(height: 20),
              statRow(
                Icons.thumb_up_outlined,
                l10n.matchStatsStatGoodPlays,
                '${stats.goodPlays}',
                iconColor: scheme.tertiary,
              ),
              statRow(
                Icons.thumb_down_outlined,
                l10n.matchStatsStatBadPlays,
                '${stats.badPlays}',
                iconColor: scheme.outline,
              ),
            ],
          ),
        ),
        actions: [
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.dialogClose),
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
    final typeKey = canonicalMatchEventTypeKey(rawType);
    final int? p1 = event['player_id1'] as int?;
    final int? p2 = event['player_id2'] as int?;
    final String? note = event['note'] as String?;

    if (typeKey == 'scoregoal') {
      if (p1 == playerId) {
        goals++;
      }
      if (p2 == playerId) {
        assists++;
      }
    }

    if (p1 != playerId) continue;

    final isGoodPass = typeKey == 'goodpass';
    final isBadPass = typeKey == 'badpass';
    final isGoodPlay = typeKey == 'goodplay';
    final isBadPlay = typeKey == 'badplay';
    final isBallRecovery = typeKey == 'ballrecovery';

    if (isGoodPass || note == 'Buen pase') {
      goodPasses++;
    } else if (isBadPass ||
        note == 'Mal pase' ||
        note == 'Pase impreciso') {
      badPasses++;
    } else if (note == 'Pase clave' || typeKey == 'keypass') {
      goodPlays++;
    } else if (isGoodPlay ||
        isBallRecovery ||
        note == 'Buena jugada' ||
        note == 'Recuperación' ||
        note == 'Balón recuperado' ||
        note == 'Buen tiro' ||
        note == 'Recupera posesión' ||
        note == 'Gana posesión') {
      goodPlays++;
    } else if (isBadPlay ||
        note == 'Mala jugada' ||
        note == 'Jugada imprecisa' ||
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
    final ma = supabaseInt(a['minute']) ?? 0;
    final mb = supabaseInt(b['minute']) ?? 0;
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
    final typeKey = canonicalMatchEventTypeKey(rawType);
    if (typeKey != 'substitution') {
      continue;
    }

    final minute = supabaseInt(event['minute']) ?? 0;
    final int? inId = supabaseInt(event['player_id1']);
    final int? outId = supabaseInt(event['player_id2']);

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
    final typeKey = canonicalMatchEventTypeKey(rawType);
    final String? note = event['note'] as String?;
    if (typeKey == 'statuschange' &&
        note != null &&
        note.toLowerCase().contains('final')) {
      final minute = supabaseInt(event['minute']) ?? 0;
      finishedMinute = minute;
    }
  }

  if (finishedMinute != null) {
    return finishedMinute;
  }

  int maxMinute = 0;
  for (final event in state.events) {
    final minute = supabaseInt(event['minute']) ?? 0;
    if (minute > maxMinute) {
      maxMinute = minute;
    }
  }

  if (maxMinute > 0) {
    return maxMinute;
  }

  return 70;
}
