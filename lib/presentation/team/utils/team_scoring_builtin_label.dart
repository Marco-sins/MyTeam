import 'package:football_manager/domain/entities/team_scoring_config.dart';
import 'package:football_manager/l10n/app_localizations.dart';

/// Nombres de evento en **singular** (misma lógica que acciones de partido, no títulos de tabla estadística).
String teamScoringBuiltinTitle(AppLocalizations l10n, String id) {
  switch (id) {
    case TeamScoringBuiltinId.scoregoalScorer:
      return l10n.teamScoringGoalScorer;
    case TeamScoringBuiltinId.scoregoalAssist:
      return l10n.teamScoringGoalAssist;
    case TeamScoringBuiltinId.owngoal:
      return l10n.teamScoringEventOwnGoal;
    case TeamScoringBuiltinId.concedegoal:
      return l10n.teamScoringEventGoalConceded;
    case TeamScoringBuiltinId.shot:
      return l10n.matchActionLabelShot;
    case TeamScoringBuiltinId.goodpass:
      return l10n.matchActionLabelGoodPass;
    case TeamScoringBuiltinId.badpass:
      return l10n.matchActionLabelBadPass;
    case TeamScoringBuiltinId.goodplay:
      return l10n.matchActionLabelGoodPlay;
    case TeamScoringBuiltinId.badplay:
      return l10n.matchActionLabelBadPlay;
    case TeamScoringBuiltinId.ballrecovery:
      return l10n.matchActionLabelBallRecovery;
    case TeamScoringBuiltinId.goodsave:
      return l10n.matchActionLabelGoodSave;
    case TeamScoringBuiltinId.goodsaveIncredible:
      return l10n.teamScoringParadaIncreible;
    case TeamScoringBuiltinId.yellowcard:
      return l10n.matchActionLabelYellowCard;
    case TeamScoringBuiltinId.redcard:
      return l10n.matchActionLabelRedCard;
    case TeamScoringBuiltinId.foul:
      return l10n.matchActionLabelFoul;
    case TeamScoringBuiltinId.cantada:
      return l10n.matchActionLabelCantada;
    case TeamScoringBuiltinId.keypass:
      return l10n.matchActionLabelKeyPass;
    case TeamScoringBuiltinId.paseClave:
      return l10n.teamScoringPaseClaveNota;
    case TeamScoringBuiltinId.jugadaClave:
      return l10n.teamScoringJugadaClaveNota;
    case TeamScoringBuiltinId.tiroNote:
      return l10n.teamScoringTiroNota;
    case TeamScoringBuiltinId.tarjetaAmarilla:
      return l10n.teamScoringAmarillaNota;
    case TeamScoringBuiltinId.tarjetaRoja:
      return l10n.teamScoringRojaNota;
    case TeamScoringBuiltinId.cantadaNote:
      return l10n.teamScoringCantadaNota;
  }
  return id;
}
