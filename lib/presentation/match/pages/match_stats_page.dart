import 'package:flutter/material.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/enum/match_status.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/entities/match.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/services/match_live_timeline_filter.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/core/utils/supabase_dynamic.dart';
import 'package:football_manager/presentation/common/widgets/player_name_text.dart';
import 'package:football_manager/core/theme/app_responsive.dart';
import 'package:football_manager/core/theme/team_brand_theme.dart';
import 'package:football_manager/presentation/match/cubit/match_stats_cubit.dart';
import 'package:football_manager/presentation/match/widgets/match_stats_events_widgets.dart';
import 'package:football_manager/presentation/match/widgets/match_field_with_formation.dart';

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

String _matchStatsNonEmptyName(String value, String placeholder) {
  final t = value.trim();
  return t.isNotEmpty ? t : placeholder;
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
  const MatchStatsPage({
    super.key,
    required this.match,
    required this.ourTeamName,
    this.teamColorHex,
  });

  final Match match;

  /// Nombre del club del usuario (debe coincidir con [Match.teamId]) para mostrar local/visitante.
  final String ourTeamName;

  /// Color de [Team.color]; si se pasa y el partido está finalizado, la pantalla usa el tono de equipo.
  final String? teamColorHex;

  Widget? _eventTile(
    BuildContext context,
    MatchStatsState state,
    Map<String, dynamic> event,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final rawType = event['type'];
    final typeKey = canonicalMatchEventTypeKey(rawType);
    final minute = resolveMatchEventMinute(Map<String, dynamic>.from(event));
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
      if (inId == null) {
        return null;
      }
      final inPlayer = state.playersById[inId];
      final outPlayer = outId != null ? state.playersById[outId] : null;
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
      final isAgainstGoal = typeKey == 'concedegoal' || typeKey == 'owngoal';

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

    if (typeKey == 'shot') {
      final player = playerId1 != null ? state.playersById[playerId1] : null;
      final scheme = Theme.of(context).colorScheme;
      final accentStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.primary,
      );
      final headline = l10n.matchActionLabelShot;
      if (player != null) {
        return MatchStatusChangeItem(
          minute: minute,
          label: headline,
          labelWidget: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: accentStyle,
              children: [
                TextSpan(text: '$headline · '),
                ...playerDorsalNameSpanList(player, accentStyle),
              ],
            ),
          ),
        );
      }
      return MatchStatusChangeItem(label: headline, minute: minute);
    }

    if (typeKey == 'rivalshot') {
      return MatchStatusChangeItem(
        minute: minute,
        label: l10n.matchEventRivalShot,
      );
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
      final accentColor = _accentForLegacyStatusActionNote(
        scheme,
        noteFallback,
      );
      final accentStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
        fontWeight: FontWeight.w600,
        color: accentColor,
      );
      final player = playerId1 != null ? state.playersById[playerId1] : null;
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
    final l10n = AppLocalizations.of(context)!;

    final dateText =
        '${match.date.day.toString().padLeft(2, '0')}/${match.date.month.toString().padLeft(2, '0')} · '
        '${match.date.hour.toString().padLeft(2, '0')}:${match.date.minute.toString().padLeft(2, '0')}';

    final authState = context.read<AuthCubit>().state;
    var isExternal = false;
    if (authState is Authenticated) {
      isExternal = authState.user.teamRoles[match.teamId] == UserRole.external;
    }

    final page = Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final textTheme = theme.textTheme;
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
                                CircularProgressIndicator(
                                  color: scheme.primary,
                                ),
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
                  if (!MatchLiveTimelineFilter.shouldIncludeChronologyMap(e)) {
                    continue;
                  }
                  final tile = _eventTile(context, state, e);
                  if (tile != null) {
                    eventTiles.add(tile);
                  }
                }

                final scoreSubtitle = match.status == MatchStatus.finished
                    ? l10n.matchStatsScoreFinal
                    : l10n.matchStatsScoreLive;

                final ph = 'Team';
                final homeTeamName = _matchStatsNonEmptyName(
                  match.isHome ? ourTeamName : match.opponent,
                  ph,
                );
                final awayTeamName = _matchStatsNonEmptyName(
                  match.isHome ? match.opponent : ourTeamName,
                  ph,
                );
                final homeGoals = match.isHome
                    ? match.goalsScored
                    : match.goalsConceded;
                final awayGoals = match.isHome
                    ? match.goalsConceded
                    : match.goalsScored;

                final s = context.layoutScale;
                final pagePad = AppResponsive.pageHorizontalPadding(context);
                final pageScrollPad = EdgeInsets.fromLTRB(
                  pagePad,
                  12 * s,
                  pagePad,
                  24 * s,
                );

                final principalSections = <Widget>[
                  _MatchSummaryCard(
                    dateText: dateText,
                    statusLabel: _matchStatusLabel(l10n, match.status),
                    scoreSubtitle: scoreSubtitle,
                    scheme: scheme,
                    textTheme: textTheme,
                    homeTeamName: homeTeamName,
                    awayTeamName: awayTeamName,
                    homeGoals: homeGoals,
                    awayGoals: awayGoals,
                    homeVenueLabel: l10n.matchVenueHome,
                    awayVenueLabel: l10n.matchVenueAway,
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
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: scheme.onSurface,
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
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.sizeOf(context).width - 32,
                                ),
                                child: MatchFieldWithFormation(
                                  formationLines: state.formationLines,
                                  formationLayoutKey: state.formationLabel,
                                  positionPlayers: state.fieldPositionPlayers,
                                  benchPlayers: state.substitutePlayers,
                                  selectedPlayer: null,
                                  sentOffPlayerIds: state.sentOffPlayerIds,
                                  currentPlayersOnField: () => state
                                      .fieldPositionPlayers
                                      .where((p) => p != null)
                                      .length,
                                  maxPlayersOnField: () =>
                                      state.fieldPositionPlayers.length,
                                  showSnack: (_, {bool error = false}) {},
                                  onLineupChanged:
                                      (
                                        _, {
                                        required bool logSubstitutionEvent,
                                        Player? substitutionIn,
                                        Player? substitutionOut,
                                      }) {},
                                  onPlayerActionRequested: (_) {},
                                  readOnly: true,
                                  playerDiscipline: (playerId) {
                                    if (state.sentOffPlayerIds.contains(
                                      playerId,
                                    )) {
                                      return MatchPlayerDisciplineHighlight.red;
                                    }
                                    final yellows =
                                        state.yellowCardsByPlayerId[playerId] ??
                                        0;
                                    if (yellows > 0) {
                                      return MatchPlayerDisciplineHighlight
                                          .yellow;
                                    }
                                    return MatchPlayerDisciplineHighlight.none;
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (showLineupSection) ...[
                    const SizedBox(height: 20),
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Lineup',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount:
                                  state.startingPlayers.length +
                                  state.substitutePlayers.length,
                              separatorBuilder: (_, _) => const Divider(),
                              itemBuilder: (_, index) {
                                final isStarter =
                                    index < state.startingPlayers.length;
                                final player = isStarter
                                    ? state.startingPlayers[index]
                                    : state.substitutePlayers[index -
                                          state.startingPlayers.length];
                                final rating = state.playerRatings[player.id];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: PlayerNameText(
                                          player: player,
                                          mode: PlayerNameTextMode.general,
                                        ),
                                      ),
                                      if (!isExternal && rating != null) ...[
                                        const SizedBox(width: 8),
                                        Chip(
                                          label: Text(
                                            rating.toStringAsFixed(1),
                                            style: textTheme.labelSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          avatar: Icon(
                                            Icons.star_rounded,
                                            size: 14,
                                            color: scheme.primary,
                                          ),
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ];
                final eventsSections = <Widget>[
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
                ];
                return RefreshIndicator(
                  onRefresh: () async {
                    await context.read<MatchStatsCubit>().load();
                  },
                  child: SingleChildScrollView(
                    padding: pageScrollPad,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...principalSections,
                        if (eventsSections.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          ...eventsSections,
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (match.status == MatchStatus.finished) {
      final brandHex = teamColorHex;
      if (brandHex != null && brandHex.isNotEmpty) {
        return Theme(data: TeamBrandTheme.wrap(context, brandHex), child: page);
      }
    }
    return page;
  }
}

class _MatchSummaryCard extends StatelessWidget {
  const _MatchSummaryCard({
    required this.dateText,
    required this.statusLabel,
    required this.scoreSubtitle,
    required this.scheme,
    required this.textTheme,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeGoals,
    required this.awayGoals,
    required this.homeVenueLabel,
    required this.awayVenueLabel,
  });

  final String dateText;
  final String statusLabel;
  final String scoreSubtitle;
  final ColorScheme scheme;
  final TextTheme textTheme;
  final String homeTeamName;
  final String awayTeamName;
  final int homeGoals;
  final int awayGoals;
  final String homeVenueLabel;
  final String awayVenueLabel;

  @override
  Widget build(BuildContext context) {
    final label = '$homeTeamName $homeGoals — $awayTeamName $awayGoals';
    final w = MediaQuery.sizeOf(context).width;
    final nameStyle = textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
      height: 1.25,
      letterSpacing: -0.35,
    );
    final roleStyle = textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.9,
    );
    final scoreStyle =
        (w < 360 ? textTheme.displaySmall : textTheme.displayMedium)?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
          height: 1.02,
          letterSpacing: -0.5,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
    return Semantics(
      label: label,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    height: 40,
                    margin: const EdgeInsets.only(top: 2, right: 12),
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateText,
                          style: textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                            letterSpacing: 0.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.sports_soccer_rounded,
                    size: 22,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(
                height: 1,
                thickness: 0.5,
                color: scheme.outlineVariant.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 28),
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('$homeGoals', style: scoreStyle),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '∶',
                          style: textTheme.headlineSmall?.copyWith(
                            color: scheme.outline.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w200,
                            height: 1.1,
                          ),
                        ),
                      ),
                      Text('$awayGoals', style: scoreStyle),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  scoreSubtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          homeTeamName,
                          textAlign: TextAlign.end,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: nameStyle,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          homeVenueLabel.toUpperCase(),
                          textAlign: TextAlign.end,
                          style: roleStyle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          awayTeamName,
                          textAlign: TextAlign.start,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: nameStyle,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          awayVenueLabel.toUpperCase(),
                          textAlign: TextAlign.start,
                          style: roleStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
