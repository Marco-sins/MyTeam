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
import 'package:football_manager/core/theme/app_responsive.dart';
import 'package:football_manager/core/utils/supabase_dynamic.dart';
import 'package:football_manager/presentation/match/utils/player_event_rating_settings_store.dart';
import 'package:football_manager/presentation/common/widgets/player_name_text.dart';
import 'package:football_manager/presentation/match/cubit/match_stats_cubit.dart';
import 'package:football_manager/presentation/match/cubit/player_event_rating_settings_cubit.dart';
import 'package:football_manager/presentation/match/widgets/match_field_with_formation.dart';
import 'package:football_manager/presentation/match/widgets/match_live_stats_panel.dart';
import 'package:football_manager/presentation/match/widgets/match_stats_events_widgets.dart';
import 'package:football_manager/presentation/match/widgets/match_stats_lineup_section.dart';
import 'package:football_manager/presentation/player/widgets/player_avatar.dart';
import 'package:football_manager/presentation/match/utils/player_rating_utils.dart';
import 'package:football_manager/core/theme/team_brand_theme.dart';
import 'package:football_manager/presentation/team/cubit/team_context_cubit.dart';

/// Tono para acciones guardadas como [statusChange] + nota (datos anteriores al enum dedicado).
/// Lo hace buscando palabras clave en la etiqueta para decidir el color.
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

/// Etiqueta localizada del estado del partido.
/// Lo hace usando un switch sobre [MatchStatus].
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

/// Localiza notas historicas de cambio de tiempo.
/// Lo hace comparando el texto normalizado con frases conocidas.
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

/// Contadores agregados para estadisticas del partido.
class _MatchEventCounters {
  final int shotsOur;
  final int shotsRival;
  final int foulsOur;
  final int foulsRival;
  final int cornersOur;
  final int cornersRival;
  final int offsidesOur;
  final int offsidesRival;
  final int yellowCardsOur;
  final int yellowCardsRival;
  final int redCardsOur;
  final int redCardsRival;

  const _MatchEventCounters({
    required this.shotsOur,
    required this.shotsRival,
    required this.foulsOur,
    required this.foulsRival,
    required this.cornersOur,
    required this.cornersRival,
    required this.offsidesOur,
    required this.offsidesRival,
    required this.yellowCardsOur,
    required this.yellowCardsRival,
    required this.redCardsOur,
    required this.redCardsRival,
  });
}

/// Calcula contadores basicos para el panel de estadisticas.
/// Lo hace recorriendo eventos y sumando por tipo canonico.
_MatchEventCounters _calculateMatchEventCounters(
  List<Map<String, dynamic>> events,
) {
  var shotsOur = 0;
  var shotsRival = 0;
  var foulsOur = 0;
  var foulsRival = 0;
  var cornersOur = 0;
  var cornersRival = 0;
  var offsidesOur = 0;
  var offsidesRival = 0;
  var yellowCardsOur = 0;
  var yellowCardsRival = 0;
  var redCardsOur = 0;
  var redCardsRival = 0;

  for (final event in events) {
    final key = canonicalMatchEventTypeKey(event['type']);
    switch (key) {
      case 'shot':
        shotsOur++;
        break;
      case 'scoregoal':
        shotsOur++;
        break;
      case 'rivalshot':
        shotsRival++;
        break;
      case 'concedegoal':
      case 'owngoal':
        shotsRival++;
        break;
      case 'foul':
        foulsOur++;
        break;
      case 'rivalfoul':
        foulsRival++;
        break;
      case 'corner':
        cornersOur++;
        break;
      case 'rivalcorner':
        cornersRival++;
        break;
      case 'offside':
        offsidesOur++;
        break;
      case 'rivaloffside':
        offsidesRival++;
        break;
      case 'yellowcard':
        yellowCardsOur++;
        break;
      case 'rivalyellowcard':
        yellowCardsRival++;
        break;
      case 'redcard':
        redCardsOur++;
        break;
      case 'rivalredcard':
        redCardsRival++;
        break;
      default:
        break;
    }
  }

  return _MatchEventCounters(
    shotsOur: shotsOur,
    shotsRival: shotsRival,
    foulsOur: foulsOur,
    foulsRival: foulsRival,
    cornersOur: cornersOur,
    cornersRival: cornersRival,
    offsidesOur: offsidesOur,
    offsidesRival: offsidesRival,
    yellowCardsOur: yellowCardsOur,
    yellowCardsRival: yellowCardsRival,
    redCardsOur: redCardsOur,
    redCardsRival: redCardsRival,
  );
}

/// Indica si un statuschange es un cambio de tiempo valido.
/// Lo hace comparando la nota con frases de inicio/descanso/fin.
bool _isTimeChangeStatusEventForLimitedView(Map<String, dynamic> event) {
  final key = canonicalMatchEventTypeKey(event['type']);
  if (key != 'statuschange') return false;
  final note = (event['note'] as String?)?.trim().toLowerCase() ?? '';
  const allowed = {
    'inicio 1ª parte',
    'inicio 1a parte',
    'descanso',
    'inicio 2ª parte',
    'inicio 2a parte',
    'final del partido',
  };
  return allowed.contains(note);
}

/// Filtra eventos visibles para roles sin permisos de admin.
/// Lo hace dejando solo tiempos, cambios, goles, faltas y tarjetas.
bool _shouldIncludeEventForLimitedView(Map<String, dynamic> event) {
  final key = canonicalMatchEventTypeKey(event['type']);
  if (key == 'statuschange') {
    return _isTimeChangeStatusEventForLimitedView(event);
  }
  if (key == 'substitution') {
    return (supabaseInt(event['minute']) ?? 0) > 0;
  }
  return key == 'scoregoal' ||
      key == 'concedegoal' ||
      key == 'owngoal' ||
      key == 'foul' ||
      key == 'rivalfoul' ||
      key == 'yellowcard' ||
      key == 'redcard';
}

/// Pantalla de estadisticas y linea temporal del partido.
/// Mapea eventos a widgets y muestra formacion final.
class MatchStatsPage extends StatelessWidget {
  const MatchStatsPage({super.key, required this.match});

  final Match match;

  /// Devuelve el widget adecuado para un evento de partido.
  /// Lo hace normalizando el tipo y creando el item correspondiente.
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
    final double? eventPoint = (event['point'] as num?)?.toDouble();
    final points =
        eventPoint ??
        PlayerEventRatingSettingsStore.instance.pointsForKey(typeKey);

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
        return MatchStatusChangeItem(
          label: label,
          minute: minute,
          pointsDelta: points,
        );
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
          pointsDelta: points,
        );
      }
      return MatchStatusChangeItem(
        label: noteLabel,
        minute: minute,
        pointsDelta: points,
      );
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
        pointsDelta: points,
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

      final totalPoints =
          eventPoint ??
          PlayerEventRatingSettingsStore.instance.pointsForKey('scoregoal');
      return MatchGoalItem(
        minute: minute,
        isOurGoal: isOurGoal,
        isAgainstGoal: isAgainstGoal,
        isOwnGoal: isOwnGoal,
        scorerPlayer: scorerPlayer,
        assistPlayer: assistPlayer,
        pointsDelta: totalPoints,
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
          pointsDelta: points,
        );
      }
      return MatchStatusChangeItem(
        label: noteRaw.isNotEmpty ? noteRaw : l10n.matchLiveSaveOnly,
        minute: minute,
        pointsDelta: points,
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
          pointsDelta: points,
        );
      }
      return MatchStatusChangeItem(
        label: headline,
        minute: minute,
        pointsDelta: points,
      );
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
          pointsDelta: points,
        );
      }
      return MatchStatusChangeItem(
        label: headline,
        minute: minute,
        pointsDelta: points,
      );
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
          pointsDelta: points,
        );
      }
      return MatchStatusChangeItem(
        label: headline,
        minute: minute,
        pointsDelta: points,
      );
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
          pointsDelta: points,
        );
      }
      return MatchStatusChangeItem(
        label: headline,
        minute: minute,
        pointsDelta: points,
      );
    }

    if (typeKey == 'rivalshot') {
      return MatchStatusChangeItem(
        minute: minute,
        label: l10n.matchEventRivalShot,
        pointsDelta: points,
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
          pointsDelta: points,
        );
      }
      return MatchStatusChangeItem(
        label: headline,
        minute: minute,
        pointsDelta: points,
      );
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
          pointsDelta: points,
        );
      }
      return MatchStatusChangeItem(
        label: headline,
        minute: minute,
        pointsDelta: points,
      );
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
          pointsDelta: points,
        );
      }
      return MatchStatusChangeItem(
        label: headline,
        minute: minute,
        pointsDelta: points,
      );
    }

    if (typeKey == 'yellowcard' || typeKey == 'redcard') {
      final isRed = typeKey == 'redcard';
      final player = playerId1 != null ? state.playersById[playerId1] : null;
      return MatchCardItem(
        minute: minute,
        player: player,
        fallbackPlayerId: playerId1,
        isRed: isRed,
        pointsDelta: points,
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
          pointsDelta: points,
        );
      }
      return MatchStatusChangeItem(
        label: noteFallback,
        minute: minute,
        pointsDelta: points,
      );
    }

    return null;
  }

  /// Construye la UI con estados de carga, error y contenido.
  /// Lo hace reaccionando al estado del [MatchStatsCubit].
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;
    final s = context.layoutScale;

    final dateText =
        '${match.date.day.toString().padLeft(2, '0')}/${match.date.month.toString().padLeft(2, '0')} · '
        '${match.date.hour.toString().padLeft(2, '0')}:${match.date.minute.toString().padLeft(2, '0')}';

    final authState = context.read<AuthCubit>().state;
    UserRole? role;
    if (authState is Authenticated) {
      role = authState.user.teamRoles[match.teamId];
    }
    final isExternal = role == UserRole.external;
    final canSeeAllEvents = role?.hasAdminPrivileges ?? false;
    TeamContextCubit? teamCubit;
    try {
      teamCubit = BlocProvider.of<TeamContextCubit>(context, listen: false);
    } catch (_) {
      teamCubit = null;
    }

    final content =
        BlocListener<
          PlayerEventRatingSettingsCubit,
          PlayerEventRatingSettingsState
        >(
          listenWhen: (previous, current) => previous.rules != current.rules,
          listener: (context, state) {
            context.read<MatchStatsCubit>().load();
          },
          child: DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                title: Text(l10n.screenMatchDetail),
                centerTitle: true,
              ),
              body: SafeArea(
                top: false,
                child: BlocBuilder<MatchStatsCubit, MatchStatsState>(
                  builder: (context, state) {
                    final loadingWidget = Center(
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

                    if (state.isLoading) {
                      return Column(
                        children: [
                          Material(
                            color: scheme.surface,
                            child: const TabBar(
                              tabs: [
                                Tab(text: 'Principal'),
                                Tab(text: 'Estadisticas'),
                                Tab(text: 'Eventos'),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                loadingWidget,
                                loadingWidget,
                                loadingWidget,
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    if (state.error != null) {
                      final errorWidget = Center(
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
                      return Column(
                        children: [
                          Material(
                            color: scheme.surface,
                            child: const TabBar(
                              tabs: [
                                Tab(text: 'Principal'),
                                Tab(text: 'Estadisticas'),
                                Tab(text: 'Eventos'),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [errorWidget, errorWidget, errorWidget],
                            ),
                          ),
                        ],
                      );
                    }

                    final bool showLineupSection =
                        match.status == MatchStatus.finished &&
                        (state.startingPlayers.isNotEmpty ||
                            state.substitutePlayers.isNotEmpty);

                    final counters = _calculateMatchEventCounters(state.events);

                    final eventTiles = <Widget>[];
                    for (final e in state.events) {
                      if (!canSeeAllEvents) {
                        if (!MatchLiveTimelineFilter.shouldIncludeChronologyMap(
                          e,
                        )) {
                          continue;
                        }
                        if (!_shouldIncludeEventForLimitedView(e)) {
                          continue;
                        }
                      }
                      final tile = _eventTile(context, state, e);
                      if (tile != null) {
                        eventTiles.add(tile);
                      }
                    }

                    final scoreSubtitle = match.status == MatchStatus.finished
                        ? l10n.matchStatsScoreFinal
                        : l10n.matchStatsScoreLive;

                    final principalList = ListView(
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
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                14,
                                12,
                                16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (state.formationLabel != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
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
                                          backgroundColor: scheme
                                              .secondaryContainer
                                              .withValues(alpha: 0.55),
                                          side: BorderSide.none,
                                        ),
                                      ),
                                    )
                                  else
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
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
                                            MediaQuery.sizeOf(context).width -
                                            32,
                                      ),
                                      child: MatchFieldWithFormation(
                                        formationLines: state.formationLines,
                                        formationLayoutKey:
                                            state.formationLabel,
                                        positionPlayers:
                                            state.fieldPositionPlayers,
                                        selectedPlayer: null,
                                        sentOffPlayerIds:
                                            state.sentOffPlayerIds,
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

                    final statsList = ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      children: [
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: MatchLiveStatsPanel(
                            layoutScale: s,
                            readOnly: true,
                            shotsOur: counters.shotsOur,
                            shotsRival: counters.shotsRival,
                            foulsOur: counters.foulsOur,
                            foulsRival: counters.foulsRival,
                            cornersOur: counters.cornersOur,
                            cornersRival: counters.cornersRival,
                            offsidesOur: counters.offsidesOur,
                            offsidesRival: counters.offsidesRival,
                            yellowCardsOur: counters.yellowCardsOur,
                            yellowCardsRival: counters.yellowCardsRival,
                            redCardsOur: counters.redCardsOur,
                            redCardsRival: counters.redCardsRival,
                            l10n: l10n,
                          ),
                        ),
                      ],
                    );

                    final eventsList = ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      children: [
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
                                    color: scheme.outline.withValues(
                                      alpha: 0.85,
                                    ),
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
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                14,
                                12,
                                14,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (
                                    var i = 0;
                                    i < eventTiles.length;
                                    i++
                                  ) ...[
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
                      ],
                    );

                    return Column(
                      children: [
                        Material(
                          color: scheme.surface,
                          child: const TabBar(
                            tabs: [
                              Tab(text: 'Principal'),
                              Tab(text: 'Estadisticas'),
                              Tab(text: 'Eventos'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [principalList, statsList, eventsList],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );

    if (teamCubit == null) {
      return content;
    }

    return TeamBrandedScope(team: teamCubit.state, child: content);
  }
}

/// Tarjeta resumen con fecha, estado y marcador.
/// Recibe datos ya formateados para no recalcular en build.
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

  /// Construye la tarjeta resumen del partido.
  /// Lo hace componiendo cabecera, chips y marcador.
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
                    Chip(
                      label: Text(
                        match.isHome ? homeVenueLabel : awayVenueLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: scheme.secondaryContainer.withValues(
                        alpha: 0.55,
                      ),
                      side: BorderSide.none,
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        statusLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

/// Encabezado de seccion con icono y titulo.
/// Lo hace con un Row simple y tipografia destacada.
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

  /// Construye el encabezado de seccion.
  /// Lo hace alineando icono y texto.
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

/// DTO con estadisticas individuales calculadas.
/// Se usa para mostrar el modal de detalle por jugador.
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

class _PlayerMatchAction {
  const _PlayerMatchAction({
    required this.minute,
    required this.label,
    required this.points,
    required this.icon,
    required this.color,
    this.detail,
  });

  final int minute;
  final String label;
  final String? detail;
  final double points;
  final IconData icon;
  final Color color;
}

List<Map<String, dynamic>> _sortedMatchEventsForPlayer(
  List<Map<String, dynamic>> events,
) {
  final indexed = events.asMap().entries.toList();
  indexed.sort((a, b) {
    final ma = supabaseInt(a.value['minute']) ?? 0;
    final mb = supabaseInt(b.value['minute']) ?? 0;
    if (ma != mb) return ma.compareTo(mb);
    return a.key.compareTo(b.key);
  });
  return indexed.map((entry) => entry.value).toList();
}

List<_PlayerMatchAction> _collectPlayerMatchActions(
  BuildContext context,
  MatchStatsState state,
  Player player,
) {
  final scheme = Theme.of(context).colorScheme;
  final actions = <_PlayerMatchAction>[];
  final playerId = player.id;

  void addAction({
    required int minute,
    required String label,
    required double points,
    required IconData icon,
    required Color color,
    String? detail,
  }) {
    actions.add(
      _PlayerMatchAction(
        minute: minute,
        label: label,
        detail: detail,
        points: points,
        icon: icon,
        color: color,
      ),
    );
  }

  // Iterar sobre TODOS los eventos, incluyendo aquellos del rival.
  // Filtrar por player después.
  for (final event in _sortedMatchEventsForPlayer(state.events)) {
    final rawType = event['type'];
    if (rawType == null) continue;

    final typeKey = canonicalMatchEventTypeKey(rawType);
    final minute = supabaseInt(event['minute']) ?? 0;
    final int? p1 = supabaseInt(event['player_id1']);
    final int? p2 = supabaseInt(event['player_id2']);
    final String? note = (event['note'] as String?)?.trim();
    final double? eventPoint = (event['point'] as num?)?.toDouble();

    // Eventos de gol (scorer y asistente)
    if (typeKey == 'scoregoal') {
      if (p1 == playerId) {
        addAction(
          minute: minute,
          label: 'Gol',
          points:
              eventPoint ??
              PlayerEventRatingSettingsStore.instance.pointsForKey('scoregoal'),
          icon: Icons.sports_soccer_rounded,
          color: scheme.primary,
          detail: p2 != null ? 'Con asistencia' : null,
        );
      }
      if (p2 == playerId) {
        addAction(
          minute: minute,
          label: 'Asistencia',
          points:
              eventPoint ??
              PlayerEventRatingSettingsStore.instance.pointsForKey('assist'),
          icon: Icons.directions_run_rounded,
          color: scheme.tertiary,
          detail: 'En gol',
        );
      }
      continue;
    }

    // Eventos de sustitución (entra/sale del campo)
    if (typeKey == 'substitution') {
      if (p1 == playerId) {
        addAction(
          minute: minute,
          label: 'Sustitución',
          points:
              eventPoint ??
              PlayerEventRatingSettingsStore.instance.pointsForKey(
                'substitution',
              ),
          icon: Icons.trending_up_rounded,
          color: scheme.primary,
          detail: 'Entra al campo',
        );
      }
      if (p2 == playerId) {
        addAction(
          minute: minute,
          label: 'Sustitución',
          points:
              eventPoint ??
              PlayerEventRatingSettingsStore.instance.pointsForKey(
                'substitution',
              ),
          icon: Icons.trending_down_rounded,
          color: scheme.error,
          detail: 'Sale del campo',
        );
      }
      continue;
    }

    // Acciones históricas (cambios de estado con notas antiguas).
    // Ignoramos resúmenes agregados (ej: "3 tiros", "2 buenos pases") y
    // mostramos solo acciones unitarias para mantener cronología real.
    if (typeKey == 'statuschange') {
      if (p1 != playerId || note == null || note.isEmpty) continue;
      final normalizedNote = note.toLowerCase().trim();
      final isLegacySingleAction =
          normalizedNote == 'gol' ||
          normalizedNote == 'asistencia' ||
          normalizedNote == 'tiro' ||
          normalizedNote == 'buen pase' ||
          normalizedNote == 'mal pase' ||
          normalizedNote == 'buena jugada' ||
          normalizedNote == 'mala jugada' ||
          normalizedNote == 'falta' ||
          normalizedNote == 'tarjeta amarilla' ||
          normalizedNote == 'tarjeta roja' ||
          normalizedNote == 'cantada' ||
          normalizedNote == 'fuera de juego' ||
          normalizedNote == 'gol en propia' ||
          normalizedNote == 'gol encajado' ||
          normalizedNote == 'buena parada' ||
          normalizedNote == 'recuperacion' ||
          normalizedNote == 'recuperación' ||
          normalizedNote == 'pase clave';

      if (!isLegacySingleAction) {
        continue;
      }

      final accent = _accentForLegacyStatusActionNote(scheme, note);
      addAction(
        minute: minute,
        label: note,
        points:
            eventPoint ??
            PlayerEventRatingSettingsStore.instance.pointsForKey(typeKey),
        icon: accent == scheme.error
            ? Icons.remove_circle_outline_rounded
            : Icons.check_circle_outline_rounded,
        color: accent,
        detail: 'Acción',
      );
      continue;
    }

    // Tarjetas (amarilla/roja) - pueden ocurrir a cualquier jugador
    if (typeKey == 'yellowcard' || typeKey == 'redcard') {
      if (p1 == playerId) {
        final isRed = typeKey == 'redcard';
        addAction(
          minute: minute,
          label: isRed ? 'Tarjeta roja' : 'Tarjeta amarilla',
          points:
              eventPoint ??
              PlayerEventRatingSettingsStore.instance.pointsForKey(typeKey),
          icon: isRed ? Icons.square_rounded : Icons.rectangle_rounded,
          color: isRed ? scheme.error : Colors.amber.shade600,
          detail: null,
        );
      }
      continue;
    }

    // Resto de eventos: solo aplican al player_id1
    if (p1 != playerId) {
      continue;
    }

    final actionLabel = switch (typeKey) {
      'goodpass' => 'Buen pase',
      'badpass' => 'Mal pase',
      'goodplay' => 'Buena jugada',
      'badplay' => 'Mala jugada',
      'ballrecovery' => 'Recuperación',
      'goodsave' => 'Buena parada',
      'shot' => 'Tiro',
      'keypass' => 'Pase clave',
      'foul' => 'Falta',
      'cantada' => 'Cantada',
      'owngoal' => 'Gol en propia',
      'concedegoal' => 'Gol encajado',
      'offside' => 'Fuera de juego',
      _ => note?.isNotEmpty == true ? note! : typeKey,
    };

    final actionColor = switch (typeKey) {
      'goodpass' ||
      'goodplay' ||
      'ballrecovery' ||
      'goodsave' ||
      'shot' ||
      'keypass' => scheme.tertiary,
      'yellowcard' ||
      'redcard' ||
      'badpass' ||
      'badplay' ||
      'foul' ||
      'cantada' ||
      'owngoal' ||
      'concedegoal' ||
      'offside' => scheme.error,
      _ => scheme.primary,
    };

    final actionIcon = switch (typeKey) {
      'goodpass' => Icons.check_circle_outline_rounded,
      'badpass' => Icons.cancel_outlined,
      'goodplay' => Icons.thumb_up_outlined,
      'badplay' => Icons.thumb_down_outlined,
      'ballrecovery' => Icons.replay_circle_filled_rounded,
      'goodsave' => Icons.safety_check_rounded,
      'shot' => Icons.sports_soccer_rounded,
      'keypass' => Icons.auto_awesome_rounded,
      'foul' => Icons.report_problem_outlined,
      'cantada' => Icons.warning_amber_rounded,
      'owngoal' => Icons.sports_soccer_rounded,
      'concedegoal' => Icons.sports_soccer_rounded,
      'offside' => Icons.directions_run_rounded,
      _ => Icons.bolt_rounded,
    };

    final actionPoints =
        eventPoint ??
        PlayerEventRatingSettingsStore.instance.pointsForKey(typeKey);

    addAction(
      minute: minute,
      label: actionLabel,
      points: actionPoints,
      icon: actionIcon,
      color: actionColor,
      detail: note?.isNotEmpty == true ? note : null,
    );
  }

  return actions;
}

/// Muestra un dialogo con estadisticas del jugador.
/// Lo hace calculando stats y renderizando un AlertDialog.
Future<void> _showPlayerMatchStats(
  BuildContext context,
  MatchStatsState state,
  Player player,
) async {
  final stats = _calculatePlayerMatchStats(state, player);
  final actions = _collectPlayerMatchActions(context, state, player);
  final rating =
      state.playerRatings[player.id] ??
      calculatePlayerRating(player.id, state.events);
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final textTheme = theme.textTheme;
  final l10n = AppLocalizations.of(context)!;

  final actionCountByLabel = <String, int>{};
  final actionPointsByLabel = <String, double>{};
  for (final action in actions) {
    actionCountByLabel.update(
      action.label,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
    actionPointsByLabel.update(
      action.label,
      (value) => value + action.points,
      ifAbsent: () => action.points,
    );
  }

  String _summaryLabel(String label, int count) {
    final lower = label.toLowerCase().trim();
    if (count == 1) return lower;
    return switch (lower) {
      'tiro' => 'tiros',
      'buen pase' => 'buenos pases',
      'mal pase' => 'malos pases',
      'buena jugada' => 'buenas jugadas',
      'mala jugada' => 'malas jugadas',
      'asistencia' => 'asistencias',
      'gol' => 'goles',
      'falta' => 'faltas',
      'cantada' => 'cantadas',
      'tarjeta amarilla' => 'tarjetas amarillas',
      'tarjeta roja' => 'tarjetas rojas',
      'fuera de juego' => 'fuera de juego',
      'sustitución' => 'sustituciones',
      _ => '${lower}s',
    };
  }

  bool _isNegativeAction(String label) {
    final lower = label.toLowerCase().trim();
    return lower == 'mal pase' ||
        lower == 'mala jugada' ||
        lower == 'falta' ||
        lower == 'cantada' ||
        lower == 'tarjeta amarilla' ||
        lower == 'tarjeta roja' ||
        lower == 'fuera de juego' ||
        lower == 'gol en propia' ||
        lower == 'gol encajado';
  }

  bool _isPositiveAction(String label) {
    final lower = label.toLowerCase().trim();
    return lower == 'gol' ||
        lower == 'asistencia' ||
        lower == 'tiro' ||
        lower == 'buen pase' ||
        lower == 'buena jugada' ||
        lower == 'buena parada' ||
        lower == 'recuperación' ||
        lower == 'recuperacion' ||
        lower == 'pase clave';
  }

  const summaryOrder = <String>[
    'Tiro',
    'Buen pase',
    'Mal pase',
    'Buena jugada',
    'Mala jugada',
    'Gol',
    'Asistencia',
    'Falta',
    'Tarjeta amarilla',
    'Tarjeta roja',
    'Cantada',
    'Fuera de juego',
    'Sustitución',
  ];

  final summaryEntries = actionCountByLabel.entries.toList()
    ..sort((a, b) {
      final ai = summaryOrder.indexWhere(
        (x) => x.toLowerCase() == a.key.toLowerCase(),
      );
      final bi = summaryOrder.indexWhere(
        (x) => x.toLowerCase() == b.key.toLowerCase(),
      );
      final aRank = ai == -1 ? 999 : ai;
      final bRank = bi == -1 ? 999 : bi;
      if (aRank != bRank) return aRank.compareTo(bRank);
      return a.key.toLowerCase().compareTo(b.key.toLowerCase());
    });

  String _pointsText(double value) {
    final rounded = value.abs().toStringAsFixed(1);
    if (value > 0) return '+$rounded';
    if (value < 0) return '-$rounded';
    return '0.0';
  }

  Color ratingColor(double value) {
    if (value <= 5.0) {
      final t = value / 5.0;
      return Color.lerp(Colors.red, Colors.amber, t)!;
    }
    final t = (value - 5.0) / 5.0;
    return Color.lerp(Colors.amber, Colors.blue, t)!;
  }

  Widget metricChip({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (color ?? scheme.primary).withValues(alpha: 0.14),
            ),
            child: Icon(icon, size: 18, color: color ?? scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      final maxDialogHeight = MediaQuery.sizeOf(ctx).height * 0.88;
      final ratingBg = ratingColor(rating.clamp(0.0, 10.0));
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: maxDialogHeight,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.surface,
                    scheme.surfaceContainerLow.withValues(alpha: 0.92),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.primaryContainer.withValues(alpha: 0.95),
                          scheme.secondaryContainer.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        PlayerAvatar(player: player, radius: 42),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                player.fullName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: scheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.matchStatusFinished,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: scheme.onPrimaryContainer.withValues(
                                    alpha: 0.85,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ratingBg,
                            boxShadow: [
                              BoxShadow(
                                color: ratingBg.withValues(alpha: 0.28),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                rating.toStringAsFixed(1),
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  height: 1,
                                ),
                              ),
                              Text(
                                'rating',
                                style: textTheme.labelSmall?.copyWith(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: metricChip(
                                  icon: Icons.timer_outlined,
                                  label: l10n.matchStatsMinutesPlayed,
                                  value: '${stats.minutesPlayed}',
                                  color: scheme.tertiary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: metricChip(
                                  icon: Icons.emoji_events_outlined,
                                  label: 'Puntuación',
                                  value: rating.toStringAsFixed(1),
                                  color: ratingBg,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          metricChip(
                            icon: Icons.list_alt_rounded,
                            label: 'Acciones registradas',
                            value: '${actions.length}',
                            color: scheme.tertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Resumen de acciones',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (summaryEntries.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: Text(
                                'No se registraron acciones de este jugador en el partido.',
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (
                                  int i = 0;
                                  i < summaryEntries.length;
                                  i++
                                ) ...[
                                  if (i > 0) const SizedBox(height: 8),
                                  Builder(
                                    builder: (_) {
                                      final entry = summaryEntries[i];
                                      final label = entry.key;
                                      final count = entry.value;
                                      final totalPoints =
                                          actionPointsByLabel[label] ?? 0;
                                      final isNegative = _isNegativeAction(
                                        label,
                                      );
                                      final isPositive = _isPositiveAction(
                                        label,
                                      );

                                      final bgColor = isNegative
                                          ? Colors.red.shade50
                                          : isPositive
                                          ? Colors.green.shade50
                                          : scheme.surfaceContainerHighest
                                                .withValues(alpha: 0.55);

                                      final borderColor = isNegative
                                          ? Colors.red.shade200
                                          : isPositive
                                          ? Colors.green.shade200
                                          : scheme.outlineVariant.withValues(
                                              alpha: 0.45,
                                            );

                                      final textColor = isNegative
                                          ? Colors.red.shade900
                                          : isPositive
                                          ? Colors.green.shade900
                                          : scheme.onSurface;

                                      final icon = isNegative
                                          ? Icons.trending_down_rounded
                                          : isPositive
                                          ? Icons.trending_up_rounded
                                          : Icons.circle_outlined;

                                      final labelStyle = textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: textColor,
                                            height: 1.15,
                                          );

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: bgColor,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: borderColor,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 30,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: textColor.withValues(
                                                  alpha: 0.09,
                                                ),
                                              ),
                                              child: Icon(
                                                icon,
                                                size: 16,
                                                color: textColor,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                '$count ${_summaryLabel(label, count)}',
                                                style: labelStyle,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: textColor.withValues(
                                                  alpha: 0.08,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                _pointsText(totalPoints),
                                                style: textTheme.labelMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: textColor,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Divider(
                            height: 1,
                            color: scheme.outlineVariant.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonal(
                              onPressed: () => Navigator.of(ctx).pop(),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: Text(l10n.dialogClose),
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
        ),
      );
    },
  );
}

/// Calcula goles, asistencias y acciones del jugador.
/// Lo hace recorriendo eventos y sumando contadores.
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
    } else if (isBadPass || note == 'Mal pase' || note == 'Pase impreciso') {
      badPasses++;
    } else if (note == 'Pase clave' || typeKey == 'keypass') {
      goodPlays++;
    } else if (isGoodPlay ||
        isBallRecovery ||
        typeKey == 'shot' ||
        typeKey == 'goodsave' ||
        note == 'Buena jugada' ||
        note == 'Recuperación' ||
        note == 'Balón recuperado' ||
        note == 'Buena parada' ||
        note == 'Tiro' ||
        note == 'Buen tiro' ||
        note == 'Recupera posesión' ||
        note == 'Gana posesión') {
      goodPlays++;
    } else if (isBadPlay ||
        typeKey == 'foul' ||
        typeKey == 'cantada' ||
        note == 'Mala jugada' ||
        note == 'Jugada imprecisa' ||
        note == 'Falta' ||
        note == 'Cantada' ||
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

/// Calcula los minutos disputados a partir de sustituciones.
/// Lo hace ordenando eventos y acumulando tramos en campo.
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

/// Determina el minuto final del partido para calculos.
/// Lo hace buscando evento de fin o el maximo minuto.
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
