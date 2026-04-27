import 'package:flutter/material.dart';
import 'package:football_manager/domain/entities/enum/match_event_enum.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/presentation/match/widgets/match_live_stats_panel.dart';
import 'package:football_manager/presentation/match/widgets/match_manager_ui_policy.dart';

List<Widget> buildMatchManagerStatsTabSections({
  required MatchManagerUiPolicy policy,
  required double layoutScale,
  required AppLocalizations l10n,
  required int shotsOur,
  required int shotsRival,
  required int foulsOur,
  required int foulsRival,
  required int cornersOur,
  required int cornersRival,
  required int offsidesOur,
  required int offsidesRival,
  required int yellowOur,
  required int yellowRival,
  required int redOur,
  required int redRival,
  required void Function(MatchEventEnum type) removeLastOfType,
  required void Function(MatchEventEnum type, String note) saveManualCounterEvent,
}) {
  return [
    const SizedBox(height: 12),
    Card(
      clipBehavior: Clip.antiAlias,
      child: MatchLiveStatsPanel(
        layoutScale: layoutScale,
        readOnly: policy.readOnlyMatchActions,
        shotsOur: shotsOur,
        shotsRival: shotsRival,
        foulsOur: foulsOur,
        foulsRival: foulsRival,
        cornersOur: cornersOur,
        cornersRival: cornersRival,
        offsidesOur: offsidesOur,
        offsidesRival: offsidesRival,
        yellowOur: yellowOur,
        yellowRival: yellowRival,
        redOur: redOur,
        redRival: redRival,
        l10n: l10n,
        onRemoveRivalShot: policy.coachAction(
          () => removeLastOfType(MatchEventEnum.rivalShot),
        ),
        onAddRivalShot: policy.coachAction(
          () => saveManualCounterEvent(
            MatchEventEnum.rivalShot,
            l10n.matchEventRivalShot,
          ),
        ),
        onRemoveRivalFoul: policy.coachAction(
          () => removeLastOfType(MatchEventEnum.rivalFoul),
        ),
        onAddRivalFoul: policy.coachAction(
          () => saveManualCounterEvent(MatchEventEnum.rivalFoul, 'Falta rival'),
        ),
        onRemoveCorner: policy.coachAction(
          () => removeLastOfType(MatchEventEnum.corner),
        ),
        onAddCorner: policy.coachAction(
          () => saveManualCounterEvent(MatchEventEnum.corner, 'Córner'),
        ),
        onRemoveRivalCorner: policy.coachAction(
          () => removeLastOfType(MatchEventEnum.rivalCorner),
        ),
        onAddRivalCorner: policy.coachAction(
          () => saveManualCounterEvent(MatchEventEnum.rivalCorner, 'Córner rival'),
        ),
        onRemoveOffside: policy.coachAction(
          () => removeLastOfType(MatchEventEnum.offside),
        ),
        onAddOffside: policy.coachAction(
          () => saveManualCounterEvent(
            MatchEventEnum.offside,
            l10n.matchEventOffside,
          ),
        ),
        onRemoveRivalOffside: policy.coachAction(
          () => removeLastOfType(MatchEventEnum.rivalOffside),
        ),
        onAddRivalOffside: policy.coachAction(
          () => saveManualCounterEvent(
            MatchEventEnum.rivalOffside,
            l10n.matchEventRivalOffside,
          ),
        ),
        onRemoveRivalYellowCard: policy.coachAction(
          () => removeLastOfType(MatchEventEnum.rivalYellowCard),
        ),
        onAddRivalYellowCard: policy.coachAction(
          () => saveManualCounterEvent(
            MatchEventEnum.rivalYellowCard,
            l10n.matchRivalYellowCardNote,
          ),
        ),
        onRemoveRivalRedCard: policy.coachAction(
          () => removeLastOfType(MatchEventEnum.rivalRedCard),
        ),
        onAddRivalRedCard: policy.coachAction(
          () => saveManualCounterEvent(
            MatchEventEnum.rivalRedCard,
            l10n.matchRivalRedCardNote,
          ),
        ),
      ),
    ),
  ];
}
